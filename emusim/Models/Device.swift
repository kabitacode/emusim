import Foundation

enum Platform {
    case ios, android
}

struct Device: Identifiable, Hashable {
    let id: String         
    let name: String
    let osVersion: String
    let platform: Platform
    let isRunning: Bool
}

enum DeviceAction {
    case run, stop, clear
}
