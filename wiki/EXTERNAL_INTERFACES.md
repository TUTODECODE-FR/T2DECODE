# External Interfaces Reference Manual

[Lire en Français (FR)](EXTERNAL_INTERFACES_FR.md)

This document describes the external interfaces, data formats, protocols, and inputs used by T2DECODE, allowing users and developers to extend the application, import custom courses, or interact with its peer-to-peer (P2P) network.

---

## 1. Custom Course Module Schema (JSON & Markdown)

T2DECODE allows users and educators to import custom learning modules. An imported course module must consist of a JSON descriptor and associated Markdown contents.

### Course Metadata Schema (`course_manifest.json`)
Every custom course must include a manifest file defining its structure, modules, and validation quizzes.

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

### Module Content (Markdown)
The content of each module must be written in standard Markdown and placed in the referenced `contentPath`. It supports standard text, code blocks (with syntax highlighting), lists, and table formatting.

---

## 2. Ghost Link P2P LAN Protocol (UDP Broadcast)

The **Ghost Link** feature provides serverless chat and discovery over a Local Area Network (LAN). It uses UDP broadcasting and end-to-end encrypted packet exchanges.

### 1. Peer Discovery (UDP Broadcast)
*   **Protocol**: UDP Broadcast
*   **Port**: `54321` (default)
*   **Payload Format**: JSON string broadcasted every 10 seconds.
*   **Structure**:
```json
{
  "event": "DISCOVER",
  "peerId": "c8a4-1234-abcd",
  "username": "Technicien-Orange-45",
  "publicKey": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBC..."
}
```

### 2. Message Exchange (Direct Unicast)
Once discovered, peers establish direct UDP connections for exchanging encrypted messages.
*   **Encryption**: AES-GCM (256-bit key exchanged via ECDH).
*   **Structure**:
```json
{
  "event": "MESSAGE",
  "senderId": "c8a4-1234-abcd",
  "iv": "d3f86a106a0bac45b974a628",
  "ciphertext": "z8K3fHk41PlaqOm="
}
```

---

## 3. Local AI Integration (Ollama API Integration)

T2DECODE integrates with local LLM instances using the standard Ollama HTTP API.

*   **Endpoint URL**: Configurable in settings (defaults to `http://localhost:11434`).
*   **API Interface**:
    *   `POST /api/chat` : Used for streaming chat completions (with `stream: true`).
    *   `GET /api/tags` : Used to retrieve the list of locally pulled LLM models.

---

## 4. Command-Line Interface (CLI) Arguments

While T2DECODE is primarily a graphical user interface (GUI) application, it supports standard system invocation inputs.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `--help` | Flag | Displays version info and CLI usage parameters. |
| `--offline` | Flag | Forces the app to start in absolute air-gapped mode, skipping local version checks. |
| `--import-module <path>` | Path | Directly imports a course package zip file upon startup. |
