#!/usr/bin/env python3
"""Images des installateurs (DMG macOS, Inno Setup Windows) aux couleurs TUTODECODE.
Régénérer : python3 installer-art/generer.py  (nécessite Pillow ; résultats commités)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "installer-art"
BEIGE, NOIR, GRIS = (245, 235, 218), (17, 17, 17), (110, 102, 92)
FONTS = ROOT / "assets/fonts"
ICON = Image.open(ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png").convert("RGBA")

def font(name, size):
    return ImageFont.truetype(str(FONTS / f"Aileron-{name}.otf"), size)

def centre(d, y, txt, f, fill, w):
    l, _, r, _ = d.textbbox((0, 0), txt, font=f)
    d.text(((w - (r - l)) / 2 - l, y), txt, font=f, fill=fill)

def dmg(scale):
    w, h = 660 * scale, 400 * scale
    im = Image.new("RGB", (w, h), BEIGE)
    d = ImageDraw.Draw(im)
    centre(d, 34 * scale, "Installer T2DECODE", font("Bold", 30 * scale), NOIR, w)
    centre(d, 78 * scale, "Glisse l'application dans le dossier Applications", font("Regular", 15 * scale), GRIS, w)
    # flèche entre les icônes (centres à x=170 et x=490, y=215)
    y, x0, x1 = 215 * scale, 262 * scale, 398 * scale
    d.line((x0, y, x1 - 14 * scale, y), fill=NOIR, width=4 * scale)
    d.polygon([(x1, y), (x1 - 20 * scale, y - 12 * scale), (x1 - 20 * scale, y + 12 * scale)], fill=NOIR)
    centre(d, 358 * scale, "Association TUTODECODE · logiciel libre · sans télémétrie", font("Regular", 12 * scale), GRIS, w)
    im.save(OUT / (f"dmg-fond@{scale}x.png" if scale > 1 else "dmg-fond.png"), dpi=(72 * scale, 72 * scale))

def arrondi(img, r):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), r, fill=255)
    img = img.copy(); img.putalpha(Image.composite(img.getchannel("A"), m, m)); return img

def wizard(w, h):
    im = Image.new("RGB", (w, h), NOIR)
    d = ImageDraw.Draw(im)
    s = int(w * 0.62)
    ic = arrondi(ICON.resize((s, s), Image.LANCZOS), s // 5)
    im.paste(ic, ((w - s) // 2, int(h * 0.22)), ic)
    centre(d, int(h * 0.22) + s + int(h * 0.05), "T2DECODE", font("Bold", int(w * 0.14)), BEIGE, w)
    centre(d, int(h * 0.88), "TUTODECODE", font("Regular", int(w * 0.075)), (200, 190, 172), w)
    im.save(OUT / f"windows-assistant-{w}x{h}.bmp")

def petite(n):
    im = Image.new("RGB", (n, n), (255, 255, 255))
    ic = ICON.resize((n, n), Image.LANCZOS)
    im.paste(ic, (0, 0), ic)
    im.save(OUT / f"windows-icone-{n}.bmp")

for sc in (1, 2):
    dmg(sc)
# fond Retina (1x + 2x dans un seul TIFF) : macOS seulement
import subprocess
subprocess.run(["tiffutil", "-cathidpicheck", str(OUT / "dmg-fond.png"), str(OUT / "dmg-fond@2x.png"),
                "-out", str(OUT / "dmg-fond.tiff")], check=True)
(OUT / "dmg-fond.png").unlink(); (OUT / "dmg-fond@2x.png").unlink()
for w, h in ((164, 314), (328, 628)):
    wizard(w, h)
for n in (55, 110):
    petite(n)
print("ok")
