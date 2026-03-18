import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit

/// Wraps AVAudioEngine to provide song playback with speed, reverb, and EQ.
/// All published properties are updated on the main thread.
final class AudioPlayerService: ObservableObject {

    // MARK: - Published state

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0

    /// Called on the main thread when the current track finishes naturally.
    var onPlaybackFinished: (() -> Void)?
    /// Called on the main thread when the user taps Next in Control Center / lock screen.
    var onRemoteNext: (() -> Void)?
    /// Called on the main thread when the user taps Previous in Control Center / lock screen.
    var onRemotePrev: (() -> Void)?

    // MARK: - Engine graph

    private let engine       = AVAudioEngine()
    private let playerNode   = AVAudioPlayerNode()
    private let timePitch    = AVAudioUnitTimePitch()
    private let reverbUnit   = AVAudioUnitReverb()
    private let eqUnit       = AVAudioUnitEQ(numberOfBands: 3)

    // MARK: - Internal tracking

    private var audioFile: AVAudioFile?
    @Published private(set) var currentSong: Song?
    private var seekOffset: TimeInterval = 0
    private var progressTimer: Timer?
    /// Incremented every time we stop/seek/load. The completion callback checks
    /// this to avoid acting on stale segments triggered by playerNode.stop().
    private var scheduleGeneration: Int = 0
    /// The sample-time (in seconds) captured right after playerNode.play().
    /// After pause/resume, playerTime.sampleTime continues from where it was paused
    /// rather than resetting to zero. Subtracting this offset in tick() corrects
    /// for that so currentTime doesn't double-count pre-pause samples.
    private var playbackSampleOffset: Double = 0

    // MARK: - Onset detection

    /// Fires on the main thread whenever a drum onset is detected in the audio.
    /// Subscribe in views with `.onReceive(audioPlayer.onsetDetected)`.
    let onsetDetected = PassthroughSubject<Void, Never>()

    // ── All vars below are read/written exclusively from the audio render thread
    //    (the installTap callback), EXCEPT `onsetLastFireTime` which is also
    //    written from the main thread in resetOnsetState().  Single-word reads
    //    and writes of Double are atomic on arm64/x86-64, so no explicit lock
    //    is needed for that one field. ──────────────────────────────────────────

    /// 1-pole IIR low-pass filter state.  Isolates kick-drum / sub-bass band.
    /// Coefficient for ~200 Hz cutoff at 44100 Hz: α = 1 − exp(−2π·200/44100) ≈ 0.028
    private var onsetFilterState: Float = 0
    private let onsetAlpha: Float = 0.028
    private let onsetOneMinusAlpha: Float = 0.972

    /// Energy (mean-squared, no sqrt) from the previous tap buffer.
    private var onsetPrevEnergy: Float = 0

    /// Circular buffer storing recent half-wave-rectified flux values.
    /// Used to compute an adaptive firing threshold.
    private var onsetFluxHistory = [Float](repeating: 0, count: 20)
    private var onsetFluxIdx = 0

    /// Host time of the last fired onset (CACurrentMediaTime units).
    /// Written from both the audio thread and the main thread (see resetOnsetState).
    private var onsetLastFireTime: Double = 0

    /// Whether the tap is currently installed on playerNode.  Main-thread only.
    private var onsetTapInstalled = false

    // MARK: - Init

    init() {
        configureAudioSession()
        setupEngine()
        setupRemoteCommands()
        setupNotifications()
    }

    // MARK: - Public API

    /// Loads a song's audio file and prepares the engine for playback.
    /// Stops any current playback first.
    func load(song: Song) {
        guard let url = song.fileURL else { return }

        stopPlayback()
        currentSong = song

        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            print("[AudioPlayerService] Failed to open \(url.lastPathComponent): \(error)")
            return
        }

        guard let file = audioFile else { return }
        duration  = Double(file.length) / file.processingFormat.sampleRate
        seekOffset = 0
        currentTime = 0

