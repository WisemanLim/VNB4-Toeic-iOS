import Foundation

/// Auth/session state (ported from RN `auth.tsx`). Guest by default; login/signup
/// hit the real server and persist the token in the Keychain.
@MainActor
final class AuthStore: ObservableObject {
    enum Status { case loading, guest, authed }

    @Published var status: Status = .loading
    @Published var user: SessionUser?

    var isAuthed: Bool { status == .authed }

    /// Restore a saved session and validate it against the server.
    func boot() async {
        await APIClient.shared.loadToken()
        guard await APIClient.shared.isAuthed() else { status = .guest; return }
        do {
            user = try await APIClient.shared.request("/users/me", as: SessionUser.self)
            status = .authed
        } catch {
            await APIClient.shared.saveToken(nil)
            status = .guest
        }
    }

    func login(email: String, password: String) async throws {
        struct Body: Encodable { let email: String; let password: String }
        let res = try await APIClient.shared.request(
            "/auth/login/email", method: "POST",
            json: Body(email: email, password: password), as: LoginResponse.self
        )
        await APIClient.shared.saveToken(res.accessToken)
        user = res.user ?? SessionUser(id: "me", email: email, role: "user", name: nil)
        status = .authed
    }

    func signup(email: String, password: String, name: String?, birthYear: Int? = nil, guardianConsent: Bool = false) async throws {
        // edtech/PIPA §22-2: 만14세 미만은 보호자 동의 없이는 가입 차단.
        let year = Calendar.current.component(.year, from: Date())
        if ConsentGate.requiresGuardianConsent(birthYear: birthYear, currentYear: year), !guardianConsent {
            throw GuardianConsentRequired()
        }
        struct Body: Encodable { let email: String; let password: String; let name: String? }
        let res = try await APIClient.shared.request(
            "/auth/signup/email", method: "POST",
            json: Body(email: email, password: password, name: name), as: LoginResponse.self
        )
        await APIClient.shared.saveToken(res.accessToken)
        user = res.user ?? SessionUser(id: "me", email: email, role: "user", name: name)
        status = .authed
    }

    func logout() async {
        await APIClient.shared.saveToken(nil)
        user = nil
        status = .guest
    }
}
