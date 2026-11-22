#!/usr/bin/env bash
# ==============================================================================
# T2DECODE - FOSS & Air-Gapped Security Compliance Auditor
# © 2026 Association TUTODECODE (Maxime MARTIN CIVET)
# Licence : GNU General Public License v3.0
# ==============================================================================

set -euo pipefail

echo "=================================================================="
echo "🛡️  T2DECODE FOSS & AIR-GAPPED COMPLIANCE AUDIT"
echo "=================================================================="

ERRORS=0

# 1. Vérification des dépendances pubspec.yaml (Anti-Tracking & Anti-Cloud)
echo "🔍 [1/5] Audit des dépendances Dart/Flutter (Zéro télémétrie & Cloud)..."
BANNED_PACKAGES=(
    "firebase"
    "google_mobile_ads"
    "google_sign_in"
    "play_services"
    "in_app_purchase"
    "in_app_review"
    "amplitude"
    "mixpanel"
    "sentry"
    "facebook"
    "appsflyer"
    "adjust"
    "branch_io"
    "datadog"
    "newrelic"
    "crashlytics"
    "onesignal"
    "intercom"
    "telemetry"
)

for pkg in "${BANNED_PACKAGES[@]}"; do
    if grep -E "^[[:space:]]*${pkg}" pubspec.yaml >/dev/null 2>&1; then
        echo "❌ ERREUR : Package propriétaire/tracking interdit détecté dans pubspec.yaml : $pkg"
        ERRORS=$((ERRORS + 1))
    fi
done

# 2. Vérification Android & F-Droid Rules
echo "🔍 [2/5] Audit de conformité Android F-Droid (ProGuard & Play Core Exclusion)..."

if [ ! -f "android/app/proguard-rules.pro" ]; then
    echo "❌ ERREUR : Le fichier android/app/proguard-rules.pro est manquant !"
    ERRORS=$((ERRORS + 1))
else
    if ! grep -q "com.google.android.play" android/app/proguard-rules.pro; then
        echo "❌ ERREUR : Règle -dontwarn com.google.android.play manquante dans proguard-rules.pro"
        ERRORS=$((ERRORS + 1))
    fi
fi

if ! grep -q 'exclude(group = "com.google.android.play")' android/app/build.gradle.kts; then
    echo "❌ ERREUR : Exclusion de com.google.android.play manquante dans android/app/build.gradle.kts"
    ERRORS=$((ERRORS + 1))
fi

if ! grep -q 'exclude(group = "com.google.android.play")' android/build.gradle.kts; then
    echo "❌ ERREUR : Exclusion de com.google.android.play manquante dans android/build.gradle.kts"
    ERRORS=$((ERRORS + 1))
fi

# 3. Permissions Android sensibles
echo "🔍 [3/5] Audit des permissions Android (Air-Gapped & Minimal Privilege)..."
BANNED_PERMISSIONS=(
    "android.permission.ACCESS_FINE_LOCATION"
    "android.permission.ACCESS_COARSE_LOCATION"
    "android.permission.READ_CONTACTS"
    "android.permission.WRITE_CONTACTS"
    "android.permission.RECORD_AUDIO"
    "android.permission.CAMERA"
    "android.permission.READ_SMS"
    "android.permission.RECEIVE_SMS"
    "android.permission.READ_PHONE_STATE"
)

for perm in "${BANNED_PERMISSIONS[@]}"; do
    if grep -q "$perm" android/app/src/main/AndroidManifest.xml 2>/dev/null; then
        echo "❌ ERREUR : Permission intrusive interdite dans AndroidManifest.xml : $perm"
        ERRORS=$((ERRORS + 1))
    fi
done

# 4. Vérification du Copyright 2026 Association TUTODECODE
echo "🔍 [4/5] Audit des mentions légales et droits d'auteur (2026 Association TUTODECODE)..."
if grep -q "© 2024-2026" README.md 2>/dev/null; then
    echo "⚠️ AVERTISSEMENT : Mention 2024-2026 obsolète trouvée dans README.md"
fi

# 5. Contrôle d'intégrité des checksums d'assets
echo "🔍 [5/5] Audit d'intégrité des assets et sécurité anti-altération..."
if [ ! -f "assets/asset_checksums.json" ]; then
    echo "❌ ERREUR : Le fichier de sommes de contrôle assets/asset_checksums.json est manquant !"
    ERRORS=$((ERRORS + 1))
fi

echo "=================================================================="
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ SUCCÈS : Tous les contrôles de conformité FOSS & Sécurité sont VALIDÉS !"
    echo "=================================================================="
    exit 0
else
    echo "❌ ÉCHEC : $ERRORS infraction(s) de conformité FOSS détectée(s)."
    echo "=================================================================="
    exit 1
fi
