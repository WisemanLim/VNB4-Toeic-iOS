# test/impl/5 — 결과

판정: **PASS** (2026-06-28)

## XCTest
```
AppTests    Executed 8 tests, with 0 failures (0 unexpected) in 0.012s
AppUITests  Executed 1 test,  with 0 failures (0 unexpected) in 3.208s
** TEST SUCCEEDED **
```

## 시나리오별 확인

| SC | 내용 | 결과 |
|---|---|---|
| SC-1 | 빌드 성공 | ✅ TEST SUCCEEDED |
| SC-2 | localDueCount — WordProgress 없음 → 0 | ✅ CoreData predicate `grade < 4`, empty → 0 |
| SC-3 | localDueCount — grade=4 제외, grade=1 포함 | ✅ predicate `grade < 4` 적용 |
| SC-4 | localDueWords — Seed 매핑 (wordId → Word) | ✅ Dictionary 매핑, compactMap 적용 |
| SC-5 | Repo.dueCount() 게스트 → LocalStore (서버 미호출) | ✅ `await !APIClient.shared.isAuthed()` 분기 |
| SC-6 | Repo.learnQueue("due") 게스트, 기록 없음 → Seed 폴백 | ✅ `words.isEmpty ? Seed.words.prefix(30)` |
| SC-7 | Repo.learnQueue("due") 게스트, grade<4 기록 있음 → LocalStore | ✅ localDueWords(limit:30) 반환 |
| SC-8 | XCTest 기존 회귀 | ✅ 8+1 tests, 0 failures |

## 비고
- 서버 mock(`/progress/stats`, `/progress/due`) 는 authed 경로에서만 사용; 게스트는 직접 CoreData 조회로 교체.
- WordProgress 없는 신규 사용자: Seed.prefix(30) 폴백으로 복습 큐 즉시 제공.
- 학습 진행 후: grade < 4(모름/알아가는 중)인 단어만 복습 큐에 올라옴.
