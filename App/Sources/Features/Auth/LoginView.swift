import SwiftUI

/// Email login / signup (RN `app/login.tsx` · `signup.tsx`). Hits the real server
/// via AuthStore; on success returns to home synced. Guest mode needs no login.
struct LoginView: View {
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var isSignup = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var birthYear = ""
    @State private var guardianConsent = false
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        VStack(spacing: 16) {
            Text(isSignup ? "회원가입" : "로그인").font(.largeTitle.bold()).foregroundColor(Theme.text)

            if isSignup {
                field("이름 (선택)", text: $name)
                field("출생연도 (예: 2010)", text: $birthYear, keyboard: .numberPad)
                Toggle("보호자 동의함 (만 14세 미만 시 필수)", isOn: $guardianConsent)
                    .foregroundColor(Theme.textMuted).font(.subheadline)
            }
            field("이메일", text: $email, keyboard: .emailAddress)
            field("비밀번호", text: $password, secure: true)

            if let error { Text(error).font(.subheadline).foregroundColor(.red) }

            Button(isSignup ? "가입하기" : "로그인") { submit() }
                .font(.headline.bold()).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding()
                .background(Theme.accent).cornerRadius(12)
                .disabled(busy || email.isEmpty || password.isEmpty)

            Button(isSignup ? "이미 계정이 있어요 · 로그인" : "계정이 없어요 · 회원가입") {
                isSignup.toggle(); error = nil
            }.font(.subheadline).foregroundColor(Theme.textMuted)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func field(_ label: String, text: Binding<String>, secure: Bool = false, keyboard: UIKeyboardType = .default) -> some View {
        Group {
            if secure { SecureField(label, text: text) }
            else { TextField(label, text: text).keyboardType(keyboard).autocapitalization(.none) }
        }
        .padding().background(Theme.bgCard).cornerRadius(10).foregroundColor(Theme.text)
    }

    private func submit() {
        busy = true; error = nil
        Task {
            do {
                if isSignup {
                    try await auth.signup(email: email, password: password,
                                          name: name.isEmpty ? nil : name,
                                          birthYear: Int(birthYear), guardianConsent: guardianConsent)
                } else { try await auth.login(email: email, password: password) }
                dismiss()
            } catch {
                self.error = (error as? APIError)?.message ?? "로그인 실패 — 서버 연결을 확인하세요."
            }
            busy = false
        }
    }
}
