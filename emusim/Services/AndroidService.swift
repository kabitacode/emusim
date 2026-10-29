import Foundation

struct AndroidService {
    let sdkPath: String

    private var sdk: String { (sdkPath as NSString).expandingTildeInPath }
    private var emulator: String { sdk + "/emulator/emulator" }
    private var adb: String { sdk + "/platform-tools/adb" }

    func devices() async throws -> [Device] {
        let output = try await ShellRunner.run(emulator, ["-list-avds"])
        let running = await runningSerials()
        return output.split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.contains(" ") }
            .map { avd in
                let config = Self.config(avd: avd)
                return Device(id: avd, name: config["avd.ini.displayname"] ?? avd,
                              osVersion: Self.osVersion(config), platform: .android,
                              isRunning: running[avd] != nil)
            }
    }

    func start(_ avd: String) async throws {
        try await ShellRunner.launch(emulator, ["-avd", avd])
    }

    func stop(_ avd: String) async throws {
        guard let serial = await runningSerials()[avd] else {
            throw ShellError(message: "\(avd) is not running.")
        }
        try await ShellRunner.run(adb, ["-s", serial, "emu", "kill"])
    }

    func wipeData(_ avd: String) async throws {
        try await ShellRunner.launch(emulator, ["-avd", avd, "-wipe-data"])
    }

    // Running emulators by AVD name, value is the adb serial.
    private func runningSerials() async -> [String: String] {
        guard let output = try? await ShellRunner.run(adb, ["devices"]) else { return [:] }
        var result: [String: String] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let serial = String(line.split(separator: "\t").first ?? "")
            guard serial.hasPrefix("emulator-"),
                  let name = try? await ShellRunner.run(adb, ["-s", serial, "emu", "avd", "name"])
                    .split(whereSeparator: \.isNewline).first
            else { continue }
            result[name.trimmingCharacters(in: .whitespaces)] = serial
        }
        return result
    }

    // API level from image.sysdir.1, e.g. android-34 is "Android API 34".
    private static func osVersion(_ config: [String: String]) -> String {
        let api = config["image.sysdir.1"]?
            .split(separator: "/")
            .first { $0.hasPrefix("android-") }?
            .dropFirst("android-".count)
        return api.map { "Android API \($0)" } ?? "Android"
    }

    // Parse <avd>.avd/config.ini into a dictionary.
    private static func config(avd: String) -> [String: String] {
        let dir = ProcessInfo.processInfo.environment["ANDROID_AVD_HOME"] ?? NSHomeDirectory() + "/.android/avd"
        let text = (try? String(contentsOfFile: "\(dir)/\(avd).avd/config.ini", encoding: .utf8)) ?? ""
        var config: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let pair = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if pair.count == 2 { config[pair[0]] = pair[1] }
        }
        return config
    }
}
