# Workflow Bénévoles — Contenus T2DECODE

Ce guide est destiné aux bénévoles qui créent ou traduisent les contenus de l’application **T2DECODE** sans toucher au code Flutter.

---

## Principe de base

Tous les contenus pédagogiques sont écrits dans le langage **TUTODECODE Script (`.tdc`)**.

- Pas de JSON à maintenir.
- Pas de code Dart à modifier.
- Une seule grammaire pour les cours, les cheat sheets et les traductions d’interface.

---

## Arborescence des contenus

```
assets/
├── courses.tdc              ← cours en français (référence)
├── courses_en.tdc           ← traduction anglais
├── courses_es.tdc           ← traduction espagnol
├── cheat_sheets.tdc         ← cheat sheets français
├── cheat_sheets_en.tdc      ← traduction anglais
├── netkit_cheat_sheets.tdc  ← netkit français
├── locales/
│   ├── fr.tdc               ← interface français
│   └── en.tdc               ← interface anglais
└── asset_checksums.json     ← généré automatiquement
```

---

## Comment contribuer (via GitLab)

1. **Créer une branche** depuis `main` :
   ```bash
   git checkout -b feat/ajout-cours-linux-avance
   ```
2. **Éditer le fichier `.tdc`** concerné dans le dossier `assets/`.
3. **Ouvrir une Merge Request** sur GitLab.
4. La CI exécute `tdc lint` et vérifie que les fichiers sont valides.
5. Après validation, la MR est fusionnée et le build de l’app intègre les nouveaux contenus.

---

## Guide rapide pour un traducteur (exemple : anglais)

### Étape 1 : Forker le repo T2DECODE sur GitLab

Vous n’avez besoin que d’un navigateur web pour commencer.

### Étape 2 : Créer un fichier `.tdc` par langue

Pour traduire l’interface en anglais, créez :
- `assets/locales/en.tdc` à partir de `assets/locales/fr.tdc`
- `assets/courses_en.tdc` à partir de `assets/courses.tdc`
- `assets/cheat_sheets_en.tdc` à partir de `assets/cheat_sheets.tdc`

### Étape 3 : Utiliser TDC Studio App (optionnel mais recommandé)

Ouvrez TDC Studio App sur votre bureau. L’assistant d’accueil explique :
1. L’onglet **Cheat Sheets** pour les commandes.
2. L’onglet **Locales UI** pour les textes de l’interface.
3. L’onglet **Export** pour écrire directement dans `assets/`.

Cochez **« Ne plus me montrer »** quand vous connaissez le fonctionnement.

### Étape 4 : Ne traduire que les valeurs visibles

Conservez intactes :
- les identifiants de cours : `course "linux-basics"`
- les identifiants d’entrées : `entry "ip-link-show"`
- les clés de locale : `menu.home`, `home.banner.title`

Traduisez seulement ce qui est entre guillemets après le `:`.

### Étape 5 : Ouvrir une Merge Request

Nommez votre branche `feat/translation-en` et décrivez ce que vous avez traduit. La CI valide la syntaxe `.tdc` automatiquement.

---

## Outils recommandés

| Outil | Utilisation |
|-------|-------------|
| **TDC Studio App** | Interface graphique pour éditer cheat sheets et locales |
| **TDC Studio Editorial** | Interface graphique pour les cours et QCM |
| **Extension VS Code `vscode-tdc`** | Coloration syntaxique, snippets et validation |
| **CLI `tdc`** | Validation en ligne de commande (`tdc lint`) |

---

## Règles de contribution

- **Ne jamais modifier les identifiants** : `course "linux-basics"`, `entry "ip-link-show"`, clés JSON/ui (`menu.home`).
- **Traduire uniquement les textes visibles** : titres, descriptions, contenus, explications.
- **Une langue = une PR/MR** pour faciliter la relecture.
- **Toujours tester avec `tdc lint`** avant de soumettre.

---

## Pourquoi `.tdc` et pas JSON ?

Le format `.tdc` est le standard pédagogique de TUTODECODE. Il est :
- plus lisible que le JSON (moins de guillemets et de virgules) ;
- validable par un linter (`tdc lint`) ;
- structuré pour les cours, les QCM, les cheat sheets et les locales ;
- plus facile à générer correctement par des IA et des assistants locaux.

---

## Licence des contenus

Les outils du SDK (Studio, CLI, extension VS Code) sont sous **GPLv3**.
Les contenus pédagogiques produits par l’association (cours, cheat sheets, traductions) sont sous **CC BY-SA 4.0** ou **GPLv3** selon la volonté de l’auteur, afin de rester libres et réutilisables par la communauté.
