import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ReamStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("ream_restock_notifications_enabled") private var notificationsEnabled: Bool = true
    @State private var activeSheet: ReamSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Low-stock alerts", isOn: $notificationsEnabled)
                        .accessibilityIdentifier("notificationsToggle")
                }

                Section("Overview") {
                    HStack {
                        Text("Kids Tracked")
                        Spacer()
                        Text("\(store.kids.count)")
                            .foregroundStyle(RMTheme.inkFaded)
                    }
                    HStack {
                        Text("Supplies Tracked")
                        Spacer()
                        Text("\(store.items.count)")
                            .foregroundStyle(RMTheme.inkFaded)
                    }
                    HStack {
                        Text("Needing Restock")
                        Spacer()
                        Text("\(store.restockNeededCount)")
                            .foregroundStyle(RMTheme.inkFaded)
                    }
                }

                Section("Ream Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(RMTheme.tapeRed)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(RMTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/ream-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(RMTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .accessibilityIdentifier("resetDataButton")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all kids and supplies?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ReamStore())
        .environmentObject(PurchaseManager())
}
