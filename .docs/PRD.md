# One-Page PRD: VNB4-Toeic (iOS Native / Swift)

## 1. 개요
- **한 줄 요약**: 기존 React Native(Expo) TOEIC 단어장 앱을 Apple 네이티브(Swift / SwiftUI)로 재구현하여 iOS·iPad에 출시한다.
- **배경 / 왜 지금 하는가**: RN 앱은 iOS/Android/web 동시 출시에 적합했으나, 상위 폴더 경로 괄호 이슈로 로컬 iOS 네이티브 빌드 실패·Expo 종속·웹 100% 동작 불일치 등 iOS 품질/성능 한계가 있다(참고: 기존 README §7 에러 매트릭스). 네이티브 Swift로 가면 시스템 TTS·차트·접근성·앱스토어 적합성을 iOS 1급으로 끌어올린다.
- **작성자 / 날짜 / 버전**: dl_761qi@edentns.com / 2026-06-08 / v0.3 (구현 완료)
- **업종(KSIC)**: 교육·에듀테크 (P, edtech) — `가정:` 성인 TOEIC 학습자 대상(미성년자 비주력).

## 2. 문제와 대상 (Why & Who)
- **해결하려는 핵심 문제**: TOEIC 학습자가 파트별 어휘를 IPA·한글발음·예문·다국적 발음과 함께 외우고, 약점 유형을 추적하며 복습할 단일 모바일 도구가 부족하다. RN 버전은 iOS 네이티브 빌드·성능·플랫폼 적합성에서 제약이 있다.
- **비즈니스 관점 중요성**: iOS 사용자에게 네이티브 수준 UX(시스템 TTS, Swift Charts, Dynamic Type 접근성, 오프라인)를 제공해 리텐션·앱스토어 평점·심사 통과율을 높인다.
- **근거 데이터 / VOC / 로그**: `가정:` 정량 VOC 미확보. 기존 RN 앱 기능·이슈 문서(README/PUBAPP)를 근거로 함.
- **타깃 사용자 / 페르소나**: TOEIC 점수 향상이 필요한 직장인·취준생·대학생. 게스트(가입 없이 오프라인 학습) ↔ 로그인(서버 동기화·약점 분석) 두 모드.
- **대표 사용 상황**: 출퇴근/자투리 시간에 폰으로 파트별 단어를 듣고(TTS) 외우고, 주기적으로 복습 큐를 소화하고, 약점 유형 도넛을 확인한다.

## 3. 범위 (What — In / Out)

이번 릴리즈 = **전체 기능 패리티** (RN 앱 전 기능 네이티브 이식) + **UX 개선 5종**.

### 3-A. 핵심 기능 (모두 구현 완료 ✅)

| # | 핵심 기능 (P0/P1) | 설명 | 구현 |
|---|---|---|---|
| 1 | **단어 학습 카드** (P0) | 이미지→POS→단어+TTS→IPA·한글발음→로케일칩(US/GB/AU)→뜻→예문(타겟 굵게)+TTS→예문번역. 하단 툴바(이전/모름/즐겨찾기/다음) | `LearnView.swift` ✅ |
| 2 | **파트별 전체 단어 학습** (P0) | LC(Part 1–4)/RC(Part 5–7) 그리드, 카드 진입 시 해당 파트 전체 단어 | `HomeView.swift` + `LearnView.swift` ✅ |
| 3 | **다국적 TTS 재생** (P0) | en-US/GB/AU. `AVSpeechSynthesizer`(시스템 음성) | `Tts.swift` ✅ |
| 4 | **SRS 복습 큐** (P0) | 홈 복습 카드 → 복습 due 단어. CoreData `WordProgress(grade, updatedAt)` 영속화 | `Persistence.swift` + `Repository.swift` ✅ |
| 5 | **취약유형 통계 도넛** (P1) | 게스트=빈 트랙+CTA, 로그인=LC/RC 정답·오답 4분할. SwiftUI Canvas 직접 구현 | `ScoreDonut.swift` ✅ |
| 6 | **문장쓰기·쉐도잉** (P1) | Part 1–4. 한글 힌트→단어칩 골라 문장 완성→확인→정답+전체문장 🔊 | `WriteView.swift` ✅ |
| 7 | **게스트/로그인 + Email 인증** (P0) | 게스트=번들 시드 오프라인, 로그인=서버 동기화. 토큰=Keychain | `AuthStore.swift` + `Keychain.swift` ✅ |
| 8 | **즐겨찾기(북마크)** (P1) | 단어·문장 북마크. CoreData(Favorite) + UserDefaults JSON 영속화 | `Persistence.swift` (LocalStore) ✅ |

