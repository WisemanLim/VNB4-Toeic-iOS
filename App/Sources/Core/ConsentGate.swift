import Foundation

/// 미성년 보호자 동의 게이트 (edtech / PIPA §22-2). 만14세 미만 가입은 보호자 동의가
/// 없으면 차단한다. COMPLIANCE.md "만14세 미만 가입 시 보호자 동의 없으면 차단".
enum ConsentGate {
    /// 보호자 동의 없이 가입 가능한 최소 (만) 나이.
    static let minAgeWithoutGuardian = 14

    /// 출생연도와 기준연도로 (만) 나이 근사 → 보호자 동의 필요 여부.
    /// 출생연도 미입력(nil)은 차단하지 않는다(성인 대상 가정; 입력 시에만 검증).
    /// 가정: 생일 단위가 아닌 연 단위 근사.
    static func requiresGuardianConsent(birthYear: Int?, currentYear: Int) -> Bool {
        guard let by = birthYear else { return false }
        return (currentYear - by) < minAgeWithoutGuardian
    }
}

/// 가입 거부 사유 (보호자 동의 미충족).
struct GuardianConsentRequired: Error, LocalizedError {
    var errorDescription: String? {
        "만 14세 미만은 보호자 동의가 필요합니다. 보호자 동의 후 다시 시도하세요."
    }
}
