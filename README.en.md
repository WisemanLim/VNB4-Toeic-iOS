# VNB4Toeic (iOS Native / Swift)

> 🌐 **Language**: [한국어](README.md) · **English**

Native iOS TOEIC vocabulary app (Swift + SwiftUI). A native port of the existing
React Native (Expo) app ([VNB4-Toeic-app](../../Apps-Mobile/VNB4-Toeic-app)).

- **App name** (home screen): Vocabulary Notebook for TOEIC · **App Store name**: TOEIC Vocabulary Notebook – VNB4 · **Bundle ID**: `com.vnb4.vocabnote`

> **Scaffold**: `wise-dev-standard` plugin / profile `ios-swiftui` / domain `edtech`.
> Docs: [PRD.md](PRD.md) · [COMPLIANCE.md](COMPLIANCE.md)

## Tech Stack
| Layer | Tool |
|------|------|
| Language | Swift 6 |
| UI | SwiftUI (iOS **16+**, iPhone+iPad) |
| Project generation | **XcodeGen** (`project.yml` → `.xcodeproj`) |
| Storage | Keychain (token) · bundled seed (offline) |
| Speech | AVSpeechSynthesizer (system TTS, US/GB/AU) |
| Chart | Hand-rolled donut (trimmed Circle, iOS16-safe) |
| Deploy | Fastlane → TestFlight |
| CI | GitHub Actions (macOS) |

## Architecture / Layout
```
App/Sources/
├── App.swift              # @main, injects AuthStore
├── ContentView.swift      # root gate (loading → Home)
├── Core/
│   ├── Models.swift       # Codable: Word/SentenceItem/Analysis/Lesson… (part coercion, lenient)
│   ├── Seed.swift         # bundled words.json/sentences.json loader
│   ├── APIClient.swift    # URLSession async + guest mock routing + token
│   ├── Mocks.swift        # seed-backed offline routing (/words,/sentences,/me/analysis…)
│   ├── Repository.swift   # data access (ported from RN queries.ts)
│   ├── AuthStore.swift    # session (guest/authed), login/signup/logout + minor-consent gate
│   ├── ConsentGate.swift  # guardian consent for under-14 (PIPA §22-2)
│   ├── Persistence.swift  # CoreData (programmatic) + LocalStore (favorites/progress)
│   ├── Keychain.swift     # token store
│   └── Theme.swift        # design tokens + part catalog
├── Features/
│   ├── Home/HomeView.swift, ScoreDonut.swift
│   ├── Learn/LearnView.swift, Tts.swift
│   ├── Write/WriteView.swift
│   └── Auth/LoginView.swift
App/Resources/             # words.json (3,686 words) · sentences.json (198 items) + Assets.xcassets (AppIcon/AccentColor) bundled
Config/                    # Debug/Staging/Release.xcconfig (API_BASE_URL, flavor)
AppTests/ · AppUITests/    # XCTest · XCUITest
test/                      # testing standard (dev-env, impl/<Nth>)
```

### Data-source switch (ported from RN)
- **Guest (not logged in)** → bundled seed + `Mocks`, fully **offline**.
- **Logged in** → real backend (`API_BASE_URL`/api/v1) syncs words/sentences/progress/analysis. `/auth/*` always hits the server.
- `USE_MOCK` (Info.plist) → everything mock, regardless of auth.

## Prerequisites
- macOS + **Xcode 16+**
- **XcodeGen** (`brew install xcodegen`) — required to generate the `.xcodeproj`
- (deploy) Ruby/Bundler + Fastlane, Apple Developer account

## Environment
flavor + `API_BASE_URL` + signing (no DB — mobile). Never commit real secrets/signing keys.

| Env | File | flavor | API base |
|---|---|---|---|
| local | [.env.local](.env.local) | Debug | http://localhost:4000 |
| dev | [.env.dev](.env.dev) | Debug | https://dev.api.example `assumed` |
| staging | [.env.staging](.env.staging) | Staging | https://stg.api.example `assumed` |
| prod | [.env.prod](.env.prod) | Release | (injected) |

`API_BASE_URL` flows `Config/*.xcconfig` → Info.plist → `Env.apiBase`. Replace xcconfig when the server URL is finalized.

