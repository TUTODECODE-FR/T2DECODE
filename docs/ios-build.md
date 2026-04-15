# iOS: creer et builder l'application

Ce guide explique comment **generer l'app iOS** (dev, device, IPA release).

Pour la CI (GitHub Actions) et la liste des secrets, voir `docs/signing.md`.

---

## Prerequis

- macOS + Xcode installe
- Flutter (stable)
- CocoaPods

Verification:

```bash
flutter doctor -v
xcodebuild -version
pod --version
```

---

## Lancer en dev (simulateur)

Le simulateur iOS ne necessite pas de certificat de signature.

```bash
open -a Simulator
flutter run -d ios
```

Si plusieurs simulateurs sont disponibles:

```bash
flutter devices
flutter run -d "iPhone 16"
```

---

## Lancer sur iPhone/iPad (device)

Si `flutter build ios --release` affiche:
"No valid code signing certificates were found"

C'est normal tant que Xcode n'a pas de team/certificat/provisioning.

### Etapes dans Xcode

1. Ouvrir le workspace:

```bash
open ios/Runner.xcworkspace
```

2. Selectionner:
- le projet `Runner`
- la target `Runner`

3. Dans `Signing & Capabilities`:
- choisir une **Team**
- verifier un **Bundle Identifier** unique (ex: `org.tutodecode.app`)
- activer "Automatically manage signing" (pour le dev)

4. Brancher l'iPhone/iPad et cliquer Run.

---

## Build iOS (archive / IPA)

### Option A: build iOS "classique" (sans IPA)

```bash
flutter build ios --release
```

Ce build necessite quand meme une signature valide pour un device.

### Option B: generer un `.ipa` (recommande pour distribution)

Il faut en general:
- certificat iOS
- provisioning profile
- `ExportOptions.plist`

Commande:

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Sortie attendue:
- `build/ios/ipa/*.ipa`

---

## Notes importantes (Apple)

- Pour distribuer proprement (TestFlight / App Store / IPA signable), il faut en general un compte **Apple Developer** actif.
- Sans abonnement, Xcode permet souvent un dev "limite" sur device (restrictions Apple, certificats temporaires).

---

## Depannage

### "No valid code signing certificates were found"

Actions:
- se connecter a son Apple ID dans Xcode (Settings / Accounts)
- choisir une Team dans `Signing & Capabilities`
- verifier Bundle ID unique
- relancer un build

### CocoaPods / pods cassés

Dans `ios/`:

```bash
rm -rf Pods Podfile.lock
pod repo update
pod install
```

