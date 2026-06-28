# test/ — 시험 표준 (test-runner standard)

`wise-dev-standard` 시험 표준 증빙 디렉터리. Xcode 코드 테스트(`AppTests/`·`AppUITests/`)와 **별개**로,
시나리오·실행결과·로그를 남긴다.

```
test/
├── README.md          # 이 문서
├── dev-env/           # 표준 환경 검증 (1회)
│   ├── scenario.md
│   └── logs/          # 원본 로그 (비커밋)
└── impl/<Nth>/        # 구현 차수별 (implement 가 생성)
```

## 사이클
시나리오 작성 → 빌드·실행 → 오류 시 수정·재시험 → 결과 작성
(scenario → build & run → fix & retest → result)

## 러너
- 코드 테스트: **XCTest** (`AppTests/`) + **XCUITest** (`AppUITests/`)
- 실행: `make test` (`xcodebuild test -scheme App -destination 'platform=iOS Simulator,name=iPhone 15'`)

`test/impl/` 는 비어 있음 — `/wise-dev-standard:implement` 가 구현마다 `<Nth>/` 생성.
