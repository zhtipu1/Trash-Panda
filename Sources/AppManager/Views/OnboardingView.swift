import SwiftUI

/// First-launch (or every-launch, if enabled) permissions screen. Ported from the #onboarding
/// overlay in frontend/index.html.
struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    let onFinish: () -> Void

    @State private var status: PermissionStatus = .checking
    @State private var skipNextTime = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.accentBg)
                        Text("🐼").font(.system(size: 32))
                    }
                    .frame(width: 72, height: 72)
                    .padding(.bottom, 16)

                    Text("Trash Panda: App Manager")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Theme.text)
                        .multilineTextAlignment(.center)
                    Text("This loves digging through your system and eating the unwanted apps and garbage.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("REQUIRED PERMISSIONS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Theme.hint)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Full Disk Access")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                Text("Needed to scan ~/Library for leftover caches,\npreferences, logs, and support files.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.muted)
                            }
                            Spacer(minLength: 0)
                            PermissionStatusBadge(status: status)
                        }
                        HStack(spacing: 8) {
                            Button("Open System Settings") { PermissionsChecker.openPrivacySettings() }
                                .buttonStyle(.secondary)
                            Button("Re-check ↺") { recheck() }
                                .buttonStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border2, lineWidth: 0.5))
                    )
                }

                VStack(spacing: 12) {
                    Button("Get Started →") { start() }
                        .buttonStyle(.primary(warnState: status == .denied))

                    Text(status == .denied ? "⚠ Without Full Disk Access, leftover files may not be found." : " ")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.warn)
                        .frame(minHeight: 16)
                        .multilineTextAlignment(.center)

                    Toggle(isOn: $skipNextTime) {
                        Text("Don't show this screen on startup")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.muted)
                    }
                    .toggleStyle(.checkbox)
                }
            }
            .frame(width: 480)
        }
        .task { recheck() }
    }

    private func recheck() {
        status = .checking
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            status = PermissionsChecker.hasFullDiskAccess() ? .granted : .denied
        }
    }

    private func start() {
        settings.showOnboarding = !skipNextTime
        onFinish()
    }
}
