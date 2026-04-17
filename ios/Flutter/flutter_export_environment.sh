#!/bin/sh
# Checked-in fallback for CI/Xcode Cloud and sanitized local builds.
export "FLUTTER_ROOT=${SRCROOT}/../flutter"
export "FLUTTER_APPLICATION_PATH=${SRCROOT}/.."
export "COCOAPODS_PARALLEL_CODE_SIGN=true"
export "FLUTTER_TARGET=lib/main.dart"
export "FLUTTER_BUILD_DIR=build"
export "FLUTTER_BUILD_NAME=1.0.1"
export "FLUTTER_BUILD_NUMBER=25"
export "DART_DEFINES="
export "DART_OBFUSCATION=false"
export "TRACK_WIDGET_CREATION=false"
export "TREE_SHAKE_ICONS=true"
export "PACKAGE_CONFIG=.dart_tool/package_config.json"
