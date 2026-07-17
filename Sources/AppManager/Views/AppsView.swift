import SwiftUI

/// The "Apps" tab: a native list/detail split with a toolbar for search/sort/refresh.
struct AppsView: View {
    @ObservedObject var viewModel: AppListViewModel
    let scanOptions: ScanOptions

    var body: some View {
        HStack(spacing: 0) {
            listPanel
                .frame(width: 300)
            Divider()
            detailPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Apps")
        .safeAreaInset(edge: .top) { statsBar }
        .searchable(text: $viewModel.searchText, prompt: "Search apps")
        .toolbar {
            ToolbarItemGroup {
                Picker("Sort", selection: $viewModel.sortMode) {
                    ForEach(AppListViewModel.SortMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    Task { await viewModel.loadApps(options: scanOptions) }
                } label: {
                    Label("Re-scan", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Re-scan")
            }
        }
        .task {
            // Only auto-scan on first appearance — switching tabs shouldn't re-trigger a scan.
            // The refresh button (and RootView invalidating orphans) covers explicit re-scans.
            if viewModel.apps.isEmpty && !viewModel.isLoading {
                await viewModel.loadApps(options: scanOptions)
            }
        }
        .onChange(of: viewModel.selectedID) { _ in
            viewModel.clearSelectionIfLocked()
        }
    }

    private var statsBar: some View {
        HStack(spacing: 10) {
            StatPill(label: "Apps", value: "\(viewModel.installedCount) installed · \(viewModel.systemCount) system")
            StatPill(label: "Storage", value: Format.mb(viewModel.totalStorageMB))
            StatPill(label: "Junk", value: Format.mb(viewModel.totalJunkMB), danger: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var listPanel: some View {
        List(selection: $viewModel.selectedID) {
            if viewModel.isLoading {
                placeholder(text: "Scanning apps…", systemImage: "shippingbox")
            } else if viewModel.filteredApps.isEmpty {
                placeholder(
                    text: viewModel.loadFailed ? "Scan failed — check Full Disk Access." : "No apps found",
                    systemImage: "shippingbox"
                )
            } else {
                if !viewModel.installedApps.isEmpty {
                    Section("Installed Apps (\(viewModel.installedApps.count))") {
                        ForEach(viewModel.installedApps) { app in
                            AppRowView(app: app)
                                .tag(app.id)
                                .selectionDisabled(app.locked)
                        }
                    }
                }
                if !viewModel.systemApps.isEmpty {
                    Section("System Apps (\(viewModel.systemApps.count))") {
                        ForEach(viewModel.systemApps) { app in
                            AppRowView(app: app)
                                .tag(app.id)
                                .selectionDisabled(app.locked)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private func placeholder(text: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let app = viewModel.selectedApp {
            AppDetailView(viewModel: viewModel, app: app)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text("Select an app to view details")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
