# VNB4Toeic (iOS Native / Swift)

> 🌐 **언어**: **한국어** · [English](README.en.md)

TOEIC 어휘 학습 iOS 네이티브 앱 (Swift + SwiftUI). 기존 React Native(Expo) 앱
([VNB4-Toeic-app](../../Apps-Mobile/VNB4-Toeic-app))을 네이티브로 이식.

- **앱 이름**(홈화면): Vocabulary Notebook for TOEIC · **App Store 이름**: TOEIC Vocabulary Notebook – VNB4 · **번들 ID**: `com.vnb4.vocabnote`

> **스캐폴딩**: `wise-dev-standard` 플러그인 / 프로파일 `ios-swiftui` / 도메인 `edtech`.
> 관련 문서: [PRD.md](PRD.md) · [COMPLIANCE.md](COMPLIANCE.md)

## 기술 스택
| 구분 | 도구 |
|------|------|
| 언어 | Swift 6 |
| UI | SwiftUI (iOS **16+**, iPhone+iPad) |
| 프로젝트 생성 | **XcodeGen** (`project.yml` → `.xcodeproj`) |
| 저장 | Keychain(토큰) · 번들 시드(오프라인) |
| 음성 | AVSpeechSynthesizer (시스템 TTS, US/GB/AU) |
| 차트 | 직접 구현 도넛(트림 Circle, iOS16 호환) |
| 배포 | Fastlane → TestFlight |
| CI | GitHub Actions (macOS) |

## 아키텍처 / 디렉터리
```
App/Sources/
├── App.swift              # @main, AuthStore 주입
├── ContentView.swift      # 루트 게이트(loading→Home)
├── Core/
│   ├── Models.swift       # Codable: Word/SentenceItem/Analysis/Lesson… (part 코어션·lenient)
│   ├── Seed.swift         # 번들 words.json/sentences.json 로더
│   ├── APIClient.swift    # URLSession async + 게스트 mock 라우팅 + 토큰
│   ├── Mocks.swift        # 시드 기반 오프라인 라우팅(/words,/sentences,/me/analysis…)
│   ├── Repository.swift   # 데이터 접근(RN queries.ts 이식)
│   ├── AuthStore.swift    # 세션(guest/authed), login/signup/logout + 미성년 동의 게이트
│   ├── ConsentGate.swift  # 만14세 미만 보호자 동의 게이트(PIPA §22-2)
│   ├── Persistence.swift  # CoreData(프로그래매틱) + LocalStore(즐겨찾기·진도 영속화)
│   ├── Keychain.swift     # 토큰 저장
│   └── Theme.swift        # 디자인 토큰 + 파트 카탈로그
├── Features/
│   ├── Home/HomeView.swift, ScoreDonut.swift
│   ├── Learn/LearnView.swift, Tts.swift
│   ├── Write/WriteView.swift
│   └── Auth/LoginView.swift
App/Resources/             # words.json(3,686단어)·sentences.json(198문항) + Assets.xcassets(AppIcon/AccentColor) 번들
Config/                    # Debug/Staging/Release.xcconfig (API_BASE_URL·flavor)
AppTests/ · AppUITests/    # XCTest · XCUITest
test/                      # 시험 표준(dev-env·impl/<Nth>)
```

### 데이터 소스 전환 (RN 동작 이식)
- **게스트(미로그인)** → 번들 시드 + `Mocks` 로 **완전 오프라인** 동작.
- **로그인** → 실서버(`API_BASE_URL`/api/v1)에서 단어·문장·복습·분석 동기화. `/auth/*` 는 항상 서버.
- `USE_MOCK`(Info.plist) → 인증 무관 전부 mock.

## 사전 요구사항
- macOS + **Xcode 16+**
- **XcodeGen** (`brew install xcodegen`) — `.xcodeproj` 생성에 필요
- (배포 시) Ruby/Bundler + Fastlane, Apple Developer 계정

## 환경 설정
flavor + `API_BASE_URL` + 서명 (DB 없음 — 모바일). 실시크릿·서명키 **커밋 금지**.

| 환경 | 파일 | flavor | API base |
|---|---|---|---|
| local | [.env.local](.env.local) | Debug | http://localhost:4000 |
| dev | [.env.dev](.env.dev) | Debug | https://dev.api.example `가정:` |
| staging | [.env.staging](.env.staging) | Staging | https://stg.api.example `가정:` |
| prod | [.env.prod](.env.prod) | Release | (주입) |

`API_BASE_URL` 은 `Config/*.xcconfig` → Info.plist → `Env.apiBase` 로 주입. 서버 주소 확정 시 xcconfig 교체.

