import SwiftUI

/// Right-hand detail panel for a selected, unlocked app: header, suite files, leftover files,
/// and the clear/reset/uninstall action bar. Ported from renderDetail() in the original frontend.
struct AppDetailView: View {
    @ObservedObject var viewModel: AppListViewModel
    let app: InstalledApp
    @ObservedObject private var settings = AppSettings.shared

    @State private var showClearCacheConfirm = false
    @State private var showResetConfirm = false
    @State private var showUninstallConfirm = false

    private var trashVerb: String { settings.emptyTrashAfterDelete ? "permanently delete" : "move to the Trash" }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if app.hasSuiteFiles {
                        suiteSection
                    }
                    leftoverSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            actionBar
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconView(icon: app.icon, tagColor: app.tagColor, letter: String(app.name.prefix(1)), size: 48, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text("v\(app.version) · App: \(Format.mb(app.totalSizeMB)) · Junk: \(Format.mb(app.junkMB))")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: 0.5) }
    }

    private var suiteSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("SUITE FILES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
                Text("(in /Applications — check to include in uninstall)")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.muted)
            }
            .padding(.bottom, 10)

            ForEach(app.suiteFiles) { file in
                FileRowView(file: file, titleOverride: "\(file.category) — \(file.fileName)") { isOn in
                    viewModel.toggleFile(file.id, isOn: isOn)
                }
            }
        }
        .padding(.bottom, 16)
    }

    private var leftoverSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LEFTOVER FILES IN ~/LIBRARY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(Theme.hint)
                .padding(.bottom, 10)

            if app.files.isEmpty {
                Text("No leftover files found in ~/Library")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            } else {
                ForEach(app.files) { file in
                    FileRowView(file: file) { isOn in
                        viewModel.toggleFile(file.id, isOn: isOn)
                    }
                }
            }
        }
    }

    private var selectedCount: Int {
        app.files.filter { $0.isOn }.count + app.suiteFiles.filter { $0.isOn }.count
    }

    private var selectedSizeMB: Double {
        app.files.filter { $0.isOn }.reduce(0) { $0 + $1.sizeMB }
            + app.suiteFiles.filter { $0.isOn }.reduce(0) { $0 + $1.sizeMB }
    }

    private var cacheSizeMB: Double {
        app.files.filter { $0.category == "Caches" }.reduce(0) { $0 + $1.sizeMB }
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            Text("\(selectedCount) items selected · \(Format.mb(selectedSizeMB)) will be freed")
                .font(.system(size: 12))
                .foregroundColor(Theme.hint)
            Spacer(minLength: 0)

            Button("Clear cache") { showClearCacheConfirm = true }
                .buttonStyle(.cacheAction)
                .confirmationDialog(
                    "Clear cache for \(app.name)?",
                    isPresented: $showClearCacheConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Clear Cache", role: .destructive) {
                        Task { await viewModel.clearCache(for: app) }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will \(trashVerb) \(Format.mb(cacheSizeMB)) of cached data. Your settings and documents won't be touched.")
                }

            Button("Reset app") { showResetConfirm = true }
                .buttonStyle(.resetAction)
                .confirmationDialog(
                    "Reset \(app.name)?",
                    isPresented: $showResetConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Reset App", role: .destructive) {
                        Task { await viewModel.resetApp(app) }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will \(trashVerb) all of \(app.name)'s data (\(Format.mb(app.junkMB))), so it launches like a fresh install. The app itself stays installed.")
                }

            Button("Uninstall") { showUninstallConfirm = true }
                .buttonStyle(.uninstallAction)
                .confirmationDialog(
                    "Uninstall \(app.name)?",
                    isPresented: $showUninstallConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Uninstall", role: .destructive) {
                        Task { await viewModel.uninstall(app) }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will \(trashVerb) the app itself plus \(selectedCount) selected leftover file(s) (\(Format.mb(selectedSizeMB + app.appSizeMB)) total).")
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 0.5) }
    }
}
