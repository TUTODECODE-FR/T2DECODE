#!/usr/bin/env python3
"""
Nettoie les emojis des cours et améliore les titres de blocs de code.
"""
import json
import re

EMOJI_PATTERN = re.compile(
    "["
    "\U0001F600-\U0001F64F"  # emoticons
    "\U0001F300-\U0001F5FF"  # symbols & pictographs
    "\U0001F680-\U0001F6FF"  # transport & map
    "\U0001F1E0-\U0001F1FF"  # flags
    "\U00002702-\U000027B0"
    "\U000024C2-\U0001F251"
    "\U0001F900-\U0001F9FF"  # supplemental symbols
    "\U0001FA00-\U0001FA6F"
    "\U0001FA70-\U0001FAFF"
    "\U00002600-\U000026FF"  # misc symbols
    "\U00002700-\U000027BF"  # dingbats
    "\U0000FE00-\U0000FE0F"  # variation selectors
    "\U0001F018-\U0001F270"
    "\U0000200D"             # zero width joiner
    "]+",
    flags=re.UNICODE,
)

# Titres de blocs de code améliorés (mapping emoji-title → clean title)
CODE_TITLE_MAP = {
    "Votre Premier Contact avec Linux": "Premier contact avec le terminal Linux",
    "Exercice Pratique : Exploration Guidée": "Exercice pratique — Navigation et exploration",
    "De Zéro à un Conteneur en 5 Minutes": "Premiers pas avec Docker — conteneur en 5 minutes",
    "Votre Premier Dépôt Git : Workflow Complet": "Premier dépôt Git — workflow complet",
    "De Zéro à votre Première Requête SQL": "Exploration SQL — premières requêtes",
    "Python en 60 Lignes : L'Essentiel": "Python essentiel — types, fonctions, gestion d'erreurs",
    "JavaScript Moderne : Les Patterns Essentiels": "JavaScript moderne — patterns fondamentaux",
    "OSINT — Reconnaissance sur Toi-Même": "OSINT — reconnaissance sur votre propre périmètre",
    "Simuler et Bloquer une Injection SQL": "Démonstration pédagogique — injection SQL et protection",
    "Script Complet : Moniteur de Santé Système": "Script complet — moniteur de santé système",
    "Script : Rotation de Logs Automatique": "Script — rotation automatique de logs",
    "Explorer les Couches Réseau en Live": "Explorer les couches réseau en temps réel",
    "API REST Complète en 80 lignes (FastAPI)": "API REST complète avec FastAPI",
    "Async/Await : 10x Plus Rapide pour les I/O": "Async/Await — performances I/O avec asyncio",
    "Pipeline Complet : Test + Build + Deploy": "Pipeline CI/CD complet — Test, Build, Deploy",
    "30 Regex Utiles en Pratique": "Trente expressions régulières utiles en pratique",
    "Chiffrement AES + Hachage Argon2 Corrects": "Chiffrement AES-256-GCM et hachage Argon2id",
    "Benchmark : Voir la Différence Big-O en Vrai": "Benchmark — comparaison des complexités Big-O",
    "Rust en Pratique : Structures et Erreurs": "Rust en pratique — structures et gestion d'erreurs",
}

def strip_emojis(text: str) -> str:
    """Supprime les emojis d'une chaîne et nettoie les espaces résiduels."""
    cleaned = EMOJI_PATTERN.sub("", text)
    # Nettoyer les espaces multiples résiduels
    cleaned = re.sub(r"  +", " ", cleaned)
    # Nettoyer les espaces en début/fin de ligne dans le markdown
    cleaned = re.sub(r"^\s+$", "", cleaned, flags=re.MULTILINE)
    return cleaned

def clean_title(title: str) -> str:
    """Nettoie un titre de bloc de code."""
    # Essayer le mapping direct d'abord
    for k, v in CODE_TITLE_MAP.items():
        if k in title:
            return v
    # Sinon juste strip les emojis
    return strip_emojis(title).strip()

def process_code_blocks(blocks):
    if not blocks:
        return blocks
    result = []
    for block in blocks:
        new_block = dict(block)
        if "title" in new_block:
            new_block["title"] = clean_title(new_block["title"])
        result.append(new_block)
    return result

def process_module(module: dict) -> dict:
    """Traite un module de cours."""
    m = dict(module)
    if "title" in m:
        m["title"] = strip_emojis(m["title"]).strip()
    if "content" in m:
        m["content"] = strip_emojis(m["content"])
    if "codeBlocks" in m:
        m["codeBlocks"] = process_code_blocks(m["codeBlocks"])
    if "quiz" in m:
        new_quiz = []
        for q in m["quiz"]:
            nq = dict(q)
            if "question" in nq:
                nq["question"] = strip_emojis(nq["question"]).strip()
            if "choices" in nq:
                nq["choices"] = [strip_emojis(c).strip() for c in nq["choices"]]
            if "explanation" in nq:
                nq["explanation"] = strip_emojis(nq["explanation"]).strip()
            new_quiz.append(nq)
        m["quiz"] = new_quiz
    return m

def process_course(course: dict) -> dict:
    """Traite un cours complet."""
    c = dict(course)
    if "title" in c:
        c["title"] = strip_emojis(c["title"]).strip()
    if "description" in c:
        c["description"] = strip_emojis(c["description"]).strip()
    if "content" in c:
        c["content"] = [process_module(m) for m in c["content"]]
    return c

def main():
    src = "assets/courses.json"
    dst = "assets/courses.json"

    with open(src, "r", encoding="utf-8") as f:
        data = json.load(f)

    cleaned = [process_course(c) for c in data]

    with open(dst, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    print(f"Traité {len(cleaned)} cours. Fichier mis à jour : {dst}")

if __name__ == "__main__":
    main()
