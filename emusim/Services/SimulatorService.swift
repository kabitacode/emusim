import Foundation

struct SimulatorService {
    private let xcrun = "/usr/bin/xcrun"

    // Available simulators from simctl, newest OS first.
    func devices() async throws -> [Device] {
        let json = try await ShellRunner.run(xcrun, ["simctl", "list", "devices", "--json"])
        let list = try JSONDecoder().decode(SimctlList.self, from: Data(json.utf8))
        var devices: [Device] = []
        for (runtime, sims) in list.devices {
            let version = Self.osVersion(runtime: runtime)
            for sim in sims where sim.isAvailable {
                devices.append(Device(id: sim.udid, name: sim.name, osVersion: version,
                                      platform: .ios, isRunning: sim.state == "Booted"))
            }
        }
        return devices.sorted { a, b in
            a.osVersion == b.osVersion
                ? a.name.localizedStandardCompare(b.name) == .orderedAscending
                : a.osVersion.localizedStandardCompare(b.osVersion) == .orderedDescending
        }
    }

    func boot(_ udid: String) async throws {
        try await ShellRunner.run(xcrun, ["simctl", "boot", udid])
        try await ShellRunner.run("/usr/bin/open", ["-a", "Simulator"])
    }

    func shutdown(_ udid: String) async throws {
        try await ShellRunner.run(xcrun, ["simctl", "shutdown", udid])
    }

    func erase(_ udid: String) async throws {
        try await ShellRunner.run(xcrun, ["simctl", "erase", udid])
    }

    private static func osVersion(runtime: String) -> String {
        let parts = runtime.split(separator: ".").last?.split(separator: "-") ?? []
        guard let os = parts.first else { return runtime }
        return "\(os) " + parts.dropFirst().joined(separator: ".")
    }
}

private nonisolated struct SimctlList: Decodable {
    let devices: [String: [Sim]]

    struct Sim: Decodable {
        let udid: String
        let name: String
        let state: String
        let isAvailable: Bool
    }
}
