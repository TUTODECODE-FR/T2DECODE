# Manuel de Référence des Interfaces Externes

[Read in English (EN)](EXTERNAL_INTERFACES.md)

Ce document décrit les interfaces externes, les formats de données, les protocoles et les arguments d'entrée utilisés par T2DECODE, permettant aux utilisateurs et développeurs d'étendre l'application, d'importer des cours personnalisés ou d'interagir avec le réseau pair-à-pair (P2P).

---

## 1. Schéma des Modules de Cours Personnalisés (JSON & Markdown)

T2DECODE permet d'importer des modules d'apprentissage personnalisés. Un module de cours importé doit être composé d'un descripteur JSON et des contenus Markdown associés.

### Schéma de Métadonnées du Cours (`course_manifest.json`)
Chaque cours personnalisé doit inclure un fichier manifeste définissant sa structure, ses modules et ses QCM de validation.

```json
{
  "courseId": "net-advanced-routing",
  "title": "Routage Réseau Avancé",
  "category": "Réseau",
  "difficulty": "Intermédiaire",
  "xpReward": 150,
  "modules": [
    {
      "moduleId": "routing-bgp",
      "title": "Introduction à BGP",
      "contentPath": "modules/routing-bgp.md",
      "quizzes": [
        {
          "question": "Quel port TCP est utilisé par le protocole BGP ?",
          "options": ["80", "179", "443", "22"],
          "correctAnswerIndex": 1,
          "explanation": "Le protocole BGP utilise le port TCP 179 pour établir ses sessions de peering."
        }
      ]
    }
  ]
}
```

### Contenu du Module (Markdown)
Le contenu de chaque module doit être écrit en Markdown standard et placé dans le chemin défini par `contentPath`. Il prend en charge le texte standard, les blocs de code (avec coloration syntaxique), les listes et les tableaux.

---

## 2. Protocole P2P LAN Ghost Link (Diffusion UDP)

La fonctionnalité **Ghost Link** fournit un chat et une découverte de pairs sans serveur sur un réseau local (LAN). Elle utilise la diffusion UDP et des échanges de paquets chiffrés de bout en bout.

### 1. Découverte de Pairs (Diffusion UDP)
*   **Protocole** : UDP Broadcast
*   **Port** : `54321` (par défaut)
*   **Format de charge utile** : Chaîne JSON diffusée toutes les 10 secondes.
*   **Structure** :
```json
{
  "event": "DISCOVER",
  "peerId": "c8a4-1234-abcd",
  "username": "Technicien-Orange-45",
  "publicKey": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBC..."
}
```

### 2. Échange de Messages (Unicast Direct)
Une fois découverts, les pairs établissent des connexions UDP directes pour échanger des messages chiffrés.
*   **Chiffrement** : AES-GCM (clé de 256 bits échangée via ECDH).
*   **Structure** :
```json
{
  "event": "MESSAGE",
  "senderId": "c8a4-1234-abcd",
  "iv": "d3f86a106a0bac45b974a628",
  "ciphertext": "z8K3fHk41PlaqOm="
}
```

---

## 3. Intégration de l'IA Locale (API Ollama)

T2DECODE s'intègre avec des instances locales LLM en utilisant l'API HTTP standard d'Ollama.

*   **URL du point de terminaison** : Configurable dans les paramètres (par défaut `http://localhost:11434`).
*   **Interface API** :
    *   `POST /api/chat` : Utilisé pour les complétions de chat en streaming (avec `stream: true`).
    *   `GET /api/tags` : Utilisé pour récupérer la liste des modèles LLM disponibles localement.

---

## 4. Arguments de la Ligne de Commande (CLI)

Bien que T2DECODE soit principalement une application graphique (GUI), elle prend en charge des arguments d'entrée système standard lors de son invocation.

| Paramètre | Type | Description |
| :--- | :--- | :--- |
| `--help` | Flag | Affiche les informations de version et l'aide des paramètres CLI. |
| `--offline` | Flag | Force l'application à démarrer en mode déconnecté absolu (air-gapped). |
| `--import-module <chemin>` | Chemin | Importe directement un package de cours au format zip lors du démarrage. |
