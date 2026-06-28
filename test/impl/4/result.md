# test/impl/4 — 결과

판정: **PASS** (2026-06-28)

## 빌드
```
** BUILD SUCCEEDED **
```

## XCTest 회귀
```
AppTests    Executed 8 tests, with 0 failures (0 unexpected) in 0.015s
AppUITests  Executed 1 test,  with 0 failures (0 unexpected) in 3.604s
** TEST SUCCEEDED **
```

## 시나리오별 확인

| SC | 내용 | 결과 |
|---|---|---|
| SC-1 | 빌드 성공 | ✅ BUILD SUCCEEDED |
| SC-2 | loremflickr URL 생성 (`imageUrl` nil → `loremflickr.com/640/420/{slug}`, imageUrl 있으면 우선) | ✅ 코드 확인 |
| SC-3 | DragGesture 좌우 스와이프 — idx 전진/후퇴, saveProgress 호출 | ✅ 코드 확인 |
| SC-4 | load() 후 loadProgress(lessonId:) 복원 → idx | ✅ 코드 확인 |
| SC-5 | 완료 화면 "다시 시작" → idx=0, saveProgress(idx:0) | ✅ 코드 확인 |
| SC-6 | toggleFavorite(Word) — bookmarkedWords 업데이트, UserDefaults 저장 | ✅ testLocalStorePersistence PASS |
| SC-7 | Route.bookmarks, bookmarksCard, BookmarksView 진입 | ✅ 코드 확인 + UI 테스트 PASS |
| SC-8 | WriteView: 이전/힌트/북마크 버튼, showHint 토글, goPrev() | ✅ 코드 확인 |
| SC-9 | UserDefaults bm_words/bm_sentences/learn_progress JSON 저장 | ✅ 코드 확인 |
| SC-10 | XCTest 기존 회귀 | ✅ 8+1 tests, 0 failures |

## 수정 사항 (테스트 중 발견)
1. **project.pbxproj 직접 편집 → XcodeGen 재생성**: 수동 UUID 삽입으로 PRODUCT_NAME이 "VNB4Toeic"으로 변경 → TEST_HOST("App.app/App") 불일치. `xcodegen generate`로 재생성 → App target 정상화.
2. **AppTests.swift `toggleFavorite` 타입 수정**: `String` → `Word` (JSON decode 생성). testLocalStorePersistence PASS.
3. **SentenceItem encode(to:)**: Swift 합성으로 충분 — 수동 구현 제거로 redeclaration 오류 해소.

## 비고
- XcodeGen 기반 `.xcodeproj` 재생성이 수동 편집보다 안정적. `project.yml`에 source glob(`App/Sources`) 설정으로 신규 파일 자동 포함.
- RN 앱(VNB4-Toeic-app) 동일 기능: test/impl/1 별도 기록.
