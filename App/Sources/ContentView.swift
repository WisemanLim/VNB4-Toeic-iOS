import SwiftUI

/// Root: gate the tree until the session resolves (RN AuthProvider loading gate),
/// then show Home. Guest is the default offline experience.
struct ContentView: View {
    @EnvironmentObject var auth: AuthStore

    var body: some View {
        Group {
            if case .loading = auth.status {
                ProgressView().tint(Theme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.bg.ignoresSafeArea())
            } else {
                HomeView()
            }
        }
        .preferredColorScheme(.dark)
        .task { if case .loading = auth.status { await auth.boot() } }
    }
}
