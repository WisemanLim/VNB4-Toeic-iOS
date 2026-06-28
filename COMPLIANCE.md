# COMPLIANCE — 교육·에듀테크 (Education / Edtech) (KSIC P)

> 자동 생성. 근거: `domains/edtech.yaml` + .doc KSIC 통합표. 규제는 변하므로 references 로 재확인.
> 본 앱(VNB4Toeic)은 TOEIC 어휘 학습 앱. `가정:` 성인 학습자 대상(미성년 비주력) — 미성년 가입 가능 시 §보호자동의 적용.

## 분류 / Classification
- KSIC: **P** (교육) · ISIC **P** · NACE **P** · NAICS **61**
- 비고: SW 활동 자체는 J(정보통신)로 이중분류 잦음. ict-saas 베이스라인 + edtech 델타.

## 한국 규제 (1순위)

| 규제 | 영향 |
|------|------|
| 개인정보보호법(PIPA) | PII 수명주기(동의·최소수집·보유·삭제), 과징금 매출 3% |
| 아동·청소년 개인정보 (만14세 미만, PIPA §22-2) | 보호자 동의 게이트 + 본인/보호자 인증, 미성년자 정보 마스킹 |
| 교육 관련 개인정보(학습기록) | 민감 취급, 벤더 공유 제한, 학습기록 조회 감사로그 |
| 웹접근성(KWCAG) | 교육콘텐츠 접근성 + a11y CI (iOS: Dynamic Type·VoiceOver) |

## 국제 기준
- COPPA (만13세 미만, 2025-06-23 개정 / 2026-04-22 완전준수, 제3자 공유 전 부모동의)
- FERPA (US 학생기록)
- GDPR (디지털 동의연령 13~16, DPIA)

## 데이터 등급

| 데이터 | 등급 | 비고 |
|--------|------|------|
| 학습자 PII | 민감 | 이름/연락처/이메일 |
| 미성년자 정보 | **규제대상** | 보호자 동의 연동(만14세 미만) |
| 학습기록/성취도 | 민감 | 교육 민감기록 |
| 결제(보호자) | **규제대상** | PG — 본 앱 비대상(결제 Out of Scope) |

> ⚠ **규제대상** 등급은 **비-프로덕션(dev/staging/test)에 실데이터 반입 금지**. 합성 테스트데이터만 사용.

## 인프라 패턴 (앱 관점 델타)
- 온디바이스 저장: CoreData/GRDB (iOS 16+) — 토큰·PII는 **Keychain**.
- 기존 서버 페어링(URLSession). 라이브영상/WebRTC·HLS = edtech 일반 기능이나 **본 앱 비대상**.

## 개발환경 특수 요구
- 비프로드 미성년자 데이터 마스킹.
- COPPA/PIPA-safe 합성 테스트데이터 (CI 에 실제 미성년 PII 금지).
- 보호자 동의 플로우 테스트 픽스처(미성년 가입 허용 시).
- a11y CI 게이트 (KWCAG/WCAG) — VoiceOver·Dynamic Type 핵심 흐름.

## 추가 시험 (test/ 반영)
- 만14세 미만 가입 시 보호자 동의 없으면 차단 (미성년 가입 허용 시).
- 미성년자 PII 비프로드 마스킹 검증.
- (앱) 접근성: VoiceOver 라벨·Dynamic Type 레이아웃 깨짐 없음.

## 출처 / References
- https://easylaw.go.kr/CSP/CnpClsMain.laf?popMenu=ov&csmSeq=659 (만14세미만 보호자동의)
- https://casenote.kr/법령/개인정보_보호법/제22조의2 (PIPA §22-2)
- https://complydog.com/blog/edtech-saas-compliance-student-privacy-gdpr-implementation (COPPA 2025/2026)
