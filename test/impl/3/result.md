# test/impl/3 — 결과

판정: **PASS** (2026-06-08)

## App Store 검증 오류 → 빌드 plist 검증
빌드 후 `App.app/Info.plist` 추출:
```
CFBundleIconName        = AppIcon                         # 90713 해소
CFBundleIcons           → CFBundleIconFiles[AppIcon60x60]  # iPhone 120px → 90022 해소
CFBundleIcons~ipad      → CFBundleIconFiles[AppIcon60x60, AppIcon76x76]  # iPad 152px → 90023 해소
UISupportedInterfaceOrientations        = [Portrait]                     # 90474 해소
UISupportedInterfaceOrientations~ipad   = [Portrait, PortraitUpsideDown, LandscapeLeft, LandscapeRight]
CFBundleIdentifier      = com.vnb4.toeic
CFBundleDisplayName     = Vocabulary Notebook for TOEIC
```
컴파일된 아이콘 PNG: `AppIcon60x60@2x.png`(120) · `AppIcon76x76@2x~ipad.png`(152).

## 기능 회귀
```
AppTests   Executed 8 tests, 0 failures
AppUITests Executed 1 test,  0 failures
** TEST SUCCEEDED **
```

## 비고
- 아이콘은 AppKit 스크립트(`/tmp/vnb4_icon.swift`)로 생성한 1024 PNG(브랜드 블루 + "VNB4 TOEIC") — 플레이스홀더 수준. 디자인 확정 시 교체.
- 핵심 원인: xcodegen + 커스텀 Info.plist 조합에서 에셋카탈로그 partial plist 병합이 누락되어
  CFBundleIconName/CFBundleIcons 가 빠짐 → info.properties 에 명시 선언으로 해결.
- 시뮬레이터 빌드 plist로 검증(실 업로드 재검증은 EAS/Transporter 필요).
