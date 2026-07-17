import SwiftUI

/// The "Orphaned" tab. Ported from #view-orphans in the original frontend.
struct OrphansView: View {
    @ObservedObject var viewModel: OrphanListViewModel
    let installedApps: [InstalledApp]
    let scanGroupContainers: Bool
    @State private var showCleanAllConfirm = false
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        content
            .navigationTitle("Orphaned Files")
            .safeAreaInset(edge: .top) {
                if !viewModel.orphans.isEmpty {
                    infoBar
                }
            }
            .toolbar {
                ToolbarItem {
                    if !viewModel.safeOrphans.isEmpty {
                        Button("Clean All Safe") { showCleanAllConfirm = true }
                            .confirmationDialog(
                                "Delete \(viewModel.safeOrphans.count) orphaned files?",
                                isPresented: $showCleanAllConfirm,
                                titleVisibility: .visible
                            ) {
                                Button("Delete All", role: .destructive) {
                                    Task { await viewModel.cleanAllSafe() }
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text(settings.emptyTrashAfterDelete
                                    ? "This will permanently delete \(Format.mb(viewModel.totalSafeMB)) right away."
                                    : "This will move \(Format.mb(viewModel.totalSafeMB)) to the Trash.")
                            }
                    }
                }
            }
            .task(id: viewModel.hasLoaded) {
                if !viewModel.hasLoaded {
                    await viewModel.load(installedApps: installedApps, scanGroupContainers: scanGroupContainers)
                }
            }
    }

    private var subtitle: String {
        guard !viewModel.orphans.isEmpty else { return "Files left behind by uninstalled apps" }
        return "\(viewModel.safeOrphans.count) orphaned · \(viewModel.unsafeOrphans.count) linked to installed apps · \(Format.mb(viewModel.totalSafeMB)) reclaimable"
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                legendItem(color: Theme.danger, text: "Orphaned — safe to delete")
                legendItem(color: Theme.warn, text: "Linked to installed app — do not delete")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 8)
            Text(text).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            emptyState(text: "Scanning for orphaned files…", systemImage: "trash")
        } else if viewModel.orphans.isEmpty {
            emptyState(text: "No orphaned files found", systemImage: "checkmark.circle")
        } else {
            List {
                ForEach(viewModel.sortedForDisplay) { orphan in
                    OrphanRowView(orphan: orphan) { Task { await viewModel.delete(orphan) } }
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.inset)
        }
    }

    private func emptyState(text: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
