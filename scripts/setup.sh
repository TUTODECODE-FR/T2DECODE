#!/bin/bash

# Configuration
APP_NAME="T2DECODE"
MIN_FLUTTER_VERSION="3.0.0"

echo "--------------------------------------------------"
echo "🚀 Pre-flight Checks for $APP_NAME Development"
echo "--------------------------------------------------"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed. Please visit https://docs.flutter.dev/get-started/install"
    exit 1
else
    FLUTTER_VER=$(flutter --version | head -n 1)
    echo "✅ Flutter found: $FLUTTER_VER"
fi

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart is not installed."
    exit 1
else
    echo "✅ Dart found: $(dart --version 2>&1 | head -n 1)"
fi

# Check for Ollama (important for Ghost AI)
if ! command -v ollama &> /dev/null; then
    echo "⚠️ Warning: 'ollama' is missing. Ghost AI (local LLM) will not work without it."
    echo "   Download it at https://ollama.com/"
else
    echo "✅ Ollama found: $(ollama --version)"
fi

# Check for assets
if [ ! -f "assets/logo.png" ]; then
    echo "⚠️ Warning: 'assets/logo.png' is missing. Icons generation will fail."
fi

# Create necessary directories
if [ -L "build" ]; then
    TARGET=$(readlink "build")
    echo "ℹ️ 'build' is a symlink pointing to $TARGET. Recreating target directory..."
    mkdir -p "$TARGET"
else
    mkdir -p build
fi
mkdir -p assets/icons
mkdir -p assets/splash

echo "--------------------------------------------------"
echo "✨ Environment is ready for development!"
echo "Run 'make get' to install dependencies."
echo "--------------------------------------------------"
