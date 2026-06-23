#!/usr/bin/env python3
"""
CLEAN FINAL: Strips ALL old switcher injections and refactors the language
switcher to be fully CSP-compliant. It generates external switcher.css,
switcher.js, and saves flags to a local flags/ directory as PNG files.
It modifies index.html, about.html, mentions-legales.html, and presse.html.
"""
import re
import os
import json
import base64

HTML_FILES = ['index.html']
LOCALES_DIR = 'locales'
FLAGS_DIR = 'flags'

# Ensure flags directory exists
os.makedirs(FLAGS_DIR, exist_ok=True)

# Load all dicts
all_dicts = {}
for lang in ['fr', 'en', 'es', 'de', 'ar', 'zh-CN']:
    with open(os.path.join(LOCALES_DIR, f'{lang}.json'), encoding='utf-8') as f:
        all_dicts[lang] = json.load(f)

dicts_js = '{' + ','.join(
    f'"{lang}":{json.dumps(all_dicts[lang], ensure_ascii=False, separators=(",",":"))}'
    for lang in ['fr', 'en', 'es', 'de', 'ar', 'zh-CN']
) + '}'

# Load Base64 flags and extract to PNG files
with open('b64_flags.json', encoding='utf-8') as f:
    b64_flags = json.load(f)

for lang, b64_str in b64_flags.items():
    if ',' in b64_str:
        b64_data = b64_str.split('base64,')[1]
    else:
        b64_data = b64_str
    
    file_path = os.path.join(FLAGS_DIR, f'{lang}.png')
    with open(file_path, 'wb') as out_f:
        out_f.write(base64.b64decode(b64_data))
print(f"Decoded all flags to {FLAGS_DIR}/ directory.")

# Generate switcher.css
CSS_CONTENT = """#ls-root{position:fixed;bottom:28px;right:28px;z-index:999999;display:flex;align-items:center}
#ls-main-btn{width:58px;height:58px;border-radius:50%;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.5),0 0 0 3px rgba(255,255,255,0.15);cursor:pointer;border:none;padding:0;background:none;transition:transform 0.25s,box-shadow 0.25s;position:relative;z-index:2;flex-shrink:0}
#ls-main-btn:hover{transform:scale(1.08);box-shadow:0 6px 28px rgba(0,0,0,0.6),0 0 0 3px rgba(255,255,255,0.3)}
#ls-main-btn img{width:100%;height:100%;object-fit:cover;border-radius:50%;display:block}
#ls-trail{position:absolute;right:62px;bottom:6px;height:46px;background:linear-gradient(to left,rgba(108,99,255,0.25) 0%,transparent 100%);border-radius:40px;pointer-events:none;width:0;transition:width 0.4s cubic-bezier(.4,0,.2,1),opacity 0.3s;opacity:0}
#ls-root.ls-open #ls-trail{width:340px;opacity:1}
#ls-cards{display:flex;align-items:center;position:absolute;right:64px;bottom:6px;flex-direction:row-reverse;pointer-events:none}
#ls-root.ls-open #ls-cards{pointer-events:auto}
.ls-card{width:46px;height:46px;border-radius:50%;overflow:hidden;border:2px solid rgba(255,255,255,0.12);box-shadow:0 3px 12px rgba(0,0,0,0.4);cursor:pointer;transition:transform 0.35s cubic-bezier(.34,1.56,.64,1),opacity 0.3s,margin-right 0.35s cubic-bezier(.4,0,.2,1);opacity:0;margin-right:-42px;transform:scale(0.5);background:rgba(10,10,20,0.9);flex-shrink:0}
.ls-card img{width:100%;height:100%;object-fit:cover;border-radius:50%;display:block}
.ls-card:hover{transform:scale(1.12)!important;border-color:rgba(108,99,255,0.9)!important;box-shadow:0 0 18px rgba(108,99,255,0.55)!important}
.ls-active{border-color:#6c63ff!important;box-shadow:0 0 14px rgba(108,99,255,0.7)!important}
#ls-root.ls-open .ls-card{opacity:1;transform:scale(1);margin-right:8px}
#ls-root.ls-open .ls-card:nth-child(6){transition-delay:0.00s}
#ls-root.ls-open .ls-card:nth-child(5){transition-delay:0.05s}
#ls-root.ls-open .ls-card:nth-child(4){transition-delay:0.10s}
#ls-root.ls-open .ls-card:nth-child(3){transition-delay:0.15s}
#ls-root.ls-open .ls-card:nth-child(2){transition-delay:0.20s}
#ls-root.ls-open .ls-card:nth-child(1){transition-delay:0.25s}
#ls-root:not(.ls-open) .ls-card:nth-child(6){transition-delay:0.25s}
#ls-root:not(.ls-open) .ls-card:nth-child(5){transition-delay:0.20s}
#ls-root:not(.ls-open) .ls-card:nth-child(4){transition-delay:0.15s}
#ls-root:not(.ls-open) .ls-card:nth-child(3){transition-delay:0.10s}
#ls-root:not(.ls-open) .ls-card:nth-child(2){transition-delay:0.05s}
#ls-root:not(.ls-open) .ls-card:nth-child(1){transition-delay:0.00s}"""

with open('switcher.css', 'w', encoding='utf-8') as f:
    f.write(CSS_CONTENT)
print("Generated switcher.css.")

