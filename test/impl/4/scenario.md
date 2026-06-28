# test/impl/4 — 시나리오 (VNB4-Toeic-iOS, v0.3 UX 개선 5종)

대상 커밋: a293d81 (UX 5종), efbf988 (docs), 1798807 (README)
빌드 대상: `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

## SC-1: 빌드 성공
- Given: 소스 변경 후 clean build
- When: `xcodebuild build`
- Then: `** BUILD SUCCEEDED **`, 컴파일 error 0

## SC-2: 단어 관련 이미지 (loremflickr)
- Given: LearnView.imageURL() 호출, word.imageUrl = nil
- When: slug = "abandon"
- Then: URL = `https://loremflickr.com/640/420/abandon`
- Given: word.imageUrl = "https://example.com/img.jpg"
- Then: 해당 URL 그대로 반환 (loremflickr 미적용)

## SC-3: 좌우 스와이프 제스처
- Given: LearnView, words 2개 이상, idx = 0
- When: 왼쪽 스와이프 (dx < 0, |dx| > |dy|)
- Then: advance() 호출 → idx = 1, saveProgress 호출
- When: 오른쪽 스와이프 (dx > 0), idx = 1
- Then: idx = 0, saveProgress 호출
- When: idx = 0, 오른쪽 스와이프
- Then: idx 변경 없음

## SC-4: 이어 학습하기 (진도 복원)
- Given: LocalStore.saveProgress(lessonId: "part-1", idx: 5) 호출
- When: LearnView.load() 완료 (words.count > 5)
- Then: idx = 5 (저장된 진도)
- Given: 저장 진도 없음
- Then: idx = 0

## SC-5: 다시 시작 버튼
- Given: LearnView, idx >= words.count (완료 상태)
- When: "다시 시작" 버튼 탭
- Then: idx = 0, reveal = false, saveProgress(idx: 0) 호출

## SC-6: 단어 즐겨찾기 (toggleFavorite 전달 타입)
- Given: 툴바 즐겨찾기 버튼 탭
- Then: store.toggleFavorite(cur) 호출 — Word 객체 전달 (String 아님)
- Then: bookmarkedWords 업데이트, UserDefaults "bm_words" 저장

## SC-7: 북마크 모아보기 화면
- Given: HomeView 렌더
- Then: Route.bookmarks 케이스 존재, bookmarksCard 표시
- Given: bookmarksCard 탭
- Then: BookmarksView 진입
- Given: BookmarksView, store.bookmarkedWords 비어있음
- Then: "북마크한 단어가 없습니다." 표시
- Given: bookmarkedSentences 1건
- Then: SentenceBookmarkRow 1개 표시

## SC-8: WriteView 힌트·이전·북마크
- Given: WriteView item 2개 이상, idx = 1
- When: "‹ 이전" 탭
- Then: idx = 0, picked = [], checked = false, showHint = false
- Given: idx = 0, "‹ 이전" 비활성
- Then: 탭 불가(disabled)
- Given: showHint = false, "💡 힌트" 탭
- Then: showHint = true, fullSentence 노란박스 표시
- Given: "🏷" 탭
- Then: store.toggleSentenceFavorite(item) 호출, "🔖" 전환
- Given: checked = false, "확인" 탭
- Then: checked = true, Tts.speak 호출
- Given: checked = true, "다음 →" 탭
- Then: idx += 1, checked = false, showHint = false

## SC-9: LocalStore UserDefaults 영속화
- Given: toggleSentenceFavorite 호출
- Then: UserDefaults "bm_sentences" 에 JSON 저장
- Given: saveProgress(lessonId: "L1", idx: 3) 호출
- Then: UserDefaults "learn_progress" = {"L1": 3}
- Given: 두 번째 saveProgress(lessonId: "L1", idx: 7) 호출
- Then: UserDefaults "learn_progress" = {"L1": 7} (덮어쓰기)

## SC-10: XCTest 기존 회귀
- When: `xcodebuild test -scheme App`
- Then: AppTests 기존 테스트 0 failures
