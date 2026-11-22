# Devenir testeur de T2DECODE

Merci de nous aider ! Tester T2DECODE prend **environ 20 minutes**, sans compte ni inscription. L'application ne collecte rien : aucune télémétrie, aucun compte, tout reste sur ton appareil.

## 1. Installer

Prends la dernière version sur la [page des versions](https://github.com/TUTODECODE-FR/T2DECODE/releases/latest) (ou sur [SourceForge](https://sourceforge.net/projects/t2decode/files/)).

| Système | Comment |
|---|---|
| **Windows** | `T2DECODE-Windows-Setup.exe` (installateur) ou `T2DECODE-Windows.zip` (portable). L'app n'est pas encore signée : si Windows affiche « Windows a protégé votre ordinateur », clique sur **Informations complémentaires** puis **Exécuter quand même**. |
| **macOS** | `T2DECODE-macOS.dmg` : ouvre-le et glisse T2DECODE dans Applications. Ou `brew install --cask tutodecode-org/tap/t2decode`. |
| **Linux** | `sudo snap install t2decode`, ou l'archive `T2DECODE-Linux.tar.gz`. |
| **Android** | F-Droid, ou l'APK `app-arm64-v8a-release.apk` (la plupart des téléphones récents). |

**Versions bêta** (quand une bêta est annoncée) : sous Linux, `sudo snap install t2decode --beta` (ou `sudo snap refresh t2decode --beta`).

Pour vérifier un fichier téléchargé, compare son empreinte avec `SHA256SUMS.txt` :

```bash
sha256sum -c SHA256SUMS.txt --ignore-missing
```

## 2. Quoi tester

Coche ce que tu as pu essayer, et note tout ce qui te surprend, même un détail.

- [ ] L'application s'installe et se lance sans erreur.
- [ ] **Hors ligne** : coupe Internet (mode avion) et relance, tout doit fonctionner.
- [ ] **Cours** : ouvrir un cours officiel, lire un chapitre, répondre au quiz.
- [ ] **Outils** : calculateur IP / sous-réseau (CIDR), permissions Unix (chmod), hachage, générateur de scripts.
- [ ] **Labo** : lancer un simulateur (réseau, cryptographie…).
- [ ] **Réglages** : importer un fichier de cours `.tdc` (si tu en as un).
- [ ] **Affichage** : redimensionner la fenêtre (ordinateur), tourner l'écran (téléphone), thème clair et sombre.
- [ ] Facultatif : **IA locale** avec [Ollama](https://ollama.com) installé sur ta machine.
- [ ] Facultatif : option **« Cours depuis T2C Phantom »** des Réglages, si tu utilises T2C Phantom.

## 3. Nous faire un retour

Le plus simple, au choix :

- **Formulaire « Retour de test »** sur [GitHub](https://github.com/TUTODECODE-FR/T2DECODE/issues/new/choose) ou [GitLab](https://gitlab.com/tutodecode-org/T2DECODE/-/issues/new?issuable_template=Retour_de_test) ;
- **par e-mail** à `contact@tutodecode.org`, objet **`[Test T2DECODE vX.Y.Z]`**.

Indique toujours : **ta version de T2DECODE** (Réglages → Association & Mentions Légales → « Version »), **ton système** (Windows 11, macOS 15, Ubuntu 24.04, Android 14…), ce que tu faisais, ce qui s'est passé et ce que tu attendais. Une capture d'écran aide beaucoup.

Ne mets **jamais** de mot de passe ni d'information personnelle dans un retour public.

## 4. Merci

Chaque testeur qui le souhaite est remercié dans les notes de version. Dis-nous dans ton retour sous quel nom (ou pseudo) tu veux apparaître, ou si tu préfères rester anonyme.

Enseignant ou enseignante ? Une séance de test avec ta classe nous aide énormément : écris-nous à `contact@tutodecode.org`, nous préparons la séance avec toi.
