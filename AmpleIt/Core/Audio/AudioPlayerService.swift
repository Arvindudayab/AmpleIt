import AVFoundation
import Foundation

/// Wraps AVAudioEngine to provide song playback with speed, reverb, and EQ.
/// All published properties are updated on the main thread.
final class AudioPlayerService: ObservableObject {

    // MARK: - Published state

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0

    /// Called on the main thread when the current track finishes naturally.
    var onPlaybackFinished: (() -> Void)?

    // MARK: - Engine graph

    private let engine       = AVAudioEngine()
    private let playerNode   = AVAudioPlayerNode()
    private let timePitch    = AVAudioUnitTimePitch()
    private let reverbUnit   = AVAudioUnitReverb()
    private let eqUnit       = AVAudioUnitEQ(numberOfBands: 3)

    // MARK: - Internal tracking

    private var audioFile: AVAudioFile?
    private var seekOffset: TimeInterval = 0
    private var progressTimer: Timer?
    /// Incremented every time we stop/seek/load. The completion callback checks
    /// this to avoid acting on stale segments triggered by playerNode.stop().
    private var scheduleGeneration: Int = 0

    // MARK: - Init

    init() {
        configureAudioSession()
        setupEngine()
    }

    // MARK: - Public API

    /// Loads a song's audio file and prepares the engine for playback.
    /// Stops any current playback first.
    func load(song: Song) {
        guard let url = song.fileURL else { return }

        stopPlayback()

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
    }

    func play() {
        guard audioFile != nil else { return }
        if !engine.isRunning { try? engine.start() }
        playerNode.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        seekOffset = currentTime
        playerNode.pause()
        isPlaying = false
        stopTimer()
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
    }

    /// Applies the song's settings to the engine without reloading the file.
    func applySettings(_ settings: SongSettings) {
        timePitch.rate       = Float(settings.speed)
        reverbUnit.wetDryMix = Float(settings.reverb * 100)
        // Bass/mid/treble stored as –1…1, mapped to –12…+12 dB
        eqUnit.bands[0].gain = Float(settings.bass   * 12)
        eqUnit.bands[1].gain = Float(settings.mid    * 12)
        eqUnit.bands[2].gain = Float(settings.treble * 12)
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

    private func stopPlayback() {
        scheduleGeneration += 1
        playerNode.stop()
        isPlaying = false
        stopTimer()
        audioFile  = nil
        seekOffset = 0
        currentTime = 0
        duration    = 0
    }
}
