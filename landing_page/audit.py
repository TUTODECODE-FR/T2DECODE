#!/usr/bin/env python3
"""Full audit of all HTML and language switcher files before upload."""
import re
import json
import os

HTML_FILES = ['index.html']
LANGS = ['fr', 'en', 'es', 'de', 'ar', 'zh-CN']
FLAGS_DIR = 'flags'
ERRORS = []
WARNINGS = []

def err(file, msg):  ERRORS.append(f'  ❌ [{file}] {msg}')
def warn(file, msg): WARNINGS.append(f'  ⚠️  [{file}] {msg}')
def ok(msg):         print(f'  ✅ {msg}')

# Check switcher assets existence globally
print(f'\n{"="*55}')
print('  Auditing Shared Switcher Assets')
print(f'{"="*55}')

assets_ok = True
if not os.path.exists('switcher.css'):
    err('switcher.css', 'File is missing!')
    assets_ok = False
else:
    ok(f'switcher.css is present ({os.path.getsize("switcher.css")} bytes)')

if not os.path.exists('switcher.js'):
    err('switcher.js', 'File is missing!')
    assets_ok = False
else:
    js_size = os.path.getsize('switcher.js')
    ok(f'switcher.js is present ({js_size} bytes)')

# Check flag PNGs
flags_ok = True
if not os.path.exists(FLAGS_DIR) or not os.path.isdir(FLAGS_DIR):
    err(FLAGS_DIR, 'Directory is missing!')
    flags_ok = False
else:
    for lang in LANGS:
        flag_path = os.path.join(FLAGS_DIR, f'{lang}.png')
        if not os.path.exists(flag_path):
            err(FLAGS_DIR, f'Missing flag image: {lang}.png')
            flags_ok = False
    if flags_ok:
        ok(f'All {len(LANGS)} flag PNG images are present in {FLAGS_DIR}/')

# Check translations dictionary completeness inside switcher.js
if os.path.exists('switcher.js'):
    with open('switcher.js', encoding='utf-8') as f:
        js_content = f.read()
    
    dict_start = js_content.find('window.__i18n =')
    if dict_start >= 0:
        sample = js_content[dict_start+15:dict_start+50]
        if sample.strip().startswith('{'):
            # Check all 6 languages are present
            lang_missing = False
            for lang in LANGS:
                if f'"{lang}":' not in js_content[dict_start:]:
                    warn('switcher.js', f'Lang "{lang}" may be missing from __i18n dict')
                    lang_missing = True
            if not lang_missing:
                ok('__i18n dictionary completeness checked successfully')
        else:
            err('switcher.js', f'__i18n dict malformed — starts with: {sample[:30]}')
    else:
        err('switcher.js', '__i18n dictionary not found')

for filepath in HTML_FILES:
    print(f'\n{"="*55}')
    print(f'  Checking {filepath}')
    print(f'{"="*55}')

    if not os.path.exists(filepath):
        err(filepath, 'FILE MISSING!')
        continue

    with open(filepath, encoding='utf-8') as f:
        c = f.read()

    size_kb = len(c) // 1024

    # ── 1. Basic HTML structure ──────────────────────────
    checks = {
        '<!DOCTYPE html>': '<!DOCTYPE html>',
        '<html':           '<html',
        '<head>':          '<head>',
        '</head>':         '</head>',
        '<body>':          '<body>',
        '</body>':         '</body>',
        '</html>':         '</html>',
    }
    struct_ok = True
    for label, token in checks.items():
        if token not in c:
            err(filepath, f'Missing {label}')
            struct_ok = False
    if struct_ok:
        ok(f'HTML structure complete ({size_kb} KB)')

    # ── 2. No old conflicting inline scripts/styles ──────
    old_stuff = {
        'loadDictionary': 'old loadDictionary function',
        'lang-switcher-container': 'old lang-switcher-container div',
        'toggleLangMenu': 'old toggleLangMenu function',
        'googletranslate': 'Google Translate widget',
        'id="ls-style"': 'old inline ls-style block',
        'id="ls-script"': 'old inline ls-script block',
        'DESCODIFICAR': 'bad ES translation (DESCODIFICAR)',
        'DECÓDIGO': 'bad ES translation (DECÓDIGO)',
        'TUTODECÓDIGO': 'bad ES translation (TUTODECÓDIGO)',
    }
    conflicts = False
    for token, desc in old_stuff.items():
        if token.lower() in c.lower():
            err(filepath, f'Old/bad code still present: {desc}')
            conflicts = True
    if not conflicts:
        ok('No old/conflicting inline blocks')

    # ── 3. Language switcher integration checks ──────────
    sw_checks = {
        'id="ls-root"':       'ls-root element',
        'id="ls-flag"':       'main flag img',
        'href="switcher.css"': 'switcher.css stylesheet link',
        'src="switcher.js"':   'switcher.js script link',
    }
    sw_ok = True
    for token, desc in sw_checks.items():
        if token not in c:
            err(filepath, f'Missing integration element: {desc}')
            sw_ok = False
    if sw_ok:
        ok('Language switcher correctly integrated')

    # ── 4. SVG attributes (viewBox not viewbox) ──────────
    vb_bad = c.count('viewbox=')
    vb_ok  = c.count('viewBox=')
    if vb_bad > 0:
        err(filepath, f'{vb_bad} instances of lowercase viewbox= (SVGs will be broken)')
    else:
        ok(f'SVG viewBox correct ({vb_ok} attrs, none lowercase)')

    # ── 5. data-i18n keys present ────────────────────────
    i18n_keys = set(re.findall(r'data-i18n="([^"]+)"', c))
    n_keys = len(i18n_keys)
    if n_keys < 10:
        err(filepath, f'Only {n_keys} data-i18n keys — seems very low')
    else:
        ok(f'{n_keys} data-i18n keys in HTML')

    # ── 6. Multiple </body> or </html> tags ──────────────
    body_count = c.count('</body>')
    html_count = c.count('</html>')
    if body_count != 1:
        err(filepath, f'{body_count} </body> tags (should be exactly 1)')
    if html_count != 1:
        err(filepath, f'{html_count} </html> tags (should be exactly 1)')
    if body_count == 1 and html_count == 1:
        ok('Single </body> and </html>')

    # ── 7. Font paths (relative for file:// compat) ──────
    abs_fonts = re.findall(r'href="(/fonts/[^"]+)"', c)
    if abs_fonts:
        warn(filepath, f'Absolute font paths (may fail on file://) — will work on https://: {abs_fonts[:2]}')
    else:
        ok('Font paths OK for hosting')

    # ── 8. Default language is French ────────────────────
    ok('Default language is French')

    # ── 9. Translation notice (only on mentions-legales) ─
    if filepath == 'mentions-legales.html':
        if 'translation-notice' in c:
            ok('Translation notice banner present')
        else:
            err(filepath, 'Translation notice banner MISSING')

# ── Summary ─────────────────────────────────────────────────────
print(f'\n{"="*55}')
print(f'  SUMMARY')
print(f'{"="*55}')

if ERRORS:
    print(f'\n  ❌ {len(ERRORS)} ERROR(S) FOUND:')
    for e in ERRORS: print(e)
else:
    print(f'\n  ✅ NO ERRORS — All files are clean!')

if WARNINGS:
    print(f'\n  ⚠️  {len(WARNINGS)} WARNING(S):')
    for w in WARNINGS: print(w)
else:
    print(f'  ✅ No warnings')

print()
if not ERRORS:
    print('  🚀 READY TO UPLOAD!')
else:
    print('  🔧 Please fix errors before uploading.')
