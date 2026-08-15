# 📜 Spécification Officielle du Langage TUTODECODE Script (`.tdc`)
**Standard Pédagogique Souverain v1.0 — Association TUTODECODE**

Le langage **TUTODECODE Script (`.tdc`)** est un langage dédié (DSL — *Domain Specific Language*) conçu spécifiquement pour la rédaction de cours techniques, de laboratoires virtuels et de QCMs interactifs.

Il remplace avantageusement le format JSON en éliminant la verbosité, la gestion complexe des guillemets et l'échappement manuel des caractères Markdown. Il est optimisé pour être rédigé facilement par des humains et généré avec une précision absolue par des modèles d'IA (LLMs, Ollama, GPT, Claude, Gemini).

---

## 📑 Sommaire
1. [Grammaire & Syntaxe EBNF](#1-grammaire--syntaxe-ebnf)
2. [Structure d'un Fichier `.tdc`](#2-structure-dun-fichier-tdc)
3. [Composants & Blocs](#3-composants--blocs)
4. [Guide de Prompting pour les IA & LLMs](#4-guide-de-prompting-pour-les-ia--llms)
5. [Exemple Complet Référence](#5-exemple-complet-référence)

---

## 1. Grammaire & Syntaxe EBNF

```ebnf
Course          ::= 'course' String '{' CourseHeader Module* '}'
CourseHeader    ::= ( 'title:' String | 'description:' String | 'category:' Ident | 'level:' Ident | 'duration:' String | 'icon:' Ident | 'keywords:' List )*
Module          ::= 'module' String '{' ModuleHeader ContentBlock CodeBlock* QuizBlock? '}'
ModuleHeader    ::= ( 'title:' String | 'duration:' String )*
ContentBlock    ::= 'content' TripleString
CodeBlock       ::= 'codeblock' String '{' 'title:' String 'code' TripleString '}'
QuizBlock       ::= 'quiz' '{' Question* '}'
Question        ::= 'question' String '{' Option+ ('explanation:' String)? '}'
Option          ::= ( '+' | '-' ) String
TripleString    ::= '"""' Characters '"""'
List            ::= '[' Ident (',' Ident)* ']'
```

---

## 2. Structure d'un Fichier `.tdc`

Un fichier `.tdc` est composé d'au moins un bloc principal `course "id" { ... }`.

### 📌 En-tête du Cours (`CourseHeader`)

| Clé | Type | Description | Valeurs Acceptées / Exemple |
| :--- | :--- | :--- | :--- |
| `title` | Chaîne (`"..."`) | Titre officiel affiché dans l'application | `"Linux : Le Pouvoir du Terminal"` |
| `description` | Chaîne (`"..."`) | Résumé du cours (1-2 phrases) | `"Maîtrisez le système d'exploitation des serveurs."` |
| `category` | Identifiant | Catégorie thématique | `linux`, `network`, `security`, `cloud`, `crypto`, `development` |
| `level` | Identifiant | Niveau de difficulté | `beginner`, `intermediate`, `advanced` |
| `duration` | Chaîne | Durée estimée du cours complet | `"2h"`, `"6h"`, `"45min"` |
| `icon` | Identifiant | Icône Lucide / Material | `Terminal`, `Shield`, `Network`, `Cpu`, `Lock`, `Code` |
| `keywords` | Liste (`[...]`) | Mots-clés pour le moteur de recherche | `[linux, bash, sysadmin, terminal]` |

---

## 3. Composants & Blocs

### 📦 Bloc `module`
Un cours contient une suite de modules d'apprentissage.

```tdc
module "nom-du-module" {
  title: "Titre du Chapitre"
  duration: 15min

  content """
  # Titre Markdown
  Rédigez le texte du cours librement en **Markdown**.
  Les sauts de ligne et blocs de code sont préservés naturellement.
  """
}
```

### 💻 Bloc `codeblock`
Insère un extrait de code interactif avec syntax highlighting.

```tdc
codeblock "bash" {
  title: "Vérification des processus actifs"
  code """
  ps aux | grep nginx
  top -b -n 1
  """
}
```

### ❓ Bloc `quiz` & `question`
Définit un questionnaire à choix multiples.

- **`+ "..."`** : Marque la **bonne réponse** (une seule par question).
- **`- "..."`** : Marque les **fausses réponses** (leurres).
- **`explanation: "..."`** : Explication pédagogique affichée lors de la correction.

```tdc
quiz {
  question "Quelle est l'adresse IP de loopback IPv4 ?" {
    - "192.168.1.1"
    + "127.0.0.1"
    - "10.0.0.1"
    explanation "127.0.0.1 est l'adresse réservée pour désigner la machine locale (localhost)."
  }
}
```

---

## 4. Guide de Prompting pour les IA & LLMs

Lorsque vous demandez à une IA (Ollama, ChatGPT, Claude, Gemini, Codex) de générer un cours pour T2DECODE, utilisez la consigne suivante :

> **Prompt Consigne IA Standard :**
> *"Génère un cours technique au format officiel TUTODECODE Script (`.tdc`).
> Respecte la syntaxe `course "id" { ... }`, les blocs `module "id" { ... }`, le contenu Markdown entre triple guillemets `"""`, et les QCMs avec `+` pour la réponse correcte et `-` pour les erreurs."*

---

## 5. Exemple Complet Référence

```tdc
course "network-subnetting-101" {
  title: "Réseaux : Maîtriser le Subnetting IPv4"
  description: "Comprenez les masques de sous-réseau, les plages d'adresses et la notation CIDR."
  category: network
  level: intermediate
  duration: 2h
  icon: Network
  keywords: [network, ip, cidr, subnetting, mask]

  module "cidr-intro" {
    title: "Comprendre la Notation CIDR"
    duration: 20min

    content """
    # 🌐 Les Masques de Sous-Réseau et le CIDR

    Dans un réseau IPv4, le masque permet de diviser l'adresse IP en deux parties :
    1. **La portion réseau** (définie par les bits à 1 du masque)
    2. **La portion hôte** (définie par les bits à 0 du masque)

    ## 📊 Table d'Équivalence Courante

    | Notation CIDR | Masque Décimal | Hôtes Utiles |
    | :--- | :--- | :--- |
    | `/24` | `255.255.255.0` | 254 hôtes |
    | `/28` | `255.255.255.240` | 14 hôtes |
    | `/30` | `255.255.255.252` | 2 hôtes (Lien point-à-point) |
    """

    codeblock "bash" {
      title: "Calcul rapide de sous-réseau sous Linux"
      code """
      # Utiliser ipcalc pour auditer une plage CIDR
      ipcalc 192.168.1.50/28
      """
    }

    quiz {
      question "Combien d'hôtes utilisables fournit un sous-réseau /28 ?" {
        - "16 hôtes"
        + "14 hôtes"
        - "30 hôtes"
        explanation "Un /28 laisse 4 bits pour les hôtes (2^4 = 16). En retirant l'adresse réseau et l'adresse de broadcast, il reste 14 hôtes."
      }
    }
  }
}
```
