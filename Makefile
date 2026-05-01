# Makefile for T2DECODE Development

FLUTTER = flutter
PUB = $(FLUTTER) pub
PUBSTAMP = .dart_tool/package_config.json

DART_DEFINES =
ifeq ($(TUTODECODE_OFFICIAL_BUILD),true)
	DART_DEFINES = --dart-define=OFFICIAL_BUILD=true
endif

.PHONY: help setup get build-android build-android-fdroid build-ios build-macos build-windows build-linux build-all clean clean-macos test

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup          Run environment checks and setup"
	@echo "  get            Install dependencies"
	@echo "  test           Run unit tests"
	@echo "  build-android  Build Android APK"
	@echo "  build-android-fdroid  Build Android APK (F-Droid mode)"
	@echo "  build-ios      Build iOS IPA (Requires macOS)"
	@echo "  build-macos    Build macOS App (Requires macOS)"
	@echo "  build-windows  Build Windows EXE (Requires Windows)"
	@echo "  build-linux    Build Linux Binary (Requires Linux)"
	@echo "  build-all      Build for all platforms (if supported by OS)"
	@echo "  clean          Remove build artifacts"
	@echo "  clean-macos    Deep clean macOS (Pods/ephemeral)"

setup:
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

$(PUBSTAMP): pubspec.yaml pubspec.lock
	@echo "→ Dépendances Dart/Flutter (pub get)…"
	@tmp=$$(mktemp); $(PUB) get >"$$tmp" 2>&1 || (cat "$$tmp"; rm -f "$$tmp"; exit 1); rm -f "$$tmp"
	@test -f $(PUBSTAMP)

get: $(PUBSTAMP)

test: $(PUBSTAMP)
	$(FLUTTER) test --no-pub

build-android: $(PUBSTAMP)
	$(FLUTTER) build apk --release $(DART_DEFINES) --no-pub

build-android-fdroid: $(PUBSTAMP)
	FDROID_BUILD=true $(FLUTTER) build apk --release $(DART_DEFINES) --no-tree-shake-icons --no-pub

build-ios: $(PUBSTAMP)
	$(FLUTTER) build ipa --release $(DART_DEFINES) --no-pub

build-macos: $(PUBSTAMP)
	@chmod +x scripts/build_macos_local.sh
	@SKIP_PUB_GET=1 ./scripts/build_macos_local.sh

build-dmg: build-macos
	@chmod +x scripts/build_dmg.sh
	@./scripts/build_dmg.sh

build-pkg: build-macos
	@chmod +x scripts/build_pkg.sh
	@./scripts/build_pkg.sh

build-windows-installer:
	@echo "🪟 Pour Windows, lancez Inno Setup sur windows/installer/tutodecode.iss après le build."

build-linux-appimage: build-linux
	@chmod +x scripts/build_linux_appimage.sh
	@./scripts/build_linux_appimage.sh

build-windows: $(PUBSTAMP)
	$(FLUTTER) build windows --release $(DART_DEFINES) --no-pub

build-linux: $(PUBSTAMP)
	$(FLUTTER) build linux --release $(DART_DEFINES) --no-pub

build-all: build-android build-macos build-linux

clean:
	$(FLUTTER) clean
	rm -rf build/

clean-macos: clean
	rm -rf macos/Pods macos/Podfile.lock macos/Flutter/ephemeral
