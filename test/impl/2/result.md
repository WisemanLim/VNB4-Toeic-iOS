# test/impl/2 — 결과

판정: **PASS** (2026-06-08)

## 시험 실행
```
xcodebuild test -project VNB4Toeic.xcodeproj -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

```
Test Suite 'AppTests'   — Executed 8 tests, 0 failures
  ✓ testApiBaseHasDefault          ✓ testEnvFlavorHasDefault
  ✓ testGuardianConsentGate (NEW)  ✓ testLocalStorePersistence (NEW)
  ✓ testSentenceDecode             ✓ testWordPartAsEnumString
  ✓ testWordPartAsNumber           ✓ testWordRoundTrip
Test Suite 'AppUITests' — Executed 1 test, 0 failures
  ✓ testAppLaunches (3.35s)
** TEST SUCCEEDED **
```

## 수정·재시험 이력
- 무오류 1패스 통과. (CoreData 프로그래매틱 모델 + in-memory 컨텍스트 주입으로 테스트 격리.)

## 비고
- GRDB 대신 **CoreData 프로그래매틱 모델** 채택 — SPM 네트워크 fetch 불필요(설치 승인 회피), iOS16 내장.
- 앱 아이콘: `AppIcon.appiconset` 자리만 생성(1024 PNG 미포함) → 빌드는 통과(아이콘 경고). 실 PNG 드롭 필요.
- a11y Dynamic Type/VoiceOver 자동 회귀 시험은 스냅샷/접근성 감사 도구 도입 시 차기 차수.
