#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script de traduction locale décentralisée de T2DECODE via Ollama
import json
import os
import sys
import requests

OLLAMA_URL = "http://localhost:11434/api/generate"

def flatten_json(y):
    out = {}
    def flatten(x, name=''):
        if type(x) is dict:
            for a in x:
                flatten(x[a], name + a + '.')
        else:
            out[name[:-1]] = x
    flatten(y)
    return out

def unflatten_json(dictionary):
    result = {}
    for key, value in dictionary.items():
        parts = key.split('.')
        d = result
        for part in parts[:-1]:
            if part not in d:
                d[part] = {}
            d = d[part]
        d[parts[-1]] = value
    return result

def chunk_dict(data, chunk_size):
    it = iter(data)
    for i in range(0, len(data), chunk_size):
        yield {k: data[k] for k in [next(it) for _ in range(min(chunk_size, len(data) - i))]}

def clean_json(text):
    text = text.strip()
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 translate_app.py <lang_code> <lang_name> [model]")
        print("Ex: python3 translate_app.py es 'Espagnol' qwen2.5-coder")
        sys.exit(1)
        
    lang_code = sys.argv[1].lower()
    lang_name = sys.argv[2]
    model = sys.argv[3] if len(sys.argv) > 3 else "qwen2.5:1.5b"
    
    base_file = "../assets/translations/fr.json"
    if not os.path.exists(base_file):
        base_file = "assets/translations/fr.json"
        if not os.path.exists(base_file):
            print("Erreur: Impossible de trouver fr.json")
            sys.exit(1)

    print(f"[*] Chargement de {base_file}")
    with open(base_file, "r", encoding="utf-8") as f:
        fr_data = json.load(f)

    flat_data = flatten_json(fr_data)
    chunks = list(chunk_dict(flat_data, 40))
    translated_flat = {}

    print(f"[*] Lancement de la traduction vers {lang_name} ({lang_code}) via {model}...")
    print(f"[*] {len(flat_data)} clés à traduire en {len(chunks)} lots.")

    for i, chunk in enumerate(chunks):
        print(f"  -> Traduction du lot {i+1}/{len(chunks)}...", end="", flush=True)
        
        json_str = json.dumps(chunk, ensure_ascii=False)
        prompt = f"""Tu es un traducteur expert spécialisé en UI d'applications.
Traduis les VALEURS de ce JSON du Français vers : {lang_name}.
Règles strictes :
1. NE TRADUIS JAMAIS LES CLÉS.
2. RENVOIE UNIQUEMENT UN OBJET JSON VALIDE ET RIEN D'AUTRE. AUCUN TEXTE AVANT NI APRÈS.
3. PRÉSERVE LA SYNTAXE EXACTE DU JSON.

JSON à traduire :
{json_str}"""

        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_predict": 800,
                "temperature": 0.3
            }
        }

        try:
            res = requests.post(OLLAMA_URL, json=payload, timeout=60)
            res.raise_for_status()
            raw_text = res.json().get("response", "")
            
            clean_text = clean_json(raw_text)
            chunk_translated = json.loads(clean_text)
            translated_flat.update(chunk_translated)
            print(" [OK]")
        except Exception as e:
            print(f" [ERREUR: {e}] - Repli sur le Français pour ce lot.")
            translated_flat.update(chunk) # Fallback

    final_json = unflatten_json(translated_flat)
    
    # Validation stricte avant écriture
    try:
        final_str = json.dumps(final_json, ensure_ascii=False, indent=2)
        json.loads(final_str)
    except Exception as e:
        print(f"[!] ERREUR CRITIQUE: Le JSON généré est invalide ({e}). Annulation.")
        sys.exit(1)
        
    out_dir = os.path.expanduser("~/Documents/T2DECODE/translations")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{lang_code}.json")
    
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(final_str)
        
    print(f"[*] Traduction terminée et sauvegardée dans {out_path}")
    print("[*] Redémarrez l'application T2DECODE pour voir la nouvelle langue.")

if __name__ == "__main__":
    main()
