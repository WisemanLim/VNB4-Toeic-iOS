# test/impl/1 — 결과

판정: **PASS** (2026-06-08)

## 시험 실행
```
xcodebuild test -project VNB4Toeic.xcodeproj -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

```
Test Suite 'AppTests'   — Executed 6 tests, 0 failures
  ✓ testApiBaseHasDefault
  ✓ testEnvFlavorHasDefault
  ✓ testSentenceDecode
  ✓ testWordPartAsEnumString
  ✓ testWordPartAsNumber
  ✓ testWordRoundTrip
Test Suite 'AppUITests' — Executed 1 test, 0 failures
  ✓ testAppLaunches (3.32s)
** TEST SUCCEEDED **
```

## 수정·재시험 이력
1. `Tts.shared` Swift 6 동시성 오류(non-Sendable) → `@MainActor` 적용 → BUILD SUCCEEDED.
2. 테스트 타깃 Info.plist 미생성으로 코드사인 실패 → project.yml 테스트 타깃에
   `GENERATE_INFOPLIST_FILE: YES` 추가 → 재생성 → TEST SUCCEEDED.

## 비고
- 게스트 오프라인 경로(번들 시드 + Mocks)만 시험. 로그인/서버 동기화 경로는 실서버 필요 → 차기 차수.
- 단어카드 이미지(picsum)·예문은 오프라인 시 네트워크 미연결로 플레이스홀더 표시(크래시 없음).
