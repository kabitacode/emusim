import SwiftUI

struct DeviceRow: View {
    let device: Device
    let onAction: (DeviceAction) -> Void
    @State private var confirmClear = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.platform == .ios ? "iphone" : "smartphone")
                .font(.title2)
                .frame(width: 28)
                .foregroundStyle(device.platform == .ios ? Color.blue : Color.green)

            VStack(alignment: .leading) {
                Text(device.name).font(.headline)
                Text(device.osVersion).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            Text(device.isRunning ? "Running" : "Stopped")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .foregroundStyle(device.isRunning ? Color.green : Color.secondary)
                .background((device.isRunning ? Color.green : Color.secondary).opacity(0.15), in: Capsule())

            Button("Run", systemImage: "play.fill") { onAction(.run) }
                .disabled(device.isRunning)
                .help("Run")
            Button("Stop", systemImage: "stop.fill") { onAction(.stop) }
                .disabled(!device.isRunning)
                .help("Stop")
            Button("Clear", systemImage: "trash") { confirmClear = true }
                .help(device.platform == .ios ? "Erase" : "Wipe data")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
        .confirmationDialog("Clear \(device.name)?", isPresented: $confirmClear) {
            Button("Clear", role: .destructive) { onAction(.clear) }
        } message: {
            Text(device.platform == .ios
                 ? "All content and settings will be erased."
                 : "User data will be wiped and the emulator will start.")
        }
    }
}
