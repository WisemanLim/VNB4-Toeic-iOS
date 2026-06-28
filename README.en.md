# VNB4Toeic (iOS Native / Swift)

> 🌐 **Language**: [한국어](README.md) · **English**

Native iOS TOEIC vocabulary app (Swift + SwiftUI). A native port of the existing React Native (Expo) app.

- **App name** (home screen): Vocabulary Notebook for TOEIC · **App Store name**: TOEIC Vocabulary Notebook – VNB4 · **Bundle ID**: `com.vnb4.vocabnote`

> Docs: [PRD.md](.docs/PRD.md) · [COMPLIANCE.md](COMPLIANCE.md)

## Tech Stack
| Layer | Tool |
|------|------|
| Language | Swift 6 |
| UI | SwiftUI (iOS **16+**, iPhone + iPad) |
| Project | VNB4Toeic.xcodeproj (directly edited; `project.yml` XcodeGen source maintained in parallel) |
| Persistence | CoreData (favorites · SRS grades) + UserDefaults JSON (bookmark objects · learn progress) |
| Token | Keychain |
| Offline | Bundled seed (words.json 3,686 words / sentences.json 198 items) |
| Speech | AVSpeechSynthesizer (system TTS, US/GB/AU) |
| Images | `loremflickr.com` (keyword-relevant); backend `imageUrl` takes priority |
| Chart | Hand-rolled donut (trimmed Circle, iOS 16-safe) |
| Deploy | Fastlane → TestFlight |
| CI | GitHub Actions (macOS) |

## Architecture / Directory Layout
```
App/Sources/
├── App.swift
├── ContentView.swift
├── Core/
│   ├── Models.swift       # Codable: Word/SentenceItem/Analysis (part coercion, lenient)
│   ├── Seed.swift         # bundled words.json/sentences.json loader
│   ├── APIClient.swift    # URLSession async + guest mock routing + token injection
│   ├── Mocks.swift        # seed-backed offline routing
│   ├── Repository.swift   # data access layer
│   ├── AuthStore.swift    # session (guest/authed), login/signup/logout
│   ├── ConsentGate.swift  # guardian-consent gate for under-14 (PIPA §22-2)
│   ├── Persistence.swift  # CoreData (Favorite·WordProgress) + LocalStore (bookmarks·progress via UserDefaults)
│   ├── Keychain.swift     # token store
│   └── Theme.swift        # design tokens + part catalog
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift      # home (grid · review card · bookmarks card)
│   │   └── ScoreDonut.swift    # weakness-type donut chart
│   ├── Learn/
│   │   ├── LearnView.swift     # word learning card (swipe · progress restore · loremflickr)
│   │   ├── BookmarksView.swift # bookmark collection (words + sentences)
│   │   └── Tts.swift           # AVSpeechSynthesizer wrapper
│   ├── Write/
│   │   └── WriteView.swift     # sentence writing · shadowing (hint · prev · bookmark)
│   └── Auth/
│       └── LoginView.swift
App/Resources/             # words.json · sentences.json · Assets.xcassets (AppIcon/AccentColor)
Config/                    # Debug/Staging/Release.xcconfig (API_BASE_URL)
AppTests/ · AppUITests/    # XCTest · XCUITest
test/                      # testing standard (dev-env · impl/<Nth>)
```

### Data-source switch
- **Guest (not logged in)** → bundled seed + `Mocks`, fully **offline**.
- **Logged in** → real backend (`API_BASE_URL`/api/v1) syncs words/sentences/review/analysis. `/auth/*` always hits the server.
- `USE_MOCK` (Info.plist) → everything mocked, regardless of auth state.

## Prerequisites
- macOS + **Xcode 16+**
- (optional) **XcodeGen** (`brew install xcodegen`) — needed only to regenerate from `project.yml`
- (deploy) Ruby/Bundler + Fastlane, Apple Developer account

## Environment
`API_BASE_URL` flows `Config/*.xcconfig` → Info.plist → `Env.apiBase`. Never commit real secrets or signing keys.

| Env | File | flavor | API base |
|---|---|---|---|
| local | `.env.local` | Debug | http://localhost:4000 |
| dev | `.env.dev` | Debug | https://dev.api.example `assumed` |
| staging | `.env.staging` | Staging | https://stg.api.example `assumed` |
| prod | `.env.prod` | Release | (injected) |

## Run

### Simulator (recommended)
```bash
# Open in Xcode
open VNB4Toeic.xcodeproj   # ▶ Cmd+R

# Command-line build
xcodebuild -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# Makefile shortcuts (XcodeGen workflow)
make gen     # project.yml → regenerate VNB4Toeic.xcodeproj
make dev     # gen + simulator build
make test    # gen + XCTest/XCUITest
```

