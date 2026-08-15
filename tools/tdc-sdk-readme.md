<div align="center">
  <a href="https://tutodecode.org">
    <img src="https://gitlab.com/tutodecode-org/T2DECODE/-/raw/main/assets/TDC.png" width="140" height="140" alt="Logo TDC SDK">
  </a>

  <h1>TDC SDK & Studio</h1>
  <p><strong>Suite d'outils de développement, IDE dédié et compilateur CLI pour le langage TUTODECODE Script (.tdc).</strong><br>
  <em>Open Source · Multi-Plateforme (macOS, Windows, Linux) · 100% Souverain · Licence GPLv3</em></p>

  <p align="center">
    <img src="https://img.shields.io/badge/TDC_Language-v1.0-F5EBDA?style=flat-square" alt="TDC Language v1.0">
    <img src="https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux-blue?style=flat-square" alt="Multiplatform">
    <img src="https://img.shields.io/badge/VS_Code_Extension-Available-green?style=flat-square" alt="VS Code Extension">
    <img src="https://img.shields.io/badge/License-GPLv3-gold?style=flat-square" alt="License GPLv3">
  </p>

  <p>
    <a href="#1-option-1--tdc-studio-desktop-ide-dédié">TDC Studio Desktop</a> · 
    <a href="#2-option-2--tdc-cli-outil-terminal--compilateur">CLI Terminal</a> · 
    <a href="#3-option-3--extension-vs-code">Extension VS Code</a> · 
    <a href="#4-spécification-du-langage-tdc">Spécification .TDC</a>
  </p>
</div>

---

## 🚀 Présentation de la Suite TDC SDK

Le **TDC SDK** fournit tous les outils nécessaires aux enseignants, développeurs, ingénieurs et IA pour créer, valider, formater et compiler des cours et QCMs au format **TUTODECODE Script (`.tdc`)**.

Il propose **3 méthodes d'utilisation** selon vos préférences :

1. **🎨 TDC Studio Desktop** : IDE complet autonome (macOS, Windows, Linux) avec coloration syntaxique, correction d'erreurs en direct et aperçu en temps réel.
2. **⚙️ CLI Terminal (`tdc-cli`)** : Outil en ligne de commande ultra-rapide pour auditer (`check`), formater (`fmt`) et convertir (`json2tdc`) des fichiers `.tdc` depuis n'importe quel terminal.
3. **💻 Extension VS Code (`vscode-tdc`)** : Support de langage natif pour VS Code et VSCodium (coloration TextMate, autocomplétion, snippets).

---

## 1. Option 1 : TDC Studio Desktop (IDE Dédié)

**TDC Studio** est une application bureau dédiée à la création de cours `.tdc`. 

### 🌟 Fonctionnalités Principales :
- **Éditeur Bi-Mode** : Alterne entre le mode **Formulaire Guidé** (saisie intuitive par cartes colorées) et le mode **Code `.TDC` Brut**.
- **Correction d'erreurs en direct** : Détection des erreurs de syntaxe à la volée avec localisation précise.
- **Aperçu Live (Live Preview)** : Rendu instantané du cours avec le Markdown formaté et les cartes interactives.
- **Modèles de Cours Prêts à l'Emploi** : Chargez en 1 clic des squelettes de cours (Linux Sysadmin, Réseau IPv4/CIDR, Sécurité).
- **Export 1-Clic** : Exportation directe vers le presse-papier ou sous forme de fichier `.tdc`.

### 📦 Installation Desktop :
- **macOS** : Téléchargez `TDC-Studio-macOS.dmg` ou via Homebrew.
- **Linux** : Téléchargez le paquet Snap / AppImage `tdc-studio`.
- **Windows** : Téléchargez l’exécutable `TDC-Studio-Windows.exe`.

---

## 2. Option 2 : TDC CLI (Outil Terminal & Compilateur)

Si vous utilisez votre propre éditeur de texte (Neovim, Sublime Text, Notepad++, Emacs) ou souhaitez automatiser la validation dans une intégration continue (CI/CD), utilisez **`tdc-cli`**.

### 🛠️ Commandes CLI Principales :

#### 🔍 Auditer & Valider un fichier `.tdc` :
```bash
python3 tdc_cli.py check mon_cours.tdc
```
*Sortie :*
```
🔍 Audit de syntaxe .TDC : mon_cours.tdc
  ✅ Valide ! Contient 1 cours, 3 modules, 4 QCMs (4 réponses correctes marquées +).
```

#### 🔄 Convertir un ancien cours JSON vers `.tdc` :
```bash
python3 tdc_cli.py json2tdc cours_legacy.json -o cours.tdc
```

#### ⚙️ Installation CLI via Pip / Script :
```bash
pip install tdc-sdk
# ou exécuter directement
python3 tools/tdc_cli.py --help
```

---

## 3. Option 3 : Extension VS Code (`vscode-tdc`)

Si vous développez principalement sous **Visual Studio Code** ou **VSCodium** :

1. Ouvrez VS Code.
2. Déplacez le dossier `tools/vscode-tdc/` dans votre répertoire d'extensions VS Code (`~/.vscode/extensions/`).
3. Profitez de :
   - **Coloration Syntaxique Native** (Mots-clés en crème, bonnes réponses QCM `+` en vert, leurres `-` en rouge).
   - **Snippets d'Autocomplétion** (Tapez `course`, `module` ou `question` puis presser `Tab`).
   - **Auto-fermeture des guillemets triple `"""` et accolades `{}`**.

---

## 4. Spécification du Langage `.TDC`

```tdc
course "linux-basics" {
  title: "Linux : Le Pouvoir du Terminal"
  description: "Maîtrisez le système qui fait tourner 96% des serveurs."
  category: linux
  level: beginner
  duration: 6h
  icon: Terminal
  keywords: [linux, bash, terminal, sysadmin]

  module "intro" {
    title: "Architecture et Commandes Essentielles"
    duration: 15min

    content """
    # 🚨 Incident de Prod #01 : Diagnostic d'Urgence à 3h du Matin
    Vous êtes connecté en SSH sur un serveur de production.
    """

    codeblock "bash" {
      title: "Kit d'audit immédiat"
      code """
      whoami       # Quel utilisateur suis-je ?
      uptime       # Charge processeur
      """
    }

    quiz {
      question "Quelle commande affiche la charge du processeur ?" {
        - "whoami"
        + "uptime"
        - "pwd"
        explanation: "uptime donne le load average à 1, 5 et 15 minutes."
      }
    }
  }
}
```

---

## ⚖️ Licence & Crédits

Édité et maintenu par l'**Association TUTODECODE** (Association Loi 1901 à but non lucratif, SIREN 102 763 133).

- **Fondateur & Président** : Maxime MARTIN CIVET
- **Site Officiel** : [tutodecode.org](https://tutodecode.org)
- **Licence** : [GNU General Public License v3.0 (GPLv3)](LICENSE)
