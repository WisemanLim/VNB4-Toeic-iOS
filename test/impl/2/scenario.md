# test/impl/2 — 시나리오

차수 2: 영속화 + edtech 규제 게이트 + a11y + iPad 적응형.

## 범위
- 영속화: 프로그래매틱 CoreData(`Persistence`) + `LocalStore`(즐겨찾기·진도). 의존성 0(GRDB SPM fetch 회피).
- 규제: `ConsentGate` 만14세 미만 보호자 동의 게이트 → `AuthStore.signup` 적용, LoginView 출생연도·동의 UI.
- a11y: LearnView 아이콘 버튼(🔊/‹/›/🗑/🏷)에 accessibilityLabel + tts-word identifier. Dynamic Type=시스템 폰트.
- iPad 적응형: HomeView 그리드 horizontalSizeClass(regular=4열, compact=2열). 런치=UILaunchScreen, AppIcon/AccentColor 에셋.

## 케이스
| # | 시나리오 | 검증 | 결과 |
|---|---|---|---|
| 1 | 빌드(에셋·CoreData 포함) | `make dev` | BUILD SUCCEEDED |
| 2 | 즐겨찾기 toggle 영속(in-memory CoreData) | LocalStore | unit testLocalStorePersistence |
| 3 | 진도 grade upsert + learnedCount | LocalStore | 동일 |
| 4 | **만14세 미만 가입 차단**(보호자 동의 없으면) | ConsentGate | unit testGuardianConsentGate |
| 5 | 성인/미입력 비차단 + 14세 경계 | ConsentGate | 동일 |
| 6 | 앱 부팅 → Home 렌더(회귀) | UI | testAppLaunches |

## 도메인(edtech) testing_additions
- ✅ "만14세 미만 가입 시 보호자 동의 없으면 차단" — ConsentGate + AuthStore.signup 적용·시험.
- 미성년 PII 비프로드 마스킹: 데이터 없음(시드=공개 단어). N/A.
- a11y(KWCAG/WCAG): VoiceOver 라벨 적용. Dynamic Type 자동 스케일(시스템 폰트). 자동 시험은 차기 스냅샷 도입 시.