## Run (Simulator)
```bash
make gen     # project.yml → VNB4Toeic.xcodeproj (regenerate when sources/config change)
make dev     # gen + build on iPhone 17 simulator
make test    # gen + XCTest/XCUITest
open VNB4Toeic.xcodeproj   # ▶ Cmd+R in Xcode

# other simulator
make dev DEST='platform=iOS Simulator,name=iPhone 17 Pro'
```
> The `.xcodeproj` is generated (gitignored). Commit only `project.yml`. Run `make gen` after cloning.

### Build & Deploy (Fastlane → TestFlight)
```bash
make build   # fastlane ios build (gym archive .ipa)
make deploy  # fastlane ios beta (TestFlight upload)
```
> Signing via `match`/ASC API key injection — never commit `.p12`/provisioning. Stub (not executed).

## Implemented features (PRD mapping)
| PRD feature | Status | Location |
|---|---|---|
| Word card (IPA/Korean pron/example/image) | ✅ | [LearnView.swift](App/Sources/Features/Learn/LearnView.swift) |
| Multinational TTS (US/GB/AU) | ✅ AVSpeechSynthesizer | [Tts.swift](App/Sources/Features/Learn/Tts.swift) |
| Per-part full-word learning | ✅ (seed part filter, paginated) | Repository/Mocks |
| SRS review queue | ✅ (guest = top-30 sample) | HomeView review card |
| Weakness donut stats | ✅ (guest = empty track + CTA) | [ScoreDonut.swift](App/Sources/Features/Home/ScoreDonut.swift) |
| Sentence writing · shadowing | ✅ (chips → sentence → check → 🔊) | [WriteView.swift](App/Sources/Features/Write/WriteView.swift) |
| Guest/login + Email auth | ✅ guest offline / login server | [AuthStore.swift](App/Sources/Core/AuthStore.swift) |
| Notes/favorites + progress | ✅ CoreData persistence | [Persistence.swift](App/Sources/Core/Persistence.swift) |
| Minor guardian-consent gate | ✅ blocks under-14 (PIPA §22-2) | [ConsentGate.swift](App/Sources/Core/ConsentGate.swift) |
| Accessibility (VoiceOver/Dynamic Type) | ✅ a11y labels + system fonts | LearnView |
| iPad adaptive layout | ✅ size class (2↔4 columns) | [HomeView.swift](App/Sources/Features/Home/HomeView.swift) |

## Tests
```bash
make test
# per iteration: test/impl/<Nth>/scenario.md + result.md
```
Latest iteration 3: **PASS** (8 unit + 1 UI, App Store validation errors fixed & verified). → [3](test/impl/3/result.md) · [2](test/impl/2/result.md) · [1](test/impl/1/result.md)

## Troubleshooting (issues actually hit)
| Symptom | Cause | Fix |
|---|---|---|
| `does not contain a scheme named "App"` | SPM-only package = no app scheme | adopt XcodeGen (project.yml), `make gen` |
| `scheme ... iPhone 15` missing | machine only has 17-series sims | Makefile DEST `iPhone 17` |
| `Tts.shared not concurrency-safe` | Swift 6 strict concurrency | `@MainActor` |
| test `Cannot code sign ... Info.plist` | test targets had no generated plist | project.yml `GENERATE_INFOPLIST_FILE: YES` |
| upload `CFBundleIconName missing (90713)` / icon 120·152 missing (90022/3) | no real icon PNG + asset-catalog partial plist not merged with xcodegen custom Info.plist | add 1024 PNG + declare CFBundleIconName/CFBundleIcons(~ipad) in info.properties |
| upload `no orientations (90474)` | UISupportedInterfaceOrientations absent | add iPhone portrait + ~ipad 4 orientations in info.properties |
| word image blank | offline, picsum unreachable | expected (placeholder); shows when online |

## Next steps (PRD remainder)
- Real **server integration** for login/signup (live API_BASE_URL) + `/users/me` boot restore.
- Live SRS grading (`/progress/grade`) and server analysis (`/me/analysis`).
- Wire guest dueCount to local progress (LocalStore) — currently a mock sample.
- Finalize app-icon **design** — currently an auto-generated placeholder (brand blue + "VNB4 TOEIC").
- a11y regression (Dynamic Type snapshots / accessibility audit) tests.
- Re-verify a real upload (EAS/Transporter) — currently confirmed only via the simulator build plist.
