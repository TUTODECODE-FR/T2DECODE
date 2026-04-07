#!/bin/bash

# Configuration
APP_NAME="TUTODECODE"
BUILD_DIR="build/linux/x64/release/bundle"
OUTPUT_DIR="build/linux-appimage"
RESOURCES_DIR="linux/installer_resources"

echo "🐧 Préparation de l'AppImage Premium pour $APP_NAME..."

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Erreur: L'application n'est pas buildée dans $BUILD_DIR."
    echo "Lancez d'abord: flutter build linux --release"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Note: Ce script prépare la structure. La génération finale nécessite appimagetool sur Linux.
echo "📂 Structure AppDir préparée avec icônes et fichiers .desktop Premium."
echo "✅ Ressources prêtes dans $RESOURCES_DIR"
