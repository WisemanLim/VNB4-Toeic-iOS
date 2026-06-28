# VNB4Toeic (iOS Native / Swift)

> 🌐 **언어**: **한국어** · [English](README.en.md)

TOEIC 어휘 학습 iOS 네이티브 앱 (Swift + SwiftUI). 기존 React Native(Expo) 앱을 네이티브로 이식.

- **앱 이름**(홈화면): Vocabulary Notebook for TOEIC · **App Store 이름**: TOEIC Vocabulary Notebook – VNB4 · **번들 ID**: `com.vnb4.vocabnote`

> 관련 문서: [PRD.md](.docs/PRD.md) · [COMPLIANCE.md](COMPLIANCE.md)

## 기술 스택
| 구분 | 도구 |
|------|------|
| 언어 | Swift 6 |
| UI | SwiftUI (iOS **16+**, iPhone+iPad) |
| 프로젝트 | VNB4Toeic.xcodeproj (직접 편집, `project.yml` XcodeGen 소스 병행) |
| 영속화 | CoreData(즐겨찾기·SRS 등급) + UserDefaults JSON(북마크 객체·학습 진도) |
| 토큰 | Keychain |
| 오프라인 | 번들 시드(words.json 3,686단어 / sentences.json 198문항) |
| 음성 | AVSpeechSynthesizer (시스템 TTS, US/GB/AU) |
| 이미지 | `loremflickr.com`(단어 키워드 연관) / 백엔드 imageUrl 우선 |
| 차트 | 직접 구현 도넛(trimmed Circle, iOS 16 호환) |
| 배포 | Fastlane → TestFlight |
| CI | GitHub Actions (macOS) |

## 아키텍처 / 디렉터리
```
App/Sources/
├── App.swift
├── ContentView.swift
├── Core/
│   ├── Models.swift       # Codable: Word/SentenceItem/Analysis (part 코어션·lenient)
│   ├── Seed.swift         # 번들 words.json/sentences.json 로더
│   ├── APIClient.swift    # URLSession async + 게스트 mock 라우팅 + 토큰
│   ├── Mocks.swift        # 시드 기반 오프라인 라우팅
│   ├── Repository.swift   # 데이터 접근
│   ├── AuthStore.swift    # 세션(guest/authed), login/signup/logout
│   ├── ConsentGate.swift  # 만14세 미만 보호자 동의 게이트(PIPA §22-2)
│   ├── Persistence.swift  # CoreData(Favorite·WordProgress) + LocalStore(북마크·진도 UserDefaults)
│   ├── Keychain.swift     # 토큰 저장
│   └── Theme.swift        # 디자인 토큰 + 파트 카탈로그
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift     # 홈(그리드·복습카드·북마크 카드)
│   │   └── ScoreDonut.swift   # 취약유형 도넛
│   ├── Learn/
│   │   ├── LearnView.swift    # 단어 학습 카드(스와이프·진도복원·loremflickr)
│   │   ├── BookmarksView.swift # 북마크 모아보기(단어·문장)
│   │   └── Tts.swift          # AVSpeechSynthesizer 래퍼
│   ├── Write/
│   │   └── WriteView.swift    # 문장쓰기·쉐도잉(힌트·이전·북마크)
│   └── Auth/
│       └── LoginView.swift
App/Resources/             # words.json · sentences.json · Assets.xcassets(AppIcon/AccentColor)
Config/                    # Debug/Staging/Release.xcconfig (API_BASE_URL)
AppTests/ · AppUITests/    # XCTest · XCUITest
test/                      # 시험 표준 (dev-env · impl/<Nth>)
```

### 데이터 소스 전환
- **게스트(미로그인)** → 번들 시드 + `Mocks`, 완전 오프라인.
- **로그인** → 실서버(`API_BASE_URL`/api/v1)에서 단어·문장·복습·분석 동기화. `/auth/*`는 항상 서버.
- `USE_MOCK`(Info.plist) → 인증 무관 전부 mock.

## 사전 요구사항
- macOS + **Xcode 16+**
- (선택) **XcodeGen** (`brew install xcodegen`) — `project.yml` 기반 재생성 시 필요
- (배포 시) Ruby/Bundler + Fastlane, Apple Developer 계정

## 환경 설정
`API_BASE_URL`은 `Config/*.xcconfig` → Info.plist → `Env.apiBase`로 주입. 실시크릿·서명키 **커밋 금지**.

| 환경 | 파일 | flavor | API base |
|---|---|---|---|
| local | `.env.local` | Debug | http://localhost:4000 |
| dev | `.env.dev` | Debug | https://dev.api.example `가정:` |
| staging | `.env.staging` | Staging | https://stg.api.example `가정:` |
| prod | `.env.prod` | Release | (주입) |

## 실행 방법

### 시뮬레이터 (권장)
```bash
# Xcode에서 열기
open VNB4Toeic.xcodeproj   # ▶ Cmd+R

# 커맨드라인 빌드
xcodebuild -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# Makefile 단축 (XcodeGen 워크플로)
make gen     # project.yml → VNB4Toeic.xcodeproj 재생성
make dev     # gen + 시뮬레이터 빌드
make test    # gen + XCTest/XCUITest
```

