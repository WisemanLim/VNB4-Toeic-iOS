# VNB4Toeic — ios-swiftui (XcodeGen 기반 / project.yml → .xcodeproj)
.PHONY: gen dev test build deploy
PROJECT ?= VNB4Toeic.xcodeproj
SCHEME ?= App
DEST ?= 'platform=iOS Simulator,name=iPhone 17'
gen:    ; xcodegen generate                                              # project.yml → .xcodeproj
dev:    gen; xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination $(DEST) build
test:   gen; xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination $(DEST)
build:  ; cd fastlane && fastlane ios build
deploy: ; cd fastlane && fastlane ios beta   # TestFlight
