<meta name="fediverse:creator" content="@TUTODECODE@mastodon.social">

<div align="center">

<p><strong>Français</strong> · <a href="README_EN.md">English</a></p>

<a href="https://tutodecode.org"><img src="assets/TDC.png" width="128" height="128" alt="Logo T2DECODE"></a>

<h1>T2DECODE</h1>

<p>Application libre pour apprendre les réseaux, Linux et la cybersécurité.<br>
Fonctionne entièrement hors ligne, sans compte et sans collecte de données.</p>

<p>
<a href="https://github.com/TUTODECODE-FR/T2DECODE/releases/latest"><img src="https://img.shields.io/github/v/release/TUTODECODE-FR/T2DECODE?style=flat-square" alt="Dernière version"></a>
<a href="https://github.com/TUTODECODE-FR/T2DECODE/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/TUTODECODE-FR/T2DECODE/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
<a href="LICENSE"><img src="https://img.shields.io/github/license/TUTODECODE-FR/T2DECODE?style=flat-square" alt="Licence"></a>
<a href="https://f-droid.org/packages/org.t2decode.app/"><img src="https://img.shields.io/f-droid/v/org.t2decode.app?style=flat-square" alt="F-Droid"></a>
<a href="https://snapcraft.io/t2decode"><img src="https://img.shields.io/snapcraft/v/t2decode/latest/stable?style=flat-square" alt="Snap"></a>
<a href="https://securityscorecards.dev/viewer/?uri=github.com/TUTODECODE-FR/T2DECODE"><img src="https://api.securityscorecards.dev/projects/github.com/TUTODECODE-FR/T2DECODE/badge?style=flat-square" alt="OpenSSF Scorecard"></a>
</p>

<p><a href="https://tutodecode.org/telecharger/"><strong>Télécharger</strong></a> · <a href="https://tutodecode.org/t2decode/">Présentation</a> · <a href="https://tutodecode.org/etablissements/">Établissements</a> · <a href="#contribuer">Contribuer</a></p>

</div>

<p align="center"><img src="docs/images/screenshots/app-accueil.jpg" width="820" alt="T2DECODE : écran d'accueil"></p>

## Ce que fait T2DECODE

T2DECODE réunit dans une seule application de quoi apprendre et s'entraîner en informatique technique, y compris dans une salle sans accès à Internet.

| Module | Contenu |
| :--- | :--- |
| Cours | Réseaux, systèmes, Linux et sécurité, avec des cas réels et des questionnaires. |
| Simulations | Scan, ping, traceroute, attaques et défenses, préparation aux CTF. Données synthétiques : aucun scan réel n'est lancé. |
| Terminal Linux | Terminal d'entraînement pour pratiquer les commandes et bash sans toucher au système. |
| Outils | Calcul de sous-réseaux IPv4/IPv6, chmod, cron, vérification d'empreintes. |
| Cryptographie | AES, RSA et fonctions de hachage, pas à pas. |
| Assistant local | Optionnel : si [Ollama](https://ollama.com) est installé sur l'ordinateur, il répond à partir des cours. Rien ne sort de la machine. |
| Vos cours | Cours personnalisés au format `.tdc`, écrits avec [TDC Studio](https://github.com/TUTODECODE-FR/tdc-sdk). |

Pas de compte, pas de télémétrie, pas de publicité. Interface en français.

## Installer

Tous les liens, toujours à jour : **[tutodecode.org/telecharger](https://tutodecode.org/telecharger/)**

| Système | Où | Remarque |
| :--- | :--- | :--- |
| Windows 10/11 (64 bits) | [Installateur](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest/download/T2DECODE-Windows-Setup.exe) ou [version portable](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest/download/T2DECODE-Windows.zip) | Signé par TUTODECODE. « Installer pour moi seulement » ne demande pas de droits administrateur. |
| macOS 10.15+ | [Mac App Store](https://apps.apple.com/app/id6762523276) ou [image disque](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest/download/T2DECODE-macOS.dmg) | Image disque notarisée par Apple. |
| Linux (64 bits) | `sudo snap install t2decode` ou [archive .tar.gz](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest/download/T2DECODE-Linux.tar.gz) | Le Snap se met à jour tout seul. |
| Android | [Google Play](https://play.google.com/store/apps/details?id=org.tutodecode.t2decode), [F-Droid](https://f-droid.org/packages/org.t2decode.app/) ou [APK](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest) | |

Homebrew :

```bash
brew tap tutodecode-org/tap https://gitlab.com/tutodecode-org/homebrew-tap.git
brew install --cask t2decode
```

En établissement (installation silencieuse, postes sans Internet, sans droits administrateur) : voir **[tutodecode.org/etablissements](https://tutodecode.org/etablissements/)**.

## Vérifier les fichiers

Chaque version est compilée publiquement par GitHub Actions. Avec chaque [version publiée](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest) : `SHA256SUMS.txt` (empreintes) et nomenclatures logicielles (SBOM CycloneDX et SPDX).

```bash
shasum -a 256 T2DECODE-Linux.tar.gz              # macOS / Linux
Get-FileHash .\T2DECODE-Windows-Setup.exe        # Windows (PowerShell)
```

Sous Windows, l'onglet *Signatures numériques* des propriétés du fichier doit indiquer **TUTODECODE**.

## Contrôles automatiques

À chaque modification : tests unitaires et d'interface, `flutter analyze`, analyse des dépendances (OSV-Scanner) et analyse du code par CodeQL. À chaque version publiée, en plus : analyse de sécurité du code (Semgrep), recherche de secrets dans l'historique (Gitleaks) et analyse antivirus des fichiers produits (ClamAV). Les résultats sont visibles dans l'onglet [Actions](https://github.com/TUTODECODE-FR/T2DECODE/actions).

## Compiler depuis les sources

Prérequis : Flutter (version indiquée dans `.flutter-version`) et, selon le système, les outils de compilation natifs (Visual Studio 2022 avec C++ sous Windows, Xcode sous macOS, `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev` sous Debian/Ubuntu).

```bash
git clone https://github.com/TUTODECODE-FR/T2DECODE.git
cd T2DECODE
make setup && make get && make test
flutter run
```

Cibles de compilation : `make build-windows`, `make build-macos`, `make build-dmg`, `make build-linux`, `make build-android`.

## Contribuer

Signalements, idées et contributions sont bienvenus.

- Bug ou idée : [tickets GitHub](https://github.com/TUTODECODE-FR/T2DECODE/issues)
- Faille de sécurité : par e-mail, jamais en ticket public. Voir [SECURITY.md](SECURITY.md).
- Code et cours : [CONTRIBUTING.md](CONTRIBUTING.md) (commits signés `Signed-off-by`), [VOLUNTEER_BOARD.md](VOLUNTEER_BOARD.md), [MAINTAINERS.md](MAINTAINERS.md)
- Documentation technique : [architecture](docs/architecture.md), [cartographie OWASP MASVS](docs/masvs-mapping.md)

## Licence et éditeur

T2DECODE est un logiciel libre sous licence [GNU GPL v3](LICENSE).

Édité par l'association TUTODECODE (loi 1901, SIREN 102 763 133, RNA W134011896, Saint-Victoret), présidée par Maxime MARTIN CIVET. Site : [tutodecode.org](https://tutodecode.org) · Contact : [tutodecode.org/contact](https://tutodecode.org/contact/) · Mastodon : [@TUTODECODE](https://mastodon.social/@TUTODECODE)

Dépôt principal : GitHub. Miroirs : [GitLab](https://gitlab.com/tutodecode-org/T2DECODE), [SourceForge](https://sourceforge.net/projects/t2decode/).