### 3-B. UX 개선 (v0.3 신규 구현 ✅)

| # | 기능 | 설명 | 구현 |
|---|---|---|---|
| A | **단어 관련 이미지** | 단어 키워드 기반 이미지 (`loremflickr.com/640/420/{word}`). 백엔드 imageUrl 우선, 없으면 loremflickr 폴백 | `LearnView.imageURL()` ✅ |
| B | **북마크 모아보기** | 홈 카드 → 단어·문장 북마크 목록 화면(스와이프 삭제 지원) | `BookmarksView.swift` + `Route.bookmarks` ✅ |
| C | **이어 학습하기** | LearnView 이탈 후 복귀 시 마지막 인덱스 복원. `UserDefaults["learn_progress"]` `[lessonId: Int]` 맵 | `LocalStore.saveProgress / loadProgress` ✅ |
| D | **좌우 스와이프 제스처** | DragGesture(minimumDistance: 40) — 왼쪽=다음, 오른쪽=이전 | `LearnView` body ✅ |
| E | **문장쓰기 UX 개선** | 힌트 패널(노란 박스, fullSentence), 이전 버튼(`goPrev`), 문장 북마크 토글, 4버튼 툴바 | `WriteView.swift` ✅ |

- **하지 않을 것 (Out of Scope)**: Android·웹(이번 릴리즈는 iOS/iPad 전용), 서버 백엔드 신규 개발(기존 API_URL 재사용), 실시간 라이브클래스·영상, OTA 업데이트, 결제/구독.

## 4. 사용자 경험 (How — User Flow)
- **시나리오 1 (게스트 학습)**: 앱 첫 실행 → 게스트로 홈 진입(빈 도넛+"테스트 후 확인") → LC/RC 그리드에서 파트 선택 → 단어 카드 스와이프 학습, TTS 듣기, 모름/즐겨찾기 표시 → 모두 오프라인(번들 시드 3,686단어/198문항). 앱 재진입 시 마지막 위치에서 이어 학습.
- **시나리오 2 (로그인 동기화)**: 홈 상단 인증 바에서 회원가입/로그인(Email+PW) → 서버에서 최신 단어·복습 due·약점 분석 fetch → 도넛에 LC/RC 정답·오답 표시 → 복습 큐 소화 → 진도가 서버 동기화.
- **시나리오 3 (북마크 복습)**: 학습 중 단어/문장 🏷 탭 → 홈 '북마크 모아보기' 카드 → 저장된 단어·문장 목록 확인·삭제.
- **시나리오 4 (문장쓰기·쉐도잉)**: 홈 '문장쓰기·쉐도잉' 섹션 → Part 선택 → 한글 번역 보고 단어칩 배열 → 💡힌트로 전체 문장 확인 → 확인·TTS 쉐도잉 → 문장 🏷 북마크.

## 5. 성공 지표 (Success)

