#!/usr/bin/env python3
"""Frame raw simulator screenshots for the App Store.

Reads fastlane/screenshots/raw/NN-name.png (1320x2868, iPhone 17 Pro Max),
writes fastlane/screenshots/en-GB/iphone69_NN_name.png at the same size:
Observatory ground, a headline + subline at the top (Apple indexes caption
text, so each headline carries a search term), the screen below with rounded
corners and a soft glow.

    python3 fastlane/compose_screenshots.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent / "screenshots"
RAW, OUT = ROOT / "raw", ROOT / "en-GB"
W, H = 1320, 2868

# name -> (headline, subline). Headlines lead with the keyword.
CAPTIONS = {
    "01-home": ("See what's filling\nyour Photos library", "Screenshots, Live Photos, bursts, videos — with the biggest win first"),
    "02-videos": ("Free up space\nwithout the guesswork", "Largest first, running total, nothing deleted until you say so"),
    "03-review": ("Delete safely —\n30 days to undo", "Everything goes to Recently Deleted in Photos, never straight to gone"),
    "04-bursts": ("Duplicates and bursts,\ngrouped for you", "Keep the best shot from each burst and clear the rest in one tap"),
    "05-calculator": ("Could you drop\nan iCloud tier?", "Type in your plan and usage — the app never reads it for you"),
}

GROUND_TOP, GROUND_BOTTOM = (14, 21, 38), (5, 7, 13)
ACCENT = (124, 196, 255)
TEXT, MUTED = (242, 244, 248), (154, 163, 181)


def font(size, weight="Bold"):
    for path in (f"/System/Library/Fonts/SFCompact.ttf", "/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Supplemental/Arial {weight}.ttf".replace(" Regular", "")):
        try:
            f = ImageFont.truetype(path, size)
            try:
                f.set_variation_by_name(weight)
            except (OSError, AttributeError):
                pass
            return f
        except OSError:
            continue
    return ImageFont.load_default()


def ground():
    img = Image.new("RGB", (W, H), GROUND_TOP)
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        px_row = tuple(round(a + (b - a) * t) for a, b in zip(GROUND_TOP, GROUND_BOTTOM))
        for x in range(W):
            px[x, y] = px_row
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W // 2 - 700, 250, W // 2 + 700, 1650), fill=(40, 70, 120))
    glow = glow.filter(ImageFilter.GaussianBlur(260))
    return Image.blend(img, Image.composite(glow, img, glow.convert("L").point(lambda v: min(255, v * 2))), 0.55)


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def draw_centered(draw, text, y, fnt, fill, spacing):
    for line in text.split("\n"):
        w = draw.textlength(line, font=fnt)
        draw.text(((W - w) / 2, y), line, font=fnt, fill=fill)
        y += fnt.size + spacing
    return y


def compose(name, headline, subline):
    screen = Image.open(RAW / f"{name}.png").convert("RGB")
    canvas = ground()
    draw = ImageDraw.Draw(canvas)

    y = draw_centered(draw, headline, 150, font(96, "Bold"), TEXT, 14)
    draw_centered(draw, subline, y + 26, font(36, "Medium"), MUTED, 8)

    # Screen: scaled to 84% width, sitting below the caption, bottom cropped by the canvas edge.
    scale = 0.84
    sw, sh = round(W * scale), round(H * scale)
    screen = screen.resize((sw, sh), Image.LANCZOS)
    radius = 110
    x, top = (W - sw) // 2, 560

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x - 20, top + 20, x + sw + 20, top + sh + 60), radius=radius + 20, fill=(0, 0, 0, 170))
    shadow = shadow.filter(ImageFilter.GaussianBlur(60))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    frame = Image.new("RGBA", (sw + 8, sh + 8), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle((0, 0, sw + 7, sh + 7), radius=radius + 4, fill=(255, 255, 255, 40))
    canvas.alpha_composite(frame, (x - 4, top - 4))

    screen_rgba = screen.convert("RGBA")
    screen_rgba.putalpha(rounded_mask((sw, sh), radius))
    canvas.alpha_composite(screen_rgba, (x, top))
    canvas = canvas.crop((0, 0, W, H)).convert("RGB")
    return canvas


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("iphone69_*.png"):
        old.unlink()
    for name, (headline, subline) in CAPTIONS.items():
        out = OUT / f"iphone69_{name.replace('-', '_')}.png"
        compose(name, headline, subline).save(out, optimize=True)
        print(out.name)


if __name__ == "__main__":
    main()
