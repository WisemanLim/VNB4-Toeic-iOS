# test/impl/5 — 시나리오 (v0.4: 게스트 SRS 실 진도 연동)

대상: Persistence.swift (localDueCount/localDueWords), Repository.swift (dueCount/learnQueue guest path)

## SC-1: 빌드 성공
- When: `xcodebuild test -scheme App`
- Then: BUILD SUCCEEDED, 컴파일 error 0

## SC-2: localDueCount — 미학습 시 0
- Given: LocalStore (in-memory), WordProgress 없음
- When: store.localDueCount
- Then: 0

## SC-3: localDueCount — grade < 4인 항목만 카운트
- Given: recordGrade(wordId: "w1", grade: 1), recordGrade(wordId: "w2", grade: 4)
- When: store.localDueCount
- Then: 1 (w2는 grade=4로 제외)

## SC-4: localDueWords — Seed 매핑
- Given: recordGrade(wordId: {Seed.words[0].id}, grade: 2)
- When: store.localDueWords(limit: 30)
- Then: 해당 Word 반환

## SC-5: Repo.dueCount() — 게스트 경로 LocalStore 사용
- Given: APIClient.authed = false (게스트)
- When: await Repo.dueCount()
- Then: LocalStore.shared.localDueCount 반환 (서버 호출 없음)

## SC-6: Repo.learnQueue("due") — 게스트, 학습 기록 없음
- Given: APIClient.authed = false, WordProgress 없음
- When: await Repo.learnQueue("due")
- Then: Seed.words.prefix(30) 반환 (폴백)

## SC-7: Repo.learnQueue("due") — 게스트, 학습 기록 있음
- Given: APIClient.authed = false, grade < 4인 WordProgress 존재
- When: await Repo.learnQueue("due")
- Then: 해당 Word 목록 반환 (grade 오름차순)

## SC-8: XCTest 기존 회귀
- When: xcodebuild test
- Then: AppTests 8/0, AppUITests 1/0