| KPI | 기준선(Baseline) | 목표값(Target) | 측정 방법 |
|---|---|---|---|
| 기능 패리티 | RN 앱 8개 기능 | 8/8 네이티브 동작 ✅ 달성 | QA 시나리오 체크리스트(test/impl) |
| UX 개선 | 0 | 5종 구현 ✅ 달성 | 빌드 성공 + 수동 QA |
| 앱스토어 심사 | `가정:` 미제출 | 1회 통과 | App Store Connect |
| 콜드 스타트 | `가정:` RN ~측정 | < 2초 (iPhone 12 기준) | Instruments / Xcode |
| 오프라인 동작 | 게스트 전 기능 | 네트워크 0에서 학습 완주 | 기내모드 QA |
| 크래시-프리 세션율 | — | ≥ 99.5% | `가정:` Crashlytics/Xcode Organizer |
| 접근성(KWCAG/WCAG) | — | Dynamic Type·VoiceOver 핵심 흐름 통과 | a11y QA 게이트 |

## 6. 리스크 및 메모
- **주요 리스크**
  - TTS 음질/로케일: `AVSpeechSynthesizer`의 US/GB/AU 음성 품질이 expo-av 대비 차이 가능 → 음성 가용성 검증 필요.
  - 데이터 계약: 기존 서버 API 스키마(part 코어션 "P1"→1, pos 자유문자열, nullable 필드)를 Swift `Codable`로 관용 파싱. `SentenceItem.CodingKeys`에 `orderIndex` 포함(서버 필드명 혼용) → 커스텀 `init(from:)` 적용.
  - 이미지: `loremflickr.com` 외부 CDN 의존. 오프라인 시 이미지 미노출(기능에는 영향 없음).
- **의존성 (내부/외부)**
  - 외부: 기존 백엔드 서버(API_URL), Apple Developer 계정·인증서, App Store Connect, loremflickr CDN(이미지).
  - 내부: 번들 시드(words.json 3,686단어, sentences.json 198문항), VNB4-Toeic-database.
- **규제 / 데이터등급 (edtech 오버레이)**
  - PIPA: 학습자 PII(이메일·학습기록) 수명주기. 토큰·PII는 Keychain 저장.
  - 만14세 미만 가입 시 보호자 동의 게이트 — `가정:` 성인 대상 비주력.
  - 웹접근성 KWCAG/WCAG — iOS Dynamic Type·VoiceOver 대응.

## 7. 기술 메모 (구현 결정)

| 항목 | 결정 | 비고 |
|---|---|---|
| UI 프레임워크 | SwiftUI 단독 | UIKit 랩핑 불필요 |
| 영속화 | CoreData(Favorite, WordProgress) + UserDefaults JSON | 단어·문장 북마크 전체 객체, 학습 진도는 UserDefaults |
| 이미지 | 백엔드 `imageUrl` 우선 → `loremflickr.com/640/420/{word}` | picsum 대체; 단어 연관 이미지 |
| 통계 도넛 | SwiftUI Canvas 직접 구현 | Swift Charts 불필요 |
| 프로젝트 파일 | VNB4Toeic.xcodeproj 직접 편집 | XcodeGen 전환 준비(project.yml 유지) |
| 빌드 검증 | xcodebuild -scheme App | iPhone 17 Pro 시뮬레이터 |

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| v0.1 | 2026-06-08 | 초안 작성. 8개 핵심 기능 정의 |
| v0.2 | 2026-06-20 | 핵심 기능 8종 구현 완료. 영속화 방식 결정(CoreData + UserDefaults) |
| v0.3 | 2026-06-28 | UX 개선 5종 구현(loremflickr 이미지, 북마크 모아보기, 이어 학습, 스와이프 제스처, WriteView 힌트/이전/북마크). 미결정 사항 해소 |

---

### 자가 점검 (Definition of Ready)
- [x] 문제 정의가 실제 사용자 문제를 설명 — TOEIC 어휘 학습 + iOS 네이티브 품질
- [x] In/Out Scope 둘 다 명확 — 8기능 + UX 5종 In, Android/웹/백엔드신규/라이브 Out
- [x] 성공 지표 측정 가능 + 기준선 — 기능 패리티·UX 개선 달성 확인
- [x] 수용 기준 — test/impl 시나리오로 검증
- [x] 의존성·리스크 노출 — 서버 API·TTS·loremflickr·시드 이식 명시
- [x] 규제·데이터등급 반영 — PIPA·KWCAG