> `VNB4Toeic.xcodeproj` is **committed** (directly edited). `project.yml` is maintained in parallel as the XcodeGen source.

### Build & Deploy (Fastlane → TestFlight)
```bash
make build   # fastlane ios build (gym archive → .ipa)
make deploy  # fastlane ios beta (TestFlight upload)
```
> Signing via `match`/ASC API key injection — never commit `.p12`/provisioning profiles. Currently a stub.

## Implemented Features

### Core features (PRD §3-A)
| Feature | Location |
|---|---|
| Word learning card (image · IPA · Korean pron · example · TTS) | [LearnView.swift](App/Sources/Features/Learn/LearnView.swift) |
| Multinational TTS (US/GB/AU) | [Tts.swift](App/Sources/Features/Learn/Tts.swift) |
| Per-part word learning (LC Part1–4 / RC Part5–7) | HomeView grid + Repository |
| SRS review queue | HomeView review card |
| Weakness donut statistics | [ScoreDonut.swift](App/Sources/Features/Home/ScoreDonut.swift) |
| Sentence writing · shadowing (chips → check → 🔊) | [WriteView.swift](App/Sources/Features/Write/WriteView.swift) |
| Guest/login + Email auth | [AuthStore.swift](App/Sources/Core/AuthStore.swift) |
| Favorites/bookmarks persistence | [Persistence.swift](App/Sources/Core/Persistence.swift) |
| Guest SRS live progress (dueCount + due queue → LocalStore grade < 4) | [Repository.swift](App/Sources/Core/Repository.swift) + [Persistence.swift](App/Sources/Core/Persistence.swift) |
| Minor guardian-consent gate (PIPA §22-2) | [ConsentGate.swift](App/Sources/Core/ConsentGate.swift) |
| Accessibility (VoiceOver · Dynamic Type) | LearnView accessibilityLabel |
| iPad adaptive layout (2↔4 columns) | [HomeView.swift](App/Sources/Features/Home/HomeView.swift) |

### UX improvements (PRD §3-B, v0.3)
| Feature | Description | Location |
|---|---|---|
| Word-relevant images | loremflickr.com keyword images; backend `imageUrl` takes priority | LearnView.imageURL() |
| Bookmark collection view | Saved words + sentences list, swipe-to-delete | [BookmarksView.swift](App/Sources/Features/Learn/BookmarksView.swift) |
| Resume learning | Restores last index on re-entry (UserDefaults) | LocalStore.saveProgress / loadProgress |
| Swipe gesture navigation | DragGesture — left = next, right = previous | LearnView body |
| WriteView UX | 💡 hint panel (full sentence), ‹ prev button, 🏷 bookmark toggle, 4-button toolbar | WriteView.swift |

## Tests
```bash
make test
# per iteration: test/impl/<Nth>/scenario.md + result.md
```
Latest iteration 3: **PASS** (8 unit + 1 UI). → [3](test/impl/3/result.md) · [2](test/impl/2/result.md) · [1](test/impl/1/result.md)

## Troubleshooting (issues actually encountered)
| Symptom | Cause | Fix |
|---|---|---|
| `does not contain a scheme named "App"` | SPM-only package has no app scheme | Adopt XcodeGen (`make gen`) |
| `scheme ... iPhone 15` not found | Machine only has 17-series simulators | Set Makefile DEST to `iPhone 17 Pro` |
| `Tts.shared not concurrency-safe` | Swift 6 strict concurrency | Add `@MainActor` |
| test `Cannot code sign ... Info.plist` | Test targets had no generated plist | Add `GENERATE_INFOPLIST_FILE: YES` in project.yml |
| upload `CFBundleIconName missing (90713)` | No real icon PNG present | Add 1024 PNG + declare CFBundleIconName in info.properties |
| upload `no orientations (90474)` | UISupportedInterfaceOrientations absent | Add iPhone portrait + ~ipad 4-way in info.properties |
| `SentenceItem encode(to:) invalid redeclaration` | Swift synthesizes encode from CodingKeys — manual impl conflicts | Remove manual `encode(to:)` (synthesis is sufficient) |

## Next Steps (PRD remainder)
- Real **server integration** for login/signup (live `API_BASE_URL`) + `/users/me` boot restore.
- Live SRS grading (`/progress/grade`) and server analysis (`/me/analysis`).
- Finalize app-icon **design** — currently an auto-generated placeholder.
- a11y regression tests (Dynamic Type snapshots · VoiceOver audit).
- Re-verify a real TestFlight upload (EAS/Transporter).
