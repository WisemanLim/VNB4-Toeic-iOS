# dev-env 검증 시나리오 — ios-swiftui

표준 환경(Xcode/시뮬레이터/빌드)이 동작하는지 1회 검증. 모바일 기준(DB/compose 케이스 없음).

## 사전 (toolchain)
- [ ] `xcodebuild -version` → Xcode 16+ 출력
- [ ] `xcrun simctl list devices available` → iPhone 시뮬레이터 존재
- [ ] (선택) `fastlane --version`, `bundle install`

## 케이스
| # | 시나리오 | 명령 | 기대 결과 |
|---|---|---|---|
| 1 | SPM 의존성 해결 | Xcode 첫 실행 / `swift build` | 에러 없이 resolve |
| 2 | Debug 빌드 | `make dev` | iPhone 15 시뮬레이터 빌드 성공 |
| 3 | 시뮬레이터 부팅·실행 | Xcode ▶ (Cmd+R) | ContentView "Hello, VNB4Toeic (Debug)" 표시 |
| 4 | 코드 테스트 | `make test` | AppTests 통과 |
| 5 | flavor 주입 | Staging 스킴 빌드 | `Env.flavor == "Staging"` |

## 비고
- 폴더 경로 괄호 이슈(RN 앱 §7)와 무관 — 본 디렉터리는 괄호 없음.
- 실행 로그는 `logs/` 에 저장(비커밋).
