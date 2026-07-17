import SwiftUI

/// App preferences, shown in the standard macOS Settings window (Cmd+,) rather than a sidebar tab —
/// a native `Form` in grouped style, matching how every other Mac app presents its settings.
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var fdaStatus: PermissionStatus = .checking

    var body: some View {
        Form {
            Section {
                LabeledContent("Full Disk Access") {
                    HStack(spacing: 8) {
                        PermissionStatusBadge(status: fdaStatus)
                        Button("Open Settings…") { PermissionsChecker.openPrivacySettings() }
                        Button("Re-check") { recheckFDA() }
                    }
                }
                Text("Required to scan ~/Library for leftover files.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Permissions")
            }

            Section {
                Toggle("Show permissions screen on startup", isOn: $settings.showOnboarding)
                Text("Display the onboarding/permissions check when the app launches.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Empty Trash after deleting", isOn: $settings.emptyTrashAfterDelete)
                Text("Skip waiting for you to empty the Trash — permanently free the space immediately instead of leaving deleted items sitting in the Trash.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Deletion")
            }

            Section {
                Toggle("Scan ~/Library/Containers", isOn: $settings.scanContainers)
                Text("Find leftovers from sandboxed apps.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Toggle("Scan ~/Library/Group Containers", isOn: $settings.scanGroupContainers)
                Text("Shared containers used by app suites (slower).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Scanner")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 420)
        .task { recheckFDA() }
    }

    private func recheckFDA() {
        fdaStatus = .checking
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            fdaStatus = PermissionsChecker.hasFullDiskAccess() ? .granted : .denied
        }
    }
}
