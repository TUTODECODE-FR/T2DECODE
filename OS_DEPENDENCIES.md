# Prérequis Système (OS Dependencies)

Avant de lancer `make setup` ou `flutter run`, vous devez vous assurer que votre système d'exploitation dispose des dépendances natives requises pour compiler l'application T2DECODE, particulièrement pour les versions Desktop (Linux, macOS, Windows).

## 🐧 Linux (Debian / Ubuntu)

Pour compiler l'application sous Linux, installez les paquets suivants :

```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  git \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev
```

## 🍏 macOS

Pour compiler l'application sous macOS (et iOS), vous avez besoin des outils de développement Apple et de CocoaPods :

```bash
# Installer les outils en ligne de commande Xcode
xcode-select --install

# Installer CocoaPods (gestionnaire de dépendances pour les plugins macOS/iOS)
sudo gem install cocoapods
# ou via Homebrew : brew install cocoapods
```
*(Remarque : L'application complète Xcode depuis le Mac App Store est recommandée pour les builds de production).*

## 🪟 Windows

Pour compiler l'application sous Windows, installez les outils suivants :

1. **Git pour Windows** : [Télécharger Git](https://git-scm.com/download/win)
2. **Visual Studio 2022** (pas VS Code, bien Visual Studio) : [Télécharger Visual Studio](https://visualstudio.microsoft.com/fr/downloads/)
   - Lors de l'installation, cochez impérativement la charge de travail : **"Développement Desktop en C++"** (Desktop development with C++).

---

## 🛠️ Dépendances Globales

Quelle que soit votre plateforme, vous aurez besoin de :

1. **Flutter SDK** (version 3.0.0 ou supérieure) : [Guide d'installation Flutter](https://docs.flutter.dev/get-started/install)
2. **Ollama** (Recommandé pour l'IA locale Ghost AI) : [Télécharger Ollama](https://ollama.com)

Une fois ces dépendances installées, vous pouvez retourner sur le `README.md` et exécuter `make setup` !
