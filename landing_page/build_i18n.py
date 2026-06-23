#!/usr/bin/env python3
"""
MASTER i18n builder:
1. Restores HTML files from backup (if available) or uses current state
2. Scans ALL text in all HTML files, assigns data-i18n keys
3. Translates everything into 6 languages via Google Translate (free, private)
4. Embeds dictionaries INLINE in each HTML page (no external files needed → works online)
5. Writes per-language .js files in /locales/ as well
"""
import os, json, re, urllib.request, urllib.parse, time
from bs4 import BeautifulSoup, NavigableString, Comment, Tag
from concurrent.futures import ThreadPoolExecutor

# ─── Config ───────────────────────────────────────────────────────────────────
HTML_FILES = ['index.html']
LOCALES_DIR = 'locales'
LANGS = {
    'en': 'en',
    'es': 'es',
    'de': 'de',
    'ar': 'ar',
    'zh-CN': 'zh-CN',
}
INLINE_TAGS = {'strong','em','b','i','u','span','a','br','abbr','mark','small','sub','sup','time','code'}
SKIP_CLASSES = {'lang-switcher-container','lang-menu','lang-btn'}
SKIP_IDS     = {'langSwitcherContainer','langMenu','mainLangBtn'}

os.makedirs(LOCALES_DIR, exist_ok=True)

# ─── Helpers ──────────────────────────────────────────────────────────────────
def has_real_text(tag):
    """Tag contains at least one non-whitespace character not inside a script/style."""
    for s in tag.strings:
        if s.strip():
            return True
    return False

def is_translatable_block(tag):
    """True if tag is a leaf-level text block we should translate."""
    if not isinstance(tag, Tag):
        return False
    name = tag.name
    if name in ('script','style','noscript','head','html','body','meta','link','title'):
        return False
    if not has_real_text(tag):
        return False
    # Check if all block-level descendants are already tagged or if the tag itself is already tagged
    if tag.has_attr('data-i18n'):
        return False
    # Skip if inside a skip-class container
    for parent in tag.parents:
        if not isinstance(parent, Tag): continue
        if parent.get('id','') in SKIP_IDS: return False
        if any(c in SKIP_CLASSES for c in parent.get('class',[])): return False
    # It's a block if it has NO block-level children that aren't already tagged
    for child in tag.children:
        if isinstance(child, Tag):
            if child.name not in INLINE_TAGS and child.name not in ('svg','path','circle','rect'):
                return False  # has a block child → not a leaf block
    return True

def html_of(tag):
    return tag.decode_contents().strip()

def translate_text(text, dest_lang, retries=3):
    if not text.strip() or dest_lang == 'fr':
        return text
    for attempt in range(retries):
        try:
            url = ("https://translate.googleapis.com/translate_a/single"
                   "?client=gtx&sl=fr&tl=" + urllib.parse.quote(dest_lang) +
                   "&dt=t&q=" + urllib.parse.quote(text))
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            resp = urllib.request.urlopen(req, timeout=10)
            data = json.loads(resp.read().decode('utf-8'))
            return "".join(part[0] for part in data[0] if part[0])
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1 + attempt)
            else:
                print(f"  [WARN] translation failed for lang={dest_lang}: {e}")
                return text

# ─── Step 1: Tag all HTML files ───────────────────────────────────────────────
print("=" * 60)
print("STEP 1: Scanning HTML and assigning data-i18n keys")
print("=" * 60)

master_fr = {}   # key -> french text (inner HTML)
key_counter = [1]  # mutable for nested use

def assign_keys(soup, file_prefix):
    """Walk soup and add data-i18n to every untranslated text block."""
    for tag in soup.find_all(True):
        if not is_translatable_block(tag):
            continue
        inner = html_of(tag)
        if not inner:
            continue
        # Check if already has a key in our dict
        key = tag.get('data-i18n')
        if key and key in master_fr:
            continue  # already done
        # Make a new unique key
        key = f"t_{key_counter[0]}"
        key_counter[0] += 1
        tag['data-i18n'] = key
        master_fr[key] = inner
    return soup

for filepath in HTML_FILES:
    if not os.path.exists(filepath):
        print(f"  [SKIP] {filepath} not found")
        continue
    print(f"  Scanning {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        raw = f.read()
    
    # Remove any OLD injected lang switcher block so we start fresh
    pattern = r'\n?    <!-- Offline Privacy-First Language Switcher -->.*?</body>'
    raw = re.sub(pattern, '\n</body>', raw, flags=re.DOTALL)
    
    soup = BeautifulSoup(raw, 'html.parser')
    soup = assign_keys(soup, filepath)
    
    # Save tagged HTML (without switcher yet, we add it after translations are embedded)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(str(soup))
    print(f"    → {len(master_fr)} keys total so far")

print(f"\n  Total French strings extracted: {len(master_fr)}")

# Save master FR dict
with open(os.path.join(LOCALES_DIR, 'fr.json'), 'w', encoding='utf-8') as f:
    json.dump(master_fr, f, ensure_ascii=False, indent=2)

# ─── Step 2: Translate into all languages ─────────────────────────────────────
print("\n" + "=" * 60)
print("STEP 2: Translating into all languages")
print("=" * 60)

all_dicts = {'fr': master_fr}

def translate_lang(lang_code):
    google_code = LANGS[lang_code]
    print(f"  [{lang_code}] Starting translation of {len(master_fr)} strings...")
    result = {}
    
    # Load existing partial translation if any
    json_path = os.path.join(LOCALES_DIR, f"{lang_code}.json")
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            result = json.load(f)
    
    # Translate missing keys
    keys_todo = [k for k in master_fr if k not in result]
    for i, k in enumerate(keys_todo):
        result[k] = translate_text(master_fr[k], google_code)
        if i > 0 and i % 25 == 0:
            print(f"  [{lang_code}] {i}/{len(keys_todo)} done...")
    
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(f"  [{lang_code}] Done! {len(result)} strings saved.")
    return lang_code, result

# Translate all languages in parallel
with ThreadPoolExecutor(max_workers=5) as executor:
    futures = [executor.submit(translate_lang, lc) for lc in LANGS]
    for future in futures:
        lc, d = future.result()
        all_dicts[lc] = d

# ─── Step 3: Write .js locale files (for online hosting too) ─────────────────
print("\n" + "=" * 60)
print("STEP 3: Writing locale JS files")
print("=" * 60)

for lang, d in all_dicts.items():
    js_content = f"window['dict_{lang}'] = {json.dumps(d, ensure_ascii=False, indent=2)};\n"
    js_path = os.path.join(LOCALES_DIR, f"{lang}.js")
    with open(js_path, 'w', encoding='utf-8') as f:
        f.write(js_content)
    print(f"  Saved {js_path}")

# ─── Step 4: Run clean CSP-compliant switcher generation ──────────────────────
print("\n" + "=" * 60)
print("STEP 4: Generating CSP-compliant external switcher files")
print("=" * 60)

import subprocess
try:
    subprocess.run(["python3", "fix_all.py"], check=True)
    print("\n✅ MASTER BUILD SUCCESSFUL!")
except Exception as e:
    print(f"\n❌ Error running fix_all.py: {e}")

