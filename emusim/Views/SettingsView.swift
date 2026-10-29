import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.themeKey) private var theme = AppTheme.system
    @AppStorage(AppSettings.sdkPathKey) private var sdkPath = AppSettings.defaultSDKPath

    var body: some View {
        Form {
            Picker("Theme", selection: $theme) {
                ForEach(AppTheme.allCases) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            TextField("Android SDK", text: $sdkPath, prompt: Text(AppSettings.defaultSDKPath))
        }
        .padding()
        .frame(width: 480)
        .preferredColorScheme(theme.colorScheme)
    }
}
