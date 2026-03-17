import AVFoundation
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

    // MARK: - Init

    init() {
        configureAudioSession()
        setupEngine()
        setupRemoteCommands()
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
        playerNode.play()
        isPlaying = true
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
        stopTimer()

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
        let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate
        currentTime = min(seekOffset + elapsed, duration)
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
        scheduleGeneration += 1
        playerNode.stop()
        isPlaying = false
        stopTimer()
        audioFile  = nil
        currentSong = nil
        seekOffset = 0
        currentTime = 0
        duration    = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
