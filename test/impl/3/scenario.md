# test/impl/3 — 시나리오

차수 3: App Store 업로드 검증 오류 수정 (아이콘·오리엔테이션·번들ID·표시이름).

## 배경
TestFlight/App Store 업로드 시 검증 거부:
- 90713 CFBundleIconName 누락
- 90022 iPhone 120x120 아이콘 누락 / 90023 iPad 152x152 아이콘 누락
- 90474 UISupportedInterfaceOrientations 미지정(iPad 멀티태스킹)
- 앱 이름 → "Vocabulary Notebook for TOEIC", 패키지 → com.vnb4.toeic

## 수정
- 실 아이콘 1024 PNG 생성(AppKit 스크립트, 무의존) → `Assets.xcassets/AppIcon.appiconset/icon-1024.png`.
- project.yml info.properties: CFBundleIconName/CFBundleIcons(+~ipad), CFBundleDisplayName,
  UISupportedInterfaceOrientations(iPhone portrait)+~ipad(4방향). 번들ID com.vnb4.toeic, ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon.
- Keychain service·Appfile 주석 com.vnb4.toeic 정합.

## 케이스
| # | 시나리오 | 검증 | 결과 |
|---|---|---|---|
| 1 | 빌드 | `make dev` | BUILD SUCCEEDED |
| 2 | CFBundleIconName 존재 | 빌드 plist | "AppIcon" |
| 3 | iPhone 120 아이콘 컴파일 | 번들 | AppIcon60x60@2x.png |
| 4 | iPad 152 아이콘 컴파일 | 번들 | AppIcon76x76@2x~ipad.png |
| 5 | 오리엔테이션(iPhone/iPad) | 빌드 plist | portrait / 4방향 |
| 6 | 번들ID·표시이름 | 빌드 plist | com.vnb4.toeic · Vocabulary Notebook for TOEIC |
| 7 | 기능 회귀 | XCTest/XCUITest | (아래 result) |
