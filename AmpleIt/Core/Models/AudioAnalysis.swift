import Foundation

struct AudioAnalysis: Codable, Equatable {
    let bpm: Double
    let key: String
    let energy: Double
    let introEnd: TimeInterval
    let outroStart: TimeInterval
}
