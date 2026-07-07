import SwiftUI

@main
struct ReamApp: App {
    @StateObject private var store = ReamStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
