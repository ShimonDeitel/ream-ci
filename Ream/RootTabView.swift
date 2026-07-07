import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ReamHomeView()
                .tabItem {
                    Label("Supplies", systemImage: "backpack.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(RMTheme.tapeRed)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(RMTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(ReamStore())
        .environmentObject(PurchaseManager())
}
