# test/impl/1 — 시나리오

차수 1: Core 레이어 + 오프라인 Home·Learn·Write 수직 슬라이스 (RN 소스 이식).

## 범위
- Core: Models(Codable, part 코어션·lenient), Seed 로더, APIClient(게스트 mock 라우팅), Mocks, Repository, AuthStore, Keychain.
- UI: HomeView(인증바·취약유형 도넛·복습카드·LC/RC 그리드·문장쓰기 섹션), LearnView(단어카드·TTS·툴바·즐겨찾기), WriteView(문장쓰기·쉐도잉), LoginView, ScoreDonut, Tts.

## 케이스
| # | 시나리오 | 검증 | 결과 |
|---|---|---|---|
| 1 | 앱 빌드 | `make dev` (iPhone 17) | BUILD SUCCEEDED |
| 2 | 모델 디코딩: part=Int | Word part 1 | unit testWordPartAsNumber |
| 3 | 모델 디코딩: part="P3"→3 + pos free-form + audio bcp47 | Word | unit testWordPartAsEnumString |
| 4 | audio 누락 → [] / nullish optional | Word | unit testWordPartAsNumber |
| 5 | SentenceItem(order, tokens) 디코딩 | Sentence | unit testSentenceDecode |
| 6 | Word encode→decode 라운드트립(Mocks 재인코딩) | Word | unit testWordRoundTrip |
| 7 | 앱 부팅 → 게스트 Home 렌더 | 화면 staticText 존재 | UI testAppLaunches |
| 8 | Env flavor/apiBase 기본값 주입 | Info.plist(xcconfig) | unit testEnv* |

## 도메인(edtech) 추가 시험 — 이번 차수 적용 여부
- 만14세 미만 보호자 동의 차단: **미적용(deferred)** — 미성년 가입 플로우 미구현(성인 대상, PRD 가정). 회원가입 서버 연동 차수에서 추가.
- 미성년 PII 비프로드 마스킹: 해당 데이터 없음(오프라인 시드=공개 단어). N/A.
- 접근성(VoiceOver/Dynamic Type): 차기 차수 a11y 케이스로 예정.
