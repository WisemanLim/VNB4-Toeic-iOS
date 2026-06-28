# dev-env 검증 결과 — ios-swiftui

판정: **PASS** (2026-06-08)

| # | 케이스 | 명령 | 결과 |
|---|---|---|---|
| 1 | toolchain | `xcodebuild -version` / `xcrun simctl list` | Xcode 16+, iPhone 17 시뮬레이터 가용 |
| 2 | 프로젝트 생성 | `xcodegen generate` | VNB4Toeic.xcodeproj 생성 |
| 3 | Debug 빌드 | `make dev` (iPhone 17) | **BUILD SUCCEEDED** |
| 4 | flavor 주입 | Env.flavor / Env.apiBase | Info.plist(xcconfig) 주입 동작 |

비고:
- 정적 템플릿 기본은 SPM-only(앱 스킴 없음) + iOS17. → XcodeGen `project.yml` 도입,
  iOS 16 타겟, `App` application 스킴으로 전환(README 트러블슈팅 참고).
- 기본 시뮬레이터 `iPhone 15` → 이 머신엔 17-series만 존재 → Makefile DEST `iPhone 17`.
