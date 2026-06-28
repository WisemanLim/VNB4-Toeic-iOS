# One-Page PRD: VNB4-Toeic (iOS Native / Swift)

## 1. 개요
- **한 줄 요약**: 기존 React Native(Expo) TOEIC 단어장 앱을 Apple 네이티브(Swift / SwiftUI)로 재구현하여 iOS·iPad에 출시한다.
- **배경 / 왜 지금 하는가**: RN 앱은 iOS/Android/web 동시 출시에 적합했으나, 상위 폴더 경로 괄호 이슈로 로컬 iOS 네이티브 빌드 실패·Expo 종속·웹 100% 동작 불일치 등 iOS 품질/성능 한계가 있다(참고: 기존 README §7 에러 매트릭스). 네이티브 Swift로 가면 시스템 TTS·차트·접근성·앱스토어 적합성을 iOS 1급으로 끌어올린다.
- **작성자 / 날짜 / 버전**: dl_761qi@edentns.com / 2026-06-08 / v0.1 (draft)
- **업종(KSIC)**: 교육·에듀테크 (P, edtech) — `가정:` 성인 TOEIC 학습자 대상(미성년자 비주력).

## 2. 문제와 대상 (Why & Who)
- **해결하려는 핵심 문제**: TOEIC 학습자가 파트별 어휘를 IPA·한글발음·예문·다국적 발음과 함께 외우고, 약점 유형을 추적하며 복습할 단일 모바일 도구가 부족하다. RN 버전은 iOS 네이티브 빌드·성능·플랫폼 적합성에서 제약이 있다.
- **비즈니스 관점 중요성**: iOS 사용자에게 네이티브 수준 UX(시스템 TTS, Swift Charts, Dynamic Type 접근성, 오프라인)를 제공해 리텐션·앱스토어 평점·심사 통과율을 높인다.
- **근거 데이터 / VOC / 로그**: `가정:` 정량 VOC 미확보. 기존 RN 앱 기능·이슈 문서(README/PUBAPP)를 근거로 함.
- **타깃 사용자 / 페르소나**: TOEIC 점수 향상이 필요한 직장인·취준생·대학생. 게스트(가입 없이 오프라인 학습) ↔ 로그인(서버 동기화·약점 분석) 두 모드.
- **대표 사용 상황**: 출퇴근/자투리 시간에 폰으로 파트별 단어를 듣고(TTS) 외우고, 주기적으로 복습 큐를 소화하고, 약점 유형 도넛을 확인한다.

## 3. 범위 (What — In / Out)

이번 릴리즈 = **전체 기능 패리티** (RN 앱 전 기능 네이티브 이식).

| # | 핵심 기능 (P0/P1) | 설명 (RN 대응) |
|---|---|---|
| 1 | **단어 학습 카드** (P0) | 일러스트→POS→단어+TTS→IPA·한글발음→로케일칩(US/GB/AU)→뜻→예문(타겟 굵게)+TTS→예문번역. 하단 툴바(이전/모름/즐겨찾기/다음) |
| 2 | **파트별 전체 단어 학습** (P0) | LC(Part 1–4)/RC(Part 5–7) 그리드, 카드 진입 시 해당 파트 전체 단어(20제한 없음) |
| 3 | **다국적 TTS 재생** (P0) | en-US/GB/AU. `가정:` `AVSpeechSynthesizer`(시스템 음성)로 expo-av 대체 |
| 4 | **SRS 복습 큐** (P0) | 홈 복습 카드 → 복습 due 단어 |
| 5 | **취약유형 통계 도넛** (P1) | 게스트=빈 트랙+CTA, 로그인=LC/RC 정답·오답 4분할. `가정:` Swift Charts |
| 6 | **문장쓰기·쉐도잉** (P1) | Part 1–4. 한글 힌트→단어칩 골라 문장 완성→확인→정답+전체문장 🔊 |
| 7 | **게스트/로그인 + Email 인증** (P0) | 게스트=번들 시드 오프라인, 로그인=서버 동기화. 토큰=Keychain(`가정:` expo-secure-store 대체) |
| 8 | **노트/즐겨찾기** (P1) | 카드 북마크. `가정:` 영속화는 RN에서 M5였음 → 네이티브는 SwiftData 영속화 포함 검토 |

- **하지 않을 것 (Out of Scope)**: Android·웹(이번 릴리즈는 iOS/iPad 전용), 서버 백엔드 신규 개발(기존 API_URL 재사용), 실시간 라이브클래스·영상(에듀테크 일반 기능이나 본 앱 비대상), OTA 업데이트(Expo 기능 제거), 결제/구독.

