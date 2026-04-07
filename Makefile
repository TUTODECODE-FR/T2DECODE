# Makefile for TUTODECODE Development

FLUTTER = flutter
PUB = $(FLUTTER) pub

.PHONY: help setup get build-android build-ios build-macos build-windows build-linux build-all clean test

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup          Run environment checks and setup"
	@echo "  get            Install dependencies"
	@echo "  test           Run unit tests"
	@echo "  build-android  Build Android APK"
	@echo "  build-ios      Build iOS IPA (Requires macOS)"
	@echo "  build-macos    Build macOS App (Requires macOS)"
	@echo "  build-windows  Build Windows EXE (Requires Windows)"
	@echo "  build-linux    Build Linux Binary (Requires Linux)"
	@echo "  build-all      Build for all platforms (if supported by OS)"
	@echo "  clean          Remove build artifacts"

setup:
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

get:
	$(PUB) get

test:
	$(FLUTTER) test

build-android:
	$(FLUTTER) build apk --release

build-ios:
	$(FLUTTER) build ipa --release

build-macos:
	$(FLUTTER) build macos --release

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

build-windows:
	$(FLUTTER) build windows --release

build-linux:
	$(FLUTTER) build linux --release

build-all: build-android build-macos build-linux

clean:
	$(FLUTTER) clean
	rm -rf build/
