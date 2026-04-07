#!/bin/bash

# Configuration
APP_NAME="tutodecode"
APP_BUNDLE_NAME="tutodecode.app"
BUILD_DIR="build/macos/Build/Products/Release"
DMG_NAME="TUTODECODE.dmg"
DMG_STAGING_DIR="build/dmg_staging"

echo "🚀 Préparation de la génération du DMG pour $APP_NAME..."

# 1. Vérifier si l'app est buildée
if [ ! -d "$BUILD_DIR/$APP_BUNDLE_NAME" ]; then
    echo "❌ Erreur: L'application n'est pas buildée dans $BUILD_DIR."
    echo "Lancez d'abord: flutter build macos --release"
    exit 1
fi

# 2. Nettoyer l'espace de staging
echo "🧹 Nettoyage de l'espace de travail..."
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"
rm -f "$BUILD_DIR/$DMG_NAME"

# 3. Copier l'application
echo "📂 Copie de l'application..."
cp -R "$BUILD_DIR/$APP_BUNDLE_NAME" "$DMG_STAGING_DIR/"

# 4. Créer le lien vers Applications
echo "🔗 Création du lien vers /Applications..."
ln -s /Applications "$DMG_STAGING_DIR/Applications"

# 5. Créer le DMG
echo "💿 Création de l'image disque (.dmg)..."
hdiutil create -volname "TUTODECODE" -srcfolder "$DMG_STAGING_DIR" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

echo "✅ DMG créé avec succès : $BUILD_DIR/$DMG_NAME"

# 6. Nettoyage final
rm -rf "$DMG_STAGING_DIR"
