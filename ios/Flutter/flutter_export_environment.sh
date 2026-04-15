#!/bin/sh
set -e

# Checked-in fallback for CI/Xcode Cloud.
# Local and CI builds may overwrite this file via: `flutter build ios --config-only`.

export "FLUTTER_APPLICATION_PATH=${SRCROOT}/.."
export "FLUTTER_ROOT=${SRCROOT}/../flutter"
export "COCOAPODS_PARALLEL_CODE_SIGN=true"
export "FLUTTER_TARGET=lib/main.dart"
export "FLUTTER_BUILD_DIR=build"
export "FLUTTER_BUILD_NAME=1.0.1"
export "FLUTTER_BUILD_NUMBER=1"
export "DART_OBFUSCATION=false"
export "TRACK_WIDGET_CREATION=true"
export "TREE_SHAKE_ICONS=false"
export "PACKAGE_CONFIG=.dart_tool/package_config.json"
