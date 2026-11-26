# Écrire un cours T2DECODE (.tdc)

Guide commun à tous les rédacteurs, humains ou non. Un cours = un fichier
`assets/courses/fr/<slug>.tdc`, et sa traduction `assets/courses/en/<slug>.tdc` (même nom de fichier).
Modèle de référence : `assets/courses/fr/bash-scripting.tdc`.

## Public et objectif

Élèves de bac pro CIEL, BTS SIO (SISR, SLAM), BTS CIEL, BUT informatique et réseaux, et autodidactes.
Chaque cours doit permettre de **faire** quelque chose à la fin, pas seulement de connaître des mots.
L'application fonctionne hors ligne : le cours se suffit à lui-même, sans lien obligatoire vers Internet.

## Structure d'un fichier

```tdc
tdc-version: 2
type: course

course "slug-du-cours" {
  title: "Titre court et clair"
  description: """
Une phrase qui dit ce que le cours apprend et à qui il s'adresse.

À la fin, tu sauras :
• objectif concret 1 ;
• objectif concret 2 ;
• objectif concret 3.

Prérequis : ce qu'il faut savoir avant (ou « aucun »).
"""
  category: "network"
  level: "beginner"
  duration: "3h"
  icon: "Router"
  keywords: ["mot", "clé"]

  module "identifiant-court" {
    title: "Chapitre 1 : titre"
    duration: "20min"
    content: """
Texte en Markdown (titres ###, listes, **gras**, `code`, tableaux, blocs ```bash).
"""

    codeblock "bash" {
      title: "Ce que fait ce code"
      code: """
commande exemple
"""
    }

    quiz {
      pick: 5
      question "Question claire ?" {
        - "réponse fausse plausible"
        + "bonne réponse"
        - "réponse fausse plausible"
        - "réponse fausse plausible"
        explanation: "Pourquoi la bonne réponse est juste et pourquoi les autres sont fausses."
      }
    }
  }
}
```

Valeurs autorisées :
- `category` : `network`, `linux`, `security`, `devops`, `cloud`, `sql`, `python`, `javascript`, `web`, `programming`
- `level` : `beginner`, `intermediate`, `advanced`
- `icon` : nom d'icône Material en PascalCase (`Router`, `Terminal`, `Security`, `Lock`, `Dns`, `Storage`, `Code`, `Cloud`, `Lan`, `Hub`, `Shield`, `DataObject`, `Api`, `AccountTree`, `Computer`)

## Contenu des chapitres

- 6 à 10 chapitres par cours, de 15 à 40 minutes chacun.
- Chaque chapitre suit le même rythme : **une idée, un exemple concret, un exercice pratique, un questionnaire.**
- Un exercice pratique par chapitre au minimum, sous un titre `### À toi de jouer`, avec l'énoncé, puis la solution
  dans un bloc séparé sous `### Correction` (étapes et résultat attendu).
- Des situations réelles : panne à diagnostiquer, poste à configurer, journal à lire, incident de sécurité.
  Pas de « Marc DevOps » ni d'entreprise imaginaire caricaturale ; un contexte simple (« le lycée », « une PME de 20 postes ») suffit.
- Commandes et sorties exactes, testables sur Debian/Ubuntu, Windows 10/11 ou Windows Server 2022.
- Un chapitre final de synthèse avec un mini-projet guidé.

## Questionnaires

- Chaque chapitre a une **banque de 10 à 15 questions**, avec `pick: 5` : l'application en tire 5 au hasard
  à chaque tentative et mélange les réponses. Le chapitre de synthèse : 20 questions, `pick: 10`.
- Une seule bonne réponse (`+`), 3 ou 4 réponses fausses (`-`) **plausibles**, de longueur comparable.
- Varier les types : définition, lecture d'une sortie de commande, calcul (masque, conversion), « que se passe-t-il si… »,
  choix de la bonne commande, repérage d'une erreur.
- Toujours une `explanation` qui explique la bonne réponse et l'erreur classique.
- Une option par ligne (l'outil `tdc check` ne compte pas les options écrites sur une seule ligne).
- Pas de « toutes les réponses » ni « aucune des réponses ».

## Style

- Français simple, phrases courtes, tutoiement (comme le reste de l'application).
- Aucun émoji. Pas de superlatifs ni de ton marketing (« ultime », « révolutionnaire », « maîtrise totale »).
- Les termes anglais utiles sont donnés une fois entre parenthèses : « passerelle par défaut (default gateway) ».
- Pas de copier-coller de sources : reformuler. Les définitions officielles peuvent être citées brièvement.

## Exactitude

- Vérifier chaque fait technique dans une source fiable : RFC, documentation officielle (man pages, Microsoft Learn,
  docs Debian, Python, MDN, PostgreSQL, Docker…), ANSSI, CNIL, OWASP, référentiels officiels des diplômes.
- Indiquer en fin de cours une section « Pour aller plus loin » avec 3 à 6 références (titre et éditeur, URL facultative).
- Aucune commande dangereuse sans avertissement explicite (`rm -rf`, formatage, `iptables -F` à distance…).
- Les exercices d'attaque restent pédagogiques et légaux : environnement de test personnel, jamais une cible réelle.

## Vérification

```bash
~/Documents/TDC-SDK/tdc check assets/courses/fr/<slug>.tdc
```

Le fichier doit être « Valide », et le nombre de bonnes réponses marquées `+` doit être égal au nombre de questions.
