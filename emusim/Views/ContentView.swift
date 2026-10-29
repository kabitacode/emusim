import SwiftUI

struct ContentView: View {
    @State private var viewModel = DeviceListViewModel()
    @AppStorage(AppSettings.themeKey) private var theme = AppTheme.system

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                List { section("iOS Simulator", viewModel.filtered(viewModel.iosDevices)) }
                Divider()
                List { section("Android Emulator", viewModel.filtered(viewModel.androidDevices)) }
            }
            .navigationTitle("EmuSim")
            .searchable(text: $viewModel.searchText)
            .toolbar {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await viewModel.refresh() }
                }
                .disabled(viewModel.isLoading)
            }
            .task { await viewModel.poll() }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .frame(minWidth: 960, minHeight: 400)
        .preferredColorScheme(theme.colorScheme)
    }

    private func section(_ title: String, _ devices: [Device]) -> some View {
        Section(title) {
            if devices.isEmpty {
                Text("No devices").foregroundStyle(.secondary)
            }
            ForEach(devices) { device in
                DeviceRow(device: device) { action in
                    Task { await viewModel.perform(action, on: device) }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
