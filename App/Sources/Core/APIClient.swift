import Foundation

struct APIError: Error, LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

/// Runtime data-source switch (ported from RN `client.ts`):
///   guest (not authed) → in-app seed/mock (offline, no network)
///   authed             → real backend (`Env.apiBase`/api/v1)
///   /auth/* endpoints  → always the server (login/signup)
///   USE_MOCK forced    → everything mock
actor APIClient {
    static let shared = APIClient()

    private var accessToken: String?
    private(set) var authed = false
    /// Force the fully-offline mock path (USE_MOCK). Env override possible.
    var forceMock = (Bundle.main.object(forInfoDictionaryKey: "USE_MOCK") as? String) == "1"

    func loadToken() {
        accessToken = Keychain.get("accessToken")
        authed = accessToken != nil
    }

    func saveToken(_ token: String?) {
        accessToken = token
        authed = token != nil
        Keychain.set(token, for: "accessToken")
    }

    func isAuthed() -> Bool { authed }

    /// GET/POST a JSON endpoint and decode `T`. Guest/forceMock serve from `Mocks`.
    func request<T: Decodable>(_ path: String, method: String = "GET", json: Encodable? = nil, as type: T.Type) async throws -> T {
        let isAuth = path.hasPrefix("/auth/")
        let useServer = !forceMock && (authed || isAuth)

        if !useServer {
            guard let data = Mocks.resolve(path: path, method: method) else {
                throw APIError(status: 404, message: "No mock for \(method) \(path)")
            }
            return try JSONDecoder().decode(T.self, from: data)
        }

        guard let url = URL(string: "\(Env.apiBase)/api/v1\(path)") else {
            throw APIError(status: 0, message: "Bad URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        if let accessToken { req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization") }
        if let json { req.httpBody = try JSONEncoder().encode(AnyEncodable(json)) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw APIError(status: code, message: "HTTP \(code)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// Type-erased Encodable so `request(json:)` can take any payload.
private struct AnyEncodable: Encodable {
    private let encodeFn: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeFn = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFn(encoder) }
}