        applySettings(song.settings)
        scheduleFrom(offset: 0)
        updateNowPlaying()
    }

    func play() {
        guard audioFile != nil else { return }
        if !engine.isRunning { try? engine.start() }
        engine.mainMixerNode.outputVolume = 1
        playerNode.play()
        isPlaying = true
        // Capture the sample offset so tick() computes elapsed time correctly.
        // Right after play(), lastRenderTime still reflects the pre-resume node clock
        // (nil after a stop, or the paused sample time after a pause). Subtracting this
        // from sampleTime in tick() gives the delta since the current play() call only.
        if let nodeTime = playerNode.lastRenderTime,
           let pt = playerNode.playerTime(forNodeTime: nodeTime) {
            playbackSampleOffset = Double(pt.sampleTime) / pt.sampleRate
        } else {
            playbackSampleOffset = 0
        }
        startTimer()
        updateNowPlaying()
    }

    func pause() {
        seekOffset = currentTime
        playerNode.pause()
        isPlaying = false
        stopTimer()
        updateNowPlaying()
    }

    func seek(to time: TimeInterval) {
        guard audioFile != nil else { return }
        let wasPlaying = isPlaying

        scheduleGeneration += 1
        playerNode.stop()
        resetOnsetState()
        stopTimer()
        // playerNode.stop() resets the sample clock; zero the offset so tick() starts clean.
        playbackSampleOffset = 0

        seekOffset = max(0, min(time, duration))
        currentTime = seekOffset
        scheduleFrom(offset: seekOffset)

        if wasPlaying {
            playerNode.play()
            startTimer()
        }
        updateNowPlaying()
    }

    /// Applies the song's settings to the engine without reloading the file.
    func applySettings(_ settings: SongSettings) {
        timePitch.rate       = Float(settings.speed)
        // pitch stored as semitones; AVAudioUnitTimePitch.pitch is in cents (100 cents = 1 semitone)
        timePitch.pitch      = Float(settings.pitch * 100)
        reverbUnit.wetDryMix = Float(settings.reverb * 100)
        // Bass/mid/treble stored directly in dB (–12…+12)
        eqUnit.bands[0].gain = Float(settings.bass)
        eqUnit.bands[1].gain = Float(settings.mid)
        eqUnit.bands[2].gain = Float(settings.treble)
    }

    // MARK: - Private – engine setup

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("[AudioPlayerService] AVAudioSession error: \(error)")
        }
    }

    private func setupEngine() {
        // Configure EQ: low shelf (bass) | parametric (mid) | high shelf (treble)
        eqUnit.bands[0].filterType = .lowShelf;    eqUnit.bands[0].frequency = 80;    eqUnit.bands[0].gain = 0; eqUnit.bands[0].bypass = false
        eqUnit.bands[1].filterType = .parametric;  eqUnit.bands[1].frequency = 1000;  eqUnit.bands[1].bandwidth = 1; eqUnit.bands[1].gain = 0; eqUnit.bands[1].bypass = false
        eqUnit.bands[2].filterType = .highShelf;   eqUnit.bands[2].frequency = 10000; eqUnit.bands[2].gain = 0; eqUnit.bands[2].bypass = false

        // Max overlap (32) gives the smoothest phase-vocoder time-stretching at slow speeds.
        // Default is 8; higher values cost more CPU but eliminate most choppiness.
        timePitch.overlap = 32

        reverbUnit.loadFactoryPreset(.mediumRoom)
        reverbUnit.wetDryMix = 0

        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.attach(reverbUnit)
        engine.attach(eqUnit)

        // playerNode → timePitch → reverb → eq → mainMixer
        engine.connect(playerNode, to: timePitch,  format: nil)
        engine.connect(timePitch,  to: reverbUnit, format: nil)
        engine.connect(reverbUnit, to: eqUnit,     format: nil)
        engine.connect(eqUnit,     to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            print("[AudioPlayerService] Engine start error: \(error)")
        }

        installOnsetTap()
    }

    // MARK: - Private – remote commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            isPlaying ? pause() : play()
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { self?.onRemoteNext?() }
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { self?.onRemotePrev?() }
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            seek(to: posEvent.positionTime)
            return .success
        }
    }

    // MARK: - Private – audio session notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch type {
            case .began:
                // Phone call, Siri, alarm, etc. — mirror the pause state so the UI is correct.
                if self.isPlaying { self.pause() }
            case .ended:
                // Only resume if the system says it's safe to do so.
                if let optValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
                   AVAudioSession.InterruptionOptions(rawValue: optValue).contains(.shouldResume) {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    if !self.engine.isRunning { try? self.engine.start() }
                    self.play()
                }
            @unknown default:
                break
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Pause when the current output device (e.g. headphones) is removed — standard iOS behavior.
        if reason == .oldDeviceUnavailable {
            DispatchQueue.main.async { [weak self] in
                if self?.isPlaying == true { self?.pause() }
            }
        }
    }

    // MARK: - Private – now playing info

    private func updateNowPlaying() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist.isEmpty ? "Unknown Artist" : song.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            // Use actual playback rate so the lock screen interpolates progress correctly.
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(timePitch.rate) : 0.0
        ]

        if let uiImage = song.artwork?.uiImage {
            let square = squareCropped(uiImage)
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: square.size) { _ in square }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Private – scheduling

    private func scheduleFrom(offset: TimeInterval) {
        guard let file = audioFile else { return }
        let sampleRate  = file.processingFormat.sampleRate
        let startFrame  = AVAudioFramePosition(offset * sampleRate)
        let framesLeft  = file.length - startFrame
        guard framesLeft > 0 else { return }

        let generation = scheduleGeneration
        playerNode.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: AVAudioFrameCount(framesLeft),
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.scheduleGeneration == generation else { return }
                self.handleCompletion()
            }
        }
    }

    private func handleCompletion() {
        isPlaying = false
        currentTime = duration
        stopTimer()
        updateNowPlaying()
        onPlaybackFinished?()
    }

    // MARK: - Private – timer

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        progressTimer = t
    }

    private func stopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func tick() {
        guard isPlaying,
              let nodeTime   = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return }
        // Subtract playbackSampleOffset to get only the elapsed time since the
        // most recent play() call. Without this, pausing and resuming would
        // double-count all pre-pause samples (seekOffset already includes them).
        let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate - playbackSampleOffset
        currentTime = min(seekOffset + max(0, elapsed), duration)
    }

    /// Returns a center-cropped square version of the image, matching the app's artwork display.
    private func squareCropped(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let origin = CGPoint(x: (image.size.width - side) / 2,
                             y: (image.size.height - side) / 2)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(at: CGPoint(x: -origin.x, y: -origin.y))
        }
    }

    private func stopPlayback() {
        engine.mainMixerNode.outputVolume = 0
        scheduleGeneration += 1
        playerNode.stop()
        resetOnsetState()
        isPlaying = false
        stopTimer()
        playbackSampleOffset = 0
        audioFile  = nil
        currentSong = nil
        seekOffset = 0
        currentTime = 0
        duration    = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Private – onset detection

    private func installOnsetTap() {
        guard !onsetTapInstalled else { return }
        let format = playerNode.outputFormat(forBus: 0)
        playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processOnset(buffer)
        }
        onsetTapInstalled = true
    }

    private func removeOnsetTap() {
        guard onsetTapInstalled else { return }
        playerNode.removeTap(onBus: 0)
        onsetTapInstalled = false
    }

    /// Resets onset detector state so stale energy from the previous segment
    /// doesn't trigger a false onset at the start of a new segment.
    /// Safe to call from the main thread; all mutated vars are main-thread-only
    /// except `onsetLastFireTime`, which is a single-word Double (atomic on arm64).
    private func resetOnsetState() {
        onsetFilterState = 0
        onsetPrevEnergy  = 0
        onsetFluxHistory = [Float](repeating: 0, count: 20)
        onsetFluxIdx     = 0
        onsetLastFireTime = 0
    }

    /// Called on the audio render thread — must be lock-free and allocation-free.
    private func processOnset(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        let samples = channelData[0]

        // 1-pole IIR low-pass to isolate kick drum / sub-bass band (~200 Hz)
        var filterState = onsetFilterState
        var sumSq: Float = 0
        for i in 0 ..< frameCount {
            filterState = onsetAlpha * samples[i] + onsetOneMinusAlpha * filterState
            sumSq += filterState * filterState
        }
        onsetFilterState = filterState

        let energy = sumSq / Float(frameCount)

        // Half-wave rectified spectral flux
        let flux = max(0, energy - onsetPrevEnergy)
        onsetPrevEnergy = energy

        // Update adaptive threshold history
        onsetFluxHistory[onsetFluxIdx] = flux
        onsetFluxIdx = (onsetFluxIdx + 1) % onsetFluxHistory.count

        var histSum: Float = 0
        for v in onsetFluxHistory { histSum += v }
        let histMean = histSum / Float(onsetFluxHistory.count)
        let threshold = max(5e-6, histMean * 3.0)

        guard flux > threshold else { return }

        // 100 ms debounce
        let now = CACurrentMediaTime()
        guard now - onsetLastFireTime > 0.1 else { return }
        onsetLastFireTime = now

        DispatchQueue.main.async { [weak self] in
            self?.onsetDetected.send()
        }
    }
}
