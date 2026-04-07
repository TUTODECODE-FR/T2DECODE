#!/bin/bash

# Configuration
APP_NAME="TUTODECODE"
BUNDLE_ID="com.tutodecode.app"
APP_BUNDLE_NAME="TUTODECODE.app"
APP_VERSION="${APP_VERSION:-1.0.0}"
BUILD_DIR="build/macos/Build/Products/Release"
RESOURCES_DIR="macos/installer_resources"
COMPONENT_PKG="$BUILD_DIR/TUTODECODE_Component.pkg"
FINAL_PKG="$BUILD_DIR/TUTODECODE_Installer.pkg"

echo "🚀 Génération de l'installeur Premium macOS (.pkg) pour $APP_NAME..."

# 1. Vérifier si l'app est buildée
if [ ! -d "$BUILD_DIR/$APP_BUNDLE_NAME" ]; then
    echo "❌ Erreur: L'application n'est pas buildée dans $BUILD_DIR."
    echo "Lancez d'abord: flutter build macos --release"
    exit 1
fi

# 2. Créer le package composant (invisible)
echo "🏗 Création du composant de base..."
pkgbuild --component "$BUILD_DIR/$APP_BUNDLE_NAME" \
         --install-location "/Applications" \
         --identifier "$BUNDLE_ID" \
         --version "$APP_VERSION" \
         "$COMPONENT_PKG"

# 3. Créer le package produit (avec UI)
echo "💎 Assemblage de l'installeur avec UI (productbuild)..."
productbuild --distribution "$RESOURCES_DIR/distribution.xml" \
             --resources "$RESOURCES_DIR" \
             --package-path "$BUILD_DIR" \
             "$FINAL_PKG"

# 4. Nettoyage
rm "$COMPONENT_PKG"

echo "✅ Installeur Premium créé avec succès : $FINAL_PKG"