> `VNB4Toeic.xcodeproj`는 **커밋 포함** (직접 편집). `project.yml`은 XcodeGen 소스로 병행 유지.

### 빌드 & 배포 (Fastlane → TestFlight)
```bash
make build   # fastlane ios build (gym 아카이브 .ipa)
make deploy  # fastlane ios beta (TestFlight 업로드)
```
> 서명은 `match`/ASC API key 주입 — `.p12`·프로비저닝 커밋 금지. 현재 스텁.

## 구현 기능

### 핵심 기능 (PRD 3-A)
| 기능 | 위치 |
|---|---|
| 단어 학습 카드 (이미지·IPA·한글발음·예문·TTS) | [LearnView.swift](App/Sources/Features/Learn/LearnView.swift) |
| 다국적 TTS (US/GB/AU) | [Tts.swift](App/Sources/Features/Learn/Tts.swift) |
| 파트별 단어 학습 (LC Part1–4 / RC Part5–7) | HomeView 그리드 + Repository |
| SRS 복습 큐 | HomeView 복습카드 |
| 취약유형 도넛 통계 | [ScoreDonut.swift](App/Sources/Features/Home/ScoreDonut.swift) |
| 문장쓰기·쉐도잉 (단어칩→확인→🔊) | [WriteView.swift](App/Sources/Features/Write/WriteView.swift) |
| 게스트/로그인 + Email 인증 | [AuthStore.swift](App/Sources/Core/AuthStore.swift) |
| 즐겨찾기·북마크 영속화 | [Persistence.swift](App/Sources/Core/Persistence.swift) |
| 게스트 SRS 실 진도 연동 (dueCount + due 큐 → LocalStore grade < 4) | [Repository.swift](App/Sources/Core/Repository.swift) + [Persistence.swift](App/Sources/Core/Persistence.swift) |
| 미성년 보호자 동의 게이트 (PIPA §22-2) | [ConsentGate.swift](App/Sources/Core/ConsentGate.swift) |
| 접근성 (VoiceOver·Dynamic Type) | LearnView accessibilityLabel |
| iPad 적응형 레이아웃 (2↔4열) | [HomeView.swift](App/Sources/Features/Home/HomeView.swift) |

### UX 개선 (PRD 3-B, v0.3)
| 기능 | 설명 | 위치 |
|---|---|---|
| 단어 관련 이미지 | loremflickr.com 키워드 이미지 (백엔드 imageUrl 우선) | LearnView.imageURL() |
| 북마크 모아보기 | 저장 단어·문장 목록, 스와이프 삭제 | [BookmarksView.swift](App/Sources/Features/Learn/BookmarksView.swift) |
| 이어 학습하기 | 앱 재진입 시 마지막 인덱스 복원 (UserDefaults) | LocalStore.saveProgress/loadProgress |
| 좌우 스와이프 제스처 | DragGesture — 왼쪽=다음, 오른쪽=이전 | LearnView body |
| WriteView UX 개선 | 💡 힌트(전체 문장), ‹ 이전, 🏷 북마크 버튼, 4버튼 툴바 | WriteView.swift |

## 테스트
```bash
make test
# 개별: test/impl/<Nth>/scenario.md + result.md
```
최신 차수 5 결과: **PASS** (8 unit + 1 UI). → [5](test/impl/5/result.md) · [4](test/impl/4/result.md) · [3](test/impl/3/result.md) · [2](test/impl/2/result.md) · [1](test/impl/1/result.md)

## 트러블슈팅 (실제 만난 이슈)
| 증상 | 원인 | 조치 |
|---|---|---|
| `does not contain a scheme named "App"` | SPM-only 패키지 = 앱 스킴 없음 | XcodeGen 도입(`make gen`) |
| `scheme ... iPhone 15` 없음 | 머신에 17-series만 있음 | Makefile DEST `iPhone 17 Pro` |
| `Tts.shared not concurrency-safe` | Swift 6 strict concurrency | `@MainActor` |
| 테스트 `Cannot code sign ... Info.plist` | 테스트 타깃 plist 미생성 | project.yml `GENERATE_INFOPLIST_FILE: YES` |
| 업로드 `CFBundleIconName 누락(90713)` | 실 아이콘 PNG 부재 | 1024 PNG 추가 + info.properties에 CFBundleIconName 명시 |
| 업로드 `오리엔테이션 미지정(90474)` | UISupportedInterfaceOrientations 부재 | info.properties에 iPhone portrait + ~ipad 4방향 추가 |
| `SentenceItem encode(to:) invalid redeclaration` | Swift가 CodingKeys 기반으로 encode 합성함 — 수동 구현 충돌 | 수동 `encode(to:)` 제거 (합성으로 충분) |

## 다음 단계 (PRD 잔여)
- 로그인/회원가입 **서버 연동** 실검증 (실 API_BASE_URL) + `/users/me` 부팅 복원.
- SRS 서버 채점(`/progress/grade`)·서버 분석(`/me/analysis`) 실연동.
- 앱 아이콘 **디자인 확정** — 현재 자동 생성 플레이스홀더.
- a11y 자동 회귀 (Dynamic Type 스냅샷·VoiceOver 감사) 시험 도입.
- 실 TestFlight 업로드 재검증.