# Generate switcher.js
JS_CONTENT = """window.__i18n = __DICTS_JS__;
(function(){
  var FLAGS_DATA = {
    "fr": "flags/fr.png",
    "en": "flags/en.png",
    "es": "flags/es.png",
    "de": "flags/de.png",
    "ar": "flags/ar.png",
    "zh-CN": "flags/zh-CN.png"
  };
  var open = false;

  var lsToggle = function(){
    open = !open;
    var root = document.getElementById('ls-root');
    if (root) root.classList.toggle('ls-open', open);
  };

  var lsSwitch = function(lang){
    var dict = window.__i18n && window.__i18n[lang];
    if(!dict){console.warn('No i18n for '+lang);return;}
    document.querySelectorAll('[data-i18n]').forEach(function(el){
      var k = el.getAttribute('data-i18n');
      if(dict[k] !== undefined) el.innerHTML = dict[k];
    });
    var flagEl = document.getElementById('ls-flag');
    if (flagEl) flagEl.src = FLAGS_DATA[lang] || '';
    document.querySelectorAll('.ls-card').forEach(function(btn){
      btn.classList.toggle('ls-active', btn.dataset.lang === lang);
    });
    document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
    document.documentElement.setAttribute('lang', lang);
    open = false;
    var root = document.getElementById('ls-root');
    if (root) root.classList.remove('ls-open');
  };

  function init() {
    var mainBtn = document.getElementById('ls-main-btn');
    if (mainBtn) {
      mainBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        lsToggle();
      });
    }

    document.querySelectorAll('.ls-card').forEach(function(btn) {
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        var lang = btn.getAttribute('data-lang');
        lsSwitch(lang);
      });
    });

    document.addEventListener('click', function(e) {
      var r = document.getElementById('ls-root');
      if (open && r && !r.contains(e.target)) {
        open = false;
        r.classList.remove('ls-open');
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();"""

JS_CONTENT = JS_CONTENT.replace('__DICTS_JS__', dicts_js)

with open('switcher.js', 'w', encoding='utf-8') as f:
    f.write(JS_CONTENT)
print("Generated switcher.js.")

# HTML clean switcher markup
HTML_BLOCK = """<div id="ls-root">
  <div id="ls-trail"></div>
  <div id="ls-cards">
    <button class="ls-card" data-lang="zh-CN" title="中文"><img src="flags/zh-CN.png" alt="中文"></button>
    <button class="ls-card" data-lang="ar"    title="العربية"><img src="flags/ar.png" alt="العربية"></button>
    <button class="ls-card" data-lang="de"    title="Deutsch"><img src="flags/de.png" alt="Deutsch"></button>
    <button class="ls-card" data-lang="es"    title="Español"><img src="flags/es.png" alt="Español"></button>
    <button class="ls-card" data-lang="en"    title="English"><img src="flags/en.png" alt="English"></button>
    <button class="ls-card ls-active" data-lang="fr" title="Français"><img src="flags/fr.png" alt="Français"></button>
  </div>
  <button id="ls-main-btn" aria-label="Choisir la langue">
    <img id="ls-flag" src="flags/fr.png" alt="Langue">
  </button>
</div>
<script src="switcher.js" defer></script>"""

# Patterns to strip EVERYTHING old
STRIP = [
    r'<!-- ===== LANGUAGE SWITCHER PREMIUM ===== -->.*?<!-- ===== END LANGUAGE SWITCHER PREMIUM ===== -->',
    r'<!-- ===== LANGUAGE SWITCHER.*?<!-- ===== END LANGUAGE SWITCHER ===== -->',
    r'<!-- Offline Privacy-First Language Switcher -->.*?</script>',
    r'<!-- Google Translate Widget.*?</script>',
    r'<script id="ls-script">.*?</script>',
    r'<style id="ls-style">.*?</style>',
    r'<div id="ls-root">.*?</div>\s*\n\s*\n',
    r'<script>\s*/\* i18n:.*?</script>',
    r'<script>\s*/\* All 259 strings.*?</script>',
    r'<script>\s*window\.__i18n=\{.*?</script>',
    r'\n?\s*<script>\s*const flags = \{.*?</script>',
    r'\n?\s*<style>\s*\.lang-switcher-container\{.*?</style>',
]

for filepath in HTML_FILES:
    if not os.path.exists(filepath):
        print(f'MISSING: {filepath}')
        continue

    with open(filepath, encoding='utf-8') as f:
        content = f.read()

    # Strip all old switcher code
    for pat in STRIP:
        content = re.sub(pat, '', content, flags=re.DOTALL)

    # Remove any existing references to switcher.css / switcher.js to avoid double inclusion
    content = content.replace('<link rel="stylesheet" href="switcher.css">', '')
    content = content.replace('<script src="switcher.js" defer></script>', '')

    # Fix viewBox (BS4 lowercased it in previous workflows)
    content = content.replace('viewbox=', 'viewBox=')

    # Clean up blank lines
    content = re.sub(r'\n{4,}', '\n\n', content)

    # Inject switcher.css link in <head>
    if '</head>' in content:
        content = content.replace('</head>', '<link rel="stylesheet" href="switcher.css">\n</head>', 1)
    
    # Inject HTML block and script src before </body>
    if '</body>' in content:
        content = content.replace('</body>', HTML_BLOCK + '\n</body>', 1)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    # Verify
    has_css_link = 'switcher.css' in content
    has_js_link  = 'switcher.js' in content
    has_root     = 'id="ls-root"' in content
    old_gone     = 'lang-switcher-container' not in content and 'loadDictionary' not in content
    print(f'✅ {filepath}: css_link={has_css_link} js_link={has_js_link} root={has_root} old_gone={old_gone}')

print('\nDone!')
