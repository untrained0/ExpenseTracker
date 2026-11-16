import SwiftUI

/// Explains how to connect bank messages to the app, and holds the two controls that
/// can only work from the foreground: notification permission and releasing a stuck hold.
struct CaptureSetupView: View {
    let viewModel: CaptureSetupViewModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            Section {
                notificationRow
            } header: {
                Text("Prompts")
            } footer: {
                Text("Used only when a bank message can't be logged by itself, so you can add it with one tap.")
            }

            Section {
                step(1, "Open Shortcuts → Automation → + → Message.")
                step(2, "In Message Contains, enter “debited”. Choose Run Immediately and turn off Notify When Run.")
                step(3, "Add the action Capture Bank Message (Expense Tracker) and set Message to Shortcut Input.")
                step(4, "Repeat for “credited” and “spent”.")
            } header: {
                Text("Capture bank messages")
            } footer: {
                Text("iOS doesn't let apps read messages directly, so Shortcuts passes each one along. Debits are saved as expenses and credits as income. Notifications from other apps can't be read.")
            }

            Section {
                step(1, "In Shortcuts → Automation → + → App, pick your games and choose Is Opened.")
                step(2, "Add the action Hold Expense Prompts with Hold turned on.")
                step(3, "Make a second automation for Is Closed, with Hold turned off.")
            } header: {
                Text("Keep prompts out of games")
            } footer: {
                Text("While held, prompts wait in a queue and arrive together when the game closes. If you use a Gaming Focus instead, add the Expense Tracker filter under Settings → Focus → Gaming → Focus Filters.")
            }

            if viewModel.isHoldingPrompts {
                Section {
                    Button("Release held prompts now") {
                        Task { await viewModel.releaseHeldPrompts() }
                    }
                } footer: {
                    Text("Prompts are on hold. ^[\(viewModel.pendingCount) message](inflect: true) waiting for review.")
                }
            }
        }
        .navigationTitle("Automatic capture")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from Settings may have changed the permission.
            if phase == .active {
                Task { await viewModel.refresh() }
            }
        }
    }

    @ViewBuilder
    private var notificationRow: some View {
        switch viewModel.authorization {
        case .allowed:
            Label("Notifications allowed", systemImage: "checkmark.circle.fill")
        case .notDetermined:
            Button {
                Task { await viewModel.allowNotifications() }
            } label: {
                Label("Allow notifications", systemImage: "bell.badge")
            }
        case .denied:
            Label("Notifications are off. Turn them on in Settings → Notifications → Expense Tracker.", systemImage: "bell.slash")
                .foregroundStyle(.secondary)
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(text)")
    }
}
