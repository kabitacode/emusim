import Foundation
import Observation

@Observable
final class DeviceListViewModel {
    var iosDevices: [Device] = []
    var androidDevices: [Device] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    private let simulators = SimulatorService()
    private var android: AndroidService { AndroidService(sdkPath: AppSettings.sdkPath) }

    func filtered(_ devices: [Device]) -> [Device] {
        guard !searchText.isEmpty else { return devices }
        return devices.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.osVersion.localizedCaseInsensitiveContains(searchText)
        }
    }

    // silent: no spinner and no alert, used by poll().
    func refresh(silent: Bool = false) async {
        if !silent { isLoading = true }
        defer { if !silent { isLoading = false } }
        var errors: [String] = []
        do { iosDevices = try await simulators.devices() } catch {
            iosDevices = []
            errors.append("iOS Simulator: \(error.localizedDescription)")
        }
        do { androidDevices = try await android.devices() } catch {
            androidDevices = []
            errors.append("Android Emulator: \(error.localizedDescription)")
        }
        if !silent, !errors.isEmpty { errorMessage = errors.joined(separator: "\n\n") }
    }

    // Refresh every 5s to catch devices closed outside the app.
    func poll() async {
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            await refresh(silent: true)
        }
    }

    func perform(_ action: DeviceAction, on device: Device) async {
        do {
            switch (device.platform, action) {
            case (.ios, .run): try await simulators.boot(device.id)
            case (.ios, .stop): try await simulators.shutdown(device.id)
            case (.ios, .clear): try await simulators.erase(device.id)
            case (.android, .run): try await android.start(device.id)
            case (.android, .stop): try await android.stop(device.id)
            case (.android, .clear): try await android.wipeData(device.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        await refresh()
    }
}
