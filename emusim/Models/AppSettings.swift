import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"

    var id: Self { self }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppSettings {
    static let themeKey = "theme"
    static let sdkPathKey = "androidSDKPath"

    static let defaultSDKPath = ProcessInfo.processInfo.environment["ANDROID_HOME"]
        ?? NSHomeDirectory() + "/Library/Android/sdk"

    static var sdkPath: String {
        UserDefaults.standard.string(forKey: sdkPathKey) ?? defaultSDKPath
    }
}