## 실행 방법 (시뮬레이터)
```bash
make gen     # project.yml → VNB4Toeic.xcodeproj (소스/설정 변경 시 재생성)
make dev     # gen + iPhone 17 시뮬레이터 빌드
make test    # gen + XCTest/XCUITest
open VNB4Toeic.xcodeproj   # Xcode에서 ▶ Cmd+R

# 다른 시뮬레이터
make dev DEST='platform=iOS Simulator,name=iPhone 17 Pro'
```
> `.xcodeproj` 는 생성물(gitignore). `project.yml` 만 커밋. 클론 후 `make gen` 선행.

### 빌드 & 배포 (Fastlane → TestFlight)
```bash
make build   # fastlane ios build (gym 아카이브 .ipa)
make deploy  # fastlane ios beta (TestFlight 업로드)
```
> 서명은 `match`/ASC API key 주입 — `.p12`·프로비저닝 커밋 금지(README 정책). 미실행(스텁).

## 구현 기능 (PRD 매핑)
| PRD 기능 | 구현 | 위치 |
|---|---|---|
| 단어 학습 카드(IPA/한글발음/예문/그림) | ✅ | [LearnView.swift](App/Sources/Features/Learn/LearnView.swift) |
| 다국적 TTS(US/GB/AU) | ✅ AVSpeechSynthesizer | [Tts.swift](App/Sources/Features/Learn/Tts.swift) |
| 파트별 전체 단어 학습 | ✅ (시드 part 필터, 페이지네이션) | Repository/Mocks |
| SRS 복습 큐 | ✅ (게스트=상위 30 샘플) | HomeView 복습카드 |
| 취약유형 도넛 통계 | ✅ (게스트=빈 트랙+CTA) | [ScoreDonut.swift](App/Sources/Features/Home/ScoreDonut.swift) |
| 문장쓰기·쉐도잉 | ✅ (단어칩→문장→확인→🔊) | [WriteView.swift](App/Sources/Features/Write/WriteView.swift) |
| 게스트/로그인 + Email 인증 | ✅ 게스트 오프라인 / 로그인 서버 | [AuthStore.swift](App/Sources/Core/AuthStore.swift) |
| 노트/즐겨찾기 + 진도 | ✅ CoreData 영속화 | [Persistence.swift](App/Sources/Core/Persistence.swift) |
| 미성년 보호자 동의 게이트 | ✅ 만14세 미만 차단(PIPA §22-2) | [ConsentGate.swift](App/Sources/Core/ConsentGate.swift) |
| 접근성(VoiceOver/Dynamic Type) | ✅ a11y 라벨 + 시스템 폰트 | LearnView |
| iPad 적응형 레이아웃 | ✅ size class(2↔4열) | [HomeView.swift](App/Sources/Features/Home/HomeView.swift) |

## 테스트
```bash
make test
# 개별: test/impl/<Nth>/scenario.md + result.md
```
최신 차수 3 결과: **PASS** (8 unit + 1 UI, App Store 검증오류 수정·확인). → [3](test/impl/3/result.md) · [2](test/impl/2/result.md) · [1](test/impl/1/result.md)

## 트러블슈팅 (실제 만난 이슈)
| 증상 | 원인 | 조치 |
|---|---|---|
| `does not contain a scheme named "App"` | SPM-only 패키지 = 앱 스킴 없음 | XcodeGen 도입(project.yml), `make gen` |
| `scheme ... iPhone 15` 없음 | 머신에 17-series만 | Makefile DEST `iPhone 17` |
| `Tts.shared not concurrency-safe` | Swift 6 strict concurrency | `@MainActor` |
| 테스트 `Cannot code sign ... Info.plist` | 테스트 타깃 plist 미생성 | project.yml `GENERATE_INFOPLIST_FILE: YES` |
| 업로드 `CFBundleIconName 누락(90713)` / 아이콘 120·152 누락(90022/3) | 실 아이콘 PNG 부재 + xcodegen 커스텀 plist 에 에셋카탈로그 partial plist 미병합 | 1024 PNG 추가 + info.properties 에 CFBundleIconName/CFBundleIcons(~ipad) 명시 |
| 업로드 `오리엔테이션 미지정(90474)` | UISupportedInterfaceOrientations 부재 | info.properties 에 iPhone portrait + ~ipad 4방향 추가 |
| 단어 이미지 안 보임 | 오프라인 picsum 미연결 | 정상(플레이스홀더). 온라인 시 표시 |

## 다음 단계 (PRD 잔여)
- 로그인/회원가입 **서버 연동** 실검증(실 API_BASE_URL) + `/users/me` 부팅 복원.
- SRS 서버 채점(`/progress/grade`)·서버 분석(`/me/analysis`) 실연동.
- 게스트 dueCount 를 로컬 진도(LocalStore)와 연동(현재 mock 샘플).
- 앱 아이콘 **디자인 확정** — 현재 자동 생성 플레이스홀더(브랜드 블루 + "VNB4 TOEIC").
- a11y 자동 회귀(Dynamic Type 스냅샷/접근성 감사) 시험 도입.
- 실 업로드 재검증(EAS/Transporter) — 현재는 시뮬레이터 빌드 plist 로만 확인.