## 4. 사용자 경험 (How — User Flow)
- **시나리오 1 (게스트 학습)**: 앱 첫 실행 → 게스트로 홈 진입(빈 도넛+"테스트 후 확인") → LC/RC 그리드에서 파트 선택 → 단어 카드 스와이프 학습, TTS 듣기, 모름/즐겨찾기 표시 → 모두 오프라인(번들 시드 3,686단어/198문항).
- **시나리오 2 (로그인 동기화)**: 홈 상단 인증 바에서 회원가입/로그인(Email+PW) → 서버에서 최신 단어·복습 due·약점 분석 fetch → 도넛에 LC/RC 정답·오답 표시 → 복습 큐 소화 → 진도가 서버 동기화.

## 5. 성공 지표 (Success)

| KPI | 기준선(Baseline) | 목표값(Target) | 측정 방법 |
|---|---|---|---|
| 기능 패리티 | RN 앱 8개 기능 | 8/8 네이티브 동작 | QA 시나리오 체크리스트(test/impl) |
| 앱스토어 심사 | `가정:` 미제출 | 1회 통과 | App Store Connect |
| 콜드 스타트 | `가정:` RN ~측정 | < 2초 (iPhone 12 기준) | Instruments / Xcode |
| 오프라인 동작 | 게스트 전 기능 | 네트워크 0에서 학습 완주 | 기내모드 QA |
| 크래시-프리 세션율 | — | ≥ 99.5% | `가정:` Crashlytics/Xcode Organizer |
| 접근성(KWCAG/WCAG) | — | Dynamic Type·VoiceOver 핵심 흐름 통과 | a11y QA 게이트 |

`가정:` 학습 효과 지표(7일 리텐션·일 학습단어수)는 로그인 서버 이벤트 확보 후 추가.

## 6. 리스크 및 메모
- **주요 리스크**
  - TTS 음질/로케일: `AVSpeechSynthesizer`의 US/GB/AU 음성 품질이 expo-av 대비 차이 가능 → 음성 가용성 검증 필요.
  - 데이터 계약: 기존 서버 API 스키마(part 코어션 "P1"→1, pos 자유문자열, nullable 필드)를 Swift `Codable`로 관용 파싱해야 함(기존 Zod 스키마가 단일 소스).
  - 시드 변환: RN `assets/seed/words.json`(3,686단어)·`sentences.json`(198문항)을 번들 리소스로 이식 + 로더 재작성.
- **의존성 (내부/외부)**
  - 외부: 기존 백엔드 서버(API_URL, `/auth/*`·`/words`·`/learn/due`·`/me/analysis`·`/sentences`), Apple Developer 계정·인증서, App Store Connect.
  - 내부: 기존 시드 DB(VNB4-Toeic-database), RN 소스(이식 기준 레퍼런스).
- **규제 / 데이터등급 (edtech 오버레이, domains/edtech.yaml)**
  - PIPA: 학습자 PII(이메일·학습기록=민감) 수명주기(동의·최소수집·보유·삭제). 학습기록은 민감 취급. [출처: PIPA]
  - 만14세 미만 가입 시 보호자 동의 게이트 — `가정:` 성인 대상이라 비주력이나, 미성년 가입 가능성 있으면 연령 확인/차단 필요. [출처: PIPA §22-2]
  - 토큰·PII는 Keychain 저장, 비프로드 실제 PII 금지(합성 테스트데이터).
  - 웹접근성 KWCAG/WCAG — iOS Dynamic Type·VoiceOver 대응.
- **미결정 사항 (Open Questions)**
  1. UI: SwiftUI 단독 vs 부분 UIKit 랩핑 — 차트/제스처 영역만 확인 필요. (현 결정: SwiftUI 우선)
  2. 로컬 영속화: SwiftData vs CoreData vs 파일 — 즐겨찾기/오프라인 진도 저장 방식.
  3. 서버 API 스펙 문서 위치(OpenAPI 유무) — Codable 모델 확정 근거.
  4. 크래시/분석 SDK 채택 여부(Crashlytics 등)와 PIPA 동의 영향.
  5. iPad 레이아웃: iPhone 스케일 vs 적응형(Split) 설계 범위.

---

### 자가 점검 (Definition of Ready)
- [x] 문제 정의가 실제 사용자 문제를 설명 — TOEIC 어휘 학습 + iOS 네이티브 품질
- [x] In/Out Scope 둘 다 명확 — 8기능 In, Android/웹/백엔드신규/라이브 Out
- [x] 성공 지표 측정 가능 + 기준선 — 일부 `가정:` (콜드스타트·크래시율 baseline 미측정)
- [△] 수용 기준 Given-When-Then — KPI는 측정법 명시, 세부 AC는 implement 단계에서 시나리오화
- [x] 의존성·리스크 노출 — 서버 API 계약·TTS·시드 이식 명시
- [x] 규제·데이터등급 반영 — PIPA·미성년 동의·KWCAG를 리스크에 반영(edtech.yaml 근거)
