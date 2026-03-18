import AVFoundation
import Accelerate
import Foundation

actor AudioAnalysisService {

    static let shared = AudioAnalysisService()
    private var analyzing: Set<UUID> = []

    func analyze(song: Song) async -> AudioAnalysis? {
        guard let url = song.fileURL else { return nil }
        guard !analyzing.contains(song.id) else { return nil }
        analyzing.insert(song.id)
        defer { analyzing.remove(song.id) }

        do {
            let file = try AVAudioFile(forReading: url)
            let sampleRate = file.processingFormat.sampleRate
            let totalFrames = Int(file.length)
            let analysisFrames = min(totalFrames, Int(sampleRate * 60))

            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(analysisFrames)
            ) else { return nil }

            try file.read(into: buffer, frameCount: AVAudioFrameCount(analysisFrames))

            guard let floatData = buffer.floatChannelData?[0] else { return nil }
            let frameCount = Int(buffer.frameLength)

            let bpm    = detectBPM(floatData: floatData, frameCount: frameCount, sampleRate: sampleRate)
            let key    = detectKey(floatData: floatData, frameCount: frameCount, sampleRate: sampleRate)
            let energy = computeEnergy(floatData: floatData, frameCount: frameCount)
            let trim   = detectTrimPoints(floatData: floatData, frameCount: frameCount,
                                          sampleRate: sampleRate, totalFrames: totalFrames)

            return AudioAnalysis(bpm: bpm, key: key, energy: energy,
                                 introEnd: trim.introEnd, outroStart: trim.outroStart)
        } catch {
            print("[AudioAnalysisService] Failed: \(error)")
            return nil
        }
    }

    // MARK: - BPM

    private func detectBPM(floatData: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> Double {
        let windowSize = max(1, Int(sampleRate * 0.01))
        let numWindows = frameCount / windowSize
        guard numWindows > 10 else { return 120 }

        var rms = [Float](repeating: 0, count: numWindows)
        for i in 0..<numWindows {
            let offset = i * windowSize
            var r: Float = 0
            vDSP_rmsqv(floatData.advanced(by: offset), 1, &r,
                       vDSP_Length(min(windowSize, frameCount - offset)))
            rms[i] = r
        }

        var onset = [Float](repeating: 0, count: numWindows - 1)
        for i in 0..<onset.count { onset[i] = max(0, rms[i + 1] - rms[i]) }

        let windowsPerSecond = sampleRate / Double(windowSize)
        let minLag = max(1, Int(windowsPerSecond * 60.0 / 180.0))
        let maxLag = min(onset.count - 1, Int(windowsPerSecond * 60.0 / 60.0))
        guard maxLag > minLag else { return 120 }

        var bestLag = minLag
        var bestCorr: Float = -Float.infinity

        onset.withUnsafeBufferPointer { buf in
            guard let base = buf.baseAddress else { return }
            for lag in minLag...maxLag {
                let len = onset.count - lag
                guard len > 0 else { continue }
                var corr: Float = 0
                vDSP_dotpr(base, 1, base.advanced(by: lag), 1, &corr, vDSP_Length(len))
                if corr > bestCorr { bestCorr = corr; bestLag = lag }
            }
        }

        let period = Double(bestLag) / windowsPerSecond
        guard period > 0 else { return 120 }
        return min(200, max(40, 60.0 / period))
    }

    // MARK: - Key

    private func detectKey(floatData: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> String {
        let analysisCount = min(frameCount, Int(sampleRate * 30))
        let log2N = Int(log2(Float(analysisCount)))
        let N = 1 << log2N
        guard N >= 512 else { return "C" }

        var real = [Float](UnsafeBufferPointer(start: floatData, count: N))
        var imag = [Float](repeating: 0, count: N)
        var magnitudes = [Float](repeating: 0, count: N / 2)

        var window = [Float](repeating: 0, count: N)
        vDSP_hann_window(&window, vDSP_Length(N), Int32(vDSP_HANN_NORM))
        vDSP_vmul(real, 1, window, 1, &real, 1, vDSP_Length(N))

        real.withUnsafeMutableBufferPointer { rBuf in
            imag.withUnsafeMutableBufferPointer { iBuf in
                var split = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                let setup = vDSP_create_fftsetup(vDSP_Length(log2N), FFTRadix(kFFTRadix2))!
                vDSP_fft_zip(setup, &split, 1, vDSP_Length(log2N), FFTDirection(kFFTDirection_Forward))
                vDSP_destroy_fftsetup(setup)
                var splitConst = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                vDSP_zvabs(&splitConst, 1, &magnitudes, 1, vDSP_Length(N / 2))
            }
        }

        var chroma = [Float](repeating: 0, count: 12)
        let freqPerBin = sampleRate / Double(N)
        for bin in 1..<(N / 2) {
            let freq = Double(bin) * freqPerBin
            guard freq >= 27.5, freq <= 4186 else { continue }
            let midi = 12.0 * log2(freq / 440.0) + 69.0
            let pc = (Int(midi.rounded()) % 12 + 12) % 12
            chroma[pc] += magnitudes[bin]
        }

        var maxVal: Float = 0
        vDSP_maxv(chroma, 1, &maxVal, vDSP_Length(12))
        if maxVal > 0 { vDSP_vsdiv(chroma, 1, &maxVal, &chroma, 1, vDSP_Length(12)) }

        let major: [Float] = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
        let minor: [Float] = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        var bestKey = "C"
        var bestCorr: Float = -Float.infinity

        chroma.withUnsafeBufferPointer { chromaBuf in
            guard let chromaBase = chromaBuf.baseAddress else { return }
            for root in 0..<12 {
                var maj = (0..<12).map { major[($0 + root) % 12] }
                var min_ = (0..<12).map { minor[($0 + root) % 12] }
                var majCorr: Float = 0
                var minCorr: Float = 0
                maj.withUnsafeMutableBufferPointer  { vDSP_dotpr(chromaBase, 1, $0.baseAddress!, 1, &majCorr, 12) }
                min_.withUnsafeMutableBufferPointer { vDSP_dotpr(chromaBase, 1, $0.baseAddress!, 1, &minCorr, 12) }
                if majCorr > bestCorr { bestCorr = majCorr; bestKey = notes[root] }
                if minCorr > bestCorr { bestCorr = minCorr; bestKey = "\(notes[root])m" }
            }
        }
        return bestKey
    }

    // MARK: - Energy

    private func computeEnergy(floatData: UnsafePointer<Float>, frameCount: Int) -> Double {
        guard frameCount > 0 else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(floatData, 1, &rms, vDSP_Length(frameCount))
        return Double(min(1.0, rms * 10))
    }

    // MARK: - Trim Points

    private func detectTrimPoints(floatData: UnsafePointer<Float>, frameCount: Int,
                                   sampleRate: Double, totalFrames: Int) -> (introEnd: TimeInterval, outroStart: TimeInterval) {
        let windowSize = max(1, Int(sampleRate * 0.05))
        let numWindows = frameCount / windowSize
        guard numWindows > 2 else { return (0, Double(totalFrames) / sampleRate) }

        var rms = [Float](repeating: 0, count: numWindows)
        for i in 0..<numWindows {
            let offset = i * windowSize
            var r: Float = 0
            vDSP_rmsqv(floatData.advanced(by: offset), 1, &r,
                       vDSP_Length(min(windowSize, frameCount - offset)))
            rms[i] = r
        }

        var meanRMS: Float = 0
        vDSP_meanv(rms, 1, &meanRMS, vDSP_Length(numWindows))
        let silenceThreshold = meanRMS * 0.1
        let energyThreshold  = meanRMS * 0.3
        let timePerWindow    = Double(windowSize) / sampleRate

        let introWindow = rms.firstIndex(where: { $0 > energyThreshold }) ?? 0
        let outroWindow = rms.lastIndex(where:  { $0 > silenceThreshold }) ?? numWindows - 1

        return (
            Double(introWindow) * timePerWindow,
            min(Double(outroWindow) * timePerWindow, Double(totalFrames) / sampleRate)
        )
    }
}
