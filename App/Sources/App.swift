// VNB4Toeic — SwiftUI entrypoint
import SwiftUI

@main
struct VNB4ToeicApp: App {
    @StateObject private var auth = AuthStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(auth)
        }
    }
}
