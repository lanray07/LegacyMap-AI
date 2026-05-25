from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "AppStoreScreenshots"
W, H = 1242, 2688

CHARCOAL = (20, 20, 19)
INK = (39, 36, 32)
PARCHMENT = (222, 205, 164)
PAPER = (238, 228, 203)
STONE = (130, 129, 121)
GOLD = (194, 151, 74)
MOSS = (69, 88, 72)
SIGNAL = (62, 119, 131)
WHITE = (250, 246, 235)


def font(size, weight="regular"):
    candidates = {
        "regular": [
            "C:/Windows/Fonts/segoeui.ttf",
            "C:/Windows/Fonts/georgia.ttf",
            "C:/Windows/Fonts/arial.ttf",
        ],
        "semibold": [
            "C:/Windows/Fonts/seguisb.ttf",
            "C:/Windows/Fonts/georgiab.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
        "bold": [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/georgiab.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
    }
    for path in candidates.get(weight, candidates["regular"]):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


F = {
    "brand": font(38, "semibold"),
    "hero": font(82, "bold"),
    "hero_small": font(66, "bold"),
    "sub": font(38, "regular"),
    "label": font(28, "semibold"),
    "body": font(30, "regular"),
    "small": font(24, "regular"),
    "tiny": font(20, "regular"),
    "phone_title": font(30, "semibold"),
    "phone_body": font(24, "regular"),
    "phone_small": font(19, "regular"),
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def rounded(draw, xy, r, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def wrap(draw, text, max_width, fnt):
    words = text.split()
    lines = []
    line = ""
    for word in words:
        test = word if not line else f"{line} {word}"
        if draw.textlength(test, font=fnt) <= max_width:
            line = test
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def draw_text(draw, xy, text, fnt, fill, max_width=None, line_gap=10, anchor=None):
    x, y = xy
    if not max_width:
        draw.text((x, y), text, font=fnt, fill=fill, anchor=anchor)
        return y + fnt.size
    for line in wrap(draw, text, max_width, fnt):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += fnt.size + line_gap
    return y


def background(seed):
    random.seed(seed)
    img = Image.new("RGB", (W, H), CHARCOAL)
    pix = img.load()
    for y in range(H):
        t = y / H
        base = lerp((17, 17, 16), (49, 45, 38), t)
        for x in range(W):
            edge = abs(x - W / 2) / (W / 2)
            shade = int(16 * edge + 8 * math.sin((x + y) / 155))
            pix[x, y] = tuple(max(0, min(255, c - shade)) for c in base)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for y in range(0, H, 14):
        alpha = 15 if (y // 14) % 2 == 0 else 8
        od.line([(0, y), (W, y + 8)], fill=(PAPER[0], PAPER[1], PAPER[2], alpha), width=1)
    for _ in range(5200):
        x = random.randrange(W)
        y = random.randrange(H)
        a = random.randrange(8, 24)
        od.point((x, y), fill=(PAPER[0], PAPER[1], PAPER[2], a))
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def draw_brand(draw):
    draw.text((82, 76), "LegacyMap AI", font=F["brand"], fill=PARCHMENT)
    draw.line((82, 132, 254, 132), fill=GOLD, width=3)


def draw_headline(draw, headline, subtitle):
    hero_font = F["hero"] if len(headline) < 24 else F["hero_small"]
    draw_text(draw, (82, 190), headline, hero_font, WHITE, max_width=1010, line_gap=6)
    draw_text(draw, (86, 390), subtitle, F["sub"], PARCHMENT, max_width=980, line_gap=9)


def phone_frame(base, x, y, w=760, h=1460):
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    rounded(sd, (x - 10, y + 24, x + w + 10, y + h + 44), 74, (0, 0, 0, 115))
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    layer = Image.alpha_composite(layer, shadow)
    d = ImageDraw.Draw(layer)
    rounded(d, (x, y, x + w, y + h), 72, (8, 8, 8), outline=(82, 76, 65), width=5)
    rounded(d, (x + 26, y + 26, x + w - 26, y + h - 26), 50, (25, 24, 22), outline=(65, 60, 50), width=2)
    rounded(d, (x + 285, y + 38, x + 475, y + 66), 18, (8, 8, 8))
    base.alpha_composite(layer)
    return (x + 42, y + 88, w - 84, h - 148)


def phone_top(draw, rect, title, subtitle=None):
    x, y, w, _ = rect
    draw.text((x, y), "9:41", font=F["phone_small"], fill=PARCHMENT)
    draw.text((x + w - 112, y), "LTE 100%", font=F["phone_small"], fill=PARCHMENT)
    draw.text((x, y + 54), title, font=F["phone_title"], fill=WHITE)
    if subtitle:
        draw.text((x, y + 90), subtitle, font=F["phone_small"], fill=(189, 174, 139))


def phone_card(draw, xy, size, title, detail, accent=GOLD, icon=None):
    x, y = xy
    w, h = size
    rounded(draw, (x, y, x + w, y + h), 24, (40, 38, 34), outline=(92, 82, 62), width=1)
    if icon:
        rounded(draw, (x + 22, y + 22, x + 72, y + 72), 14, tuple(max(0, c - 25) for c in accent))
        draw.text((x + 38, y + 34), icon, font=F["phone_small"], fill=WHITE, anchor="mm")
        tx = x + 92
    else:
        tx = x + 24
    draw.text((tx, y + 22), title, font=F["label"], fill=WHITE)
    draw_text(draw, (tx, y + 60), detail, F["phone_body"], (204, 190, 158), max_width=w - (tx - x) - 24, line_gap=4)


def draw_map(draw, rect):
    x, y, w, h = rect
    rounded(draw, (x, y, x + w, y + h), 28, (47, 53, 45), outline=(96, 88, 66), width=2)
    for i in range(9):
        yy = y + 40 + i * 86
        draw.line((x + 25, yy, x + w - 25, yy + 35), fill=(80, 90, 75), width=3)
    for i in range(7):
        xx = x + 50 + i * 90
        draw.line((xx, y + 25, xx + 55, y + h - 25), fill=(70, 79, 68), width=2)
    for px, py, name in [(0.52, 0.36, "Hart"), (0.32, 0.58, "Reed"), (0.69, 0.65, "Vale"), (0.44, 0.78, "Ames")]:
        cx = x + int(px * w)
        cy = y + int(py * h)
        draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), fill=GOLD)
        draw.text((cx + 20, cy - 12), name, font=F["phone_small"], fill=WHITE)
    draw.line((x + 92, y + h - 100, x + 260, y + h - 180, x + 410, y + h - 250), fill=(232, 210, 120), width=7)


def draw_scanner(draw, rect):
    x, y, w, h = rect
    rounded(draw, (x, y, x + w, y + h), 28, (54, 54, 51), outline=(92, 82, 62), width=2)
    stone = (x + 150, y + 110, x + w - 150, y + h - 80)
    rounded(draw, stone, 42, (112, 110, 103), outline=(162, 158, 142), width=3)
    sx1, sy1, sx2, sy2 = stone
    draw.rectangle((sx1 + 36, sy1 + 92, sx2 - 36, sy1 + 100), fill=(86, 84, 78))
    lines = ["IN MEMORY", "ELEANOR HART", "1884 - 1912", "BELOVED MOTHER"]
    for i, line in enumerate(lines):
        draw.text((x + w / 2, sy1 + 130 + i * 70), line, font=F["phone_title"], fill=(73, 71, 66), anchor="mm")
    scan_y = sy1 + 210
    draw.rectangle((sx1 + 28, scan_y, sx2 - 28, scan_y + 8), fill=(236, 213, 123))
    rounded(draw, (x + 58, y + 55, x + w - 58, y + h - 45), 38, (0, 0, 0, 0), outline=(236, 213, 123), width=4)


def screen_dashboard(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Dashboard", "Preservation overview")
    phone_card(draw, (x, y + 140), (w, 170), "Nearby cemeteries", "4 historic sites mapped within walking distance.", SIGNAL, "*")
    for i, (title, value) in enumerate([("Memorials", "128"), ("Records", "42"), ("Requests", "9")]):
        cx = x + i * (w // 3) + 6
        phone_card(draw, (cx, y + 340), (w // 3 - 12, 150), title, value, GOLD)
    phone_card(draw, (x, y + 520), (w, 190), "Recently discovered", "Eleanor Hart | possible inscription captured from weathered stone.", MOSS, "+")
    phone_card(draw, (x, y + 740), (w, 190), "Volunteer nearby", "Cleaning, photo documentation, record digitization.", GOLD, "!")
    draw_text(draw, (x + 6, y + 990), "Find Grave   Scan Headstone   Add Memorial", F["phone_body"], PARCHMENT, max_width=w - 12)


def screen_map(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Cemetery Explorer", "GPS plots and walking context")
    draw_map(draw, (x, y + 130, w, 620))
    phone_card(draw, (x, y + 790), (w, 170), "Surname search", "Hart family line placeholder | 1880-1930.", SIGNAL, "?")
    phone_card(draw, (x, y + 990), (w, 150), "Walking directions", "Route guidance to saved grave markers.", GOLD, ">")


def screen_scan(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Headstone Scanner", "AI-assisted OCR placeholder")
    draw_scanner(draw, (x, y + 130, w, 600))
    phone_card(draw, (x, y + 770), (w, 170), "Possible inscription", "In loving memory of Eleanor Hart...", GOLD, "\"")
    phone_card(draw, (x, y + 965), (w, 170), "Likely surname", "Hart | estimated date range 1880-1930.", SIGNAL, "~")
    phone_card(draw, (x, y + 1160), (w, 150), "Preservation note", "Document first. Avoid abrasive cleaning.", MOSS, "i")


def screen_memorial(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Memorial Page", "Photos, notes, links")
    phone_card(draw, (x, y + 132), (w, 180), "Eleanor Hart", "1884-1912 | Highgate Cemetery", GOLD)
    draw_map(draw, (x, y + 340, w, 330))
    phone_card(draw, (x, y + 700), (w, 180), "Inscription", "Possible text saved with human review notes.", SIGNAL, "\"")
    phone_card(draw, (x, y + 905), (w, 180), "Family links", "Relationship placeholders require verification.", MOSS, "+")
    phone_card(draw, (x, y + 1110), (w, 150), "Tributes", "Flowers and memorial notes placeholder.", GOLD, "*")


def screen_digitizer(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Record Digitizer", "Archive OCR workflow")
    rounded(draw, (x, y + 130, x + w, y + 500), 28, (225, 213, 184), outline=(155, 130, 82), width=2)
    for i, line in enumerate(["Death Register", "Full name: ______", "Birth year: ____", "Death year: ____", "Cemetery: ______"]):
        draw.text((x + 54, y + 185 + i * 58), line, font=F["phone_title"] if i == 0 else F["phone_body"], fill=INK)
    phone_card(draw, (x, y + 535), (w, 190), "Manual correction", "Review OCR fields before saving or exporting.", GOLD, "p")
    phone_card(draw, (x, y + 750), (w, 190), "Digitized record", "Local SwiftData storage works offline.", SIGNAL, "d")
    phone_card(draw, (x, y + 965), (w, 170), "PDF export", "Share a clean archival report.", MOSS, "e")


def screen_family(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Family Engine", "Verified links stay in your hands")
    rounded(draw, (x, y + 155, x + w, y + 520), 28, (42, 39, 35), outline=(96, 88, 66), width=2)
    nodes = [(x + 335, y + 220), (x + 180, y + 365), (x + 490, y + 365), (x + 335, y + 470)]
    for a, b in [(0, 1), (0, 2), (1, 3), (2, 3)]:
        draw.line((nodes[a][0], nodes[a][1], nodes[b][0], nodes[b][1]), fill=(151, 134, 92), width=4)
    for i, (nx, ny) in enumerate(nodes):
        draw.ellipse((nx - 42, ny - 42, nx + 42, ny + 42), fill=GOLD if i == 0 else MOSS)
    phone_card(draw, (x, y + 560), (w, 180), "Saved surnames", "Hart, Reed, Vale.", GOLD, "s")
    phone_card(draw, (x, y + 765), (w, 190), "Possible match", "Nearby surname match. Verify before linking.", SIGNAL, "~")
    phone_card(draw, (x, y + 980), (w, 170), "Generations", "Build collections without unsupported claims.", MOSS, "+")


def screen_volunteer(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Volunteer System", "Coordinate restoration carefully")
    for i, (title, detail) in enumerate([
        ("Cleaning", "Open request | notes attached"),
        ("Photo documentation", "Before and after placeholders"),
        ("Record digitization", "Archive volunteers needed"),
        ("Stone repair placeholder", "Expert review required"),
    ]):
        phone_card(draw, (x, y + 145 + i * 205), (w, 175), title, detail, [GOLD, SIGNAL, MOSS, STONE][i], "!")
    phone_card(draw, (x, y + 990), (w, 170), "Reminder", "Local notifications for restoration follow-up.", GOLD, "r")


def screen_story(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "AI Story Generator", "Respectful summaries")
    phone_card(draw, (x, y + 135), (w, 240), "Memorial summary", "Eleanor Hart is remembered through a memorial recorded at Highgate Cemetery. The saved inscription may help researchers reconnect this grave with local history.", GOLD, "\"")
    phone_card(draw, (x, y + 405), (w, 220), "Historical overview", "Compare dates with verified local histories, church records, and cemetery archives.", SIGNAL, "i")
    phone_card(draw, (x, y + 655), (w, 190), "No fictional claims", "AI does not invent genealogy facts or legal identity verification.", MOSS, "!")
    phone_card(draw, (x, y + 875), (w, 170), "Cautious wording", "Possible, estimated, likely, and requires review.", GOLD, "~")


def screen_pdf(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "PDF Export", "Share memorial reports")
    rounded(draw, (x + 70, y + 140, x + w - 70, y + 900), 18, PAPER, outline=(153, 125, 74), width=3)
    draw.text((x + 112, y + 190), "LegacyMap AI Report", font=F["phone_title"], fill=INK)
    draw.line((x + 112, y + 240, x + w - 112, y + 240), fill=GOLD, width=4)
    for i, line in enumerate(["Memorial summary", "Cemetery map snapshot", "Inscription text", "Grave photos", "Historical notes", "Family links placeholder"]):
        draw.text((x + 112, y + 300 + i * 72), line, font=F["phone_body"], fill=INK)
    phone_card(draw, (x, y + 940), (w, 180), "Native share sheet", "Export and share a polished preservation file.", GOLD, "e")


def screen_paywall(draw, rect):
    x, y, w, _ = rect
    phone_top(draw, rect, "Premium Heritage", "More preservation tools")
    for i, (title, price, detail, accent) in enumerate([
        ("Free", "GBP 0", "Basic search, limited scans, 7-day history.", STONE),
        ("Premium Monthly", "GBP 9.99", "Unlimited scans, AI summaries, PDF exports.", GOLD),
        ("Premium Yearly", "GBP 79.99", "Best value for family archives.", SIGNAL),
        ("Heritage Pro", "GBP 24.99", "Cemetery management and volunteer coordination placeholders.", MOSS),
    ]):
        phone_card(draw, (x, y + 135 + i * 220), (w, 190), f"{title}  {price}", detail, accent, "*")


SCREENS = [
    ("01_preserve_the_past.png", "Preserve the past", "Map cemeteries, save memorials, and reconnect forgotten stories.", screen_dashboard),
    ("02_gps_cemetery_maps.png", "Navigate history", "GPS cemetery maps, plot markers, surname search, and walking context.", screen_map),
    ("03_ai_headstone_scanner.png", "Read weathered stones", "AI-assisted OCR uses cautious possible inscriptions and estimated dates.", screen_scan),
    ("04_memorial_pages.png", "Build memorial pages", "Photos, inscriptions, notes, tributes, and verified family placeholders.", screen_memorial),
    ("05_death_record_digitizer.png", "Digitize old records", "Photograph archive documents, correct OCR, and save structured history.", screen_digitizer),
    ("06_family_connection_engine.png", "Connect family lines", "Save surnames, link relatives, and verify generations independently.", screen_family),
    ("07_volunteer_restoration.png", "Coordinate restoration", "Report neglected graves and organize respectful volunteer tasks.", screen_volunteer),
    ("08_ai_story_generator.png", "Generate careful stories", "Respectful summaries without fictional genealogy claims.", screen_story),
    ("09_pdf_memorial_export.png", "Export archival PDFs", "Create clean memorial reports with maps, notes, photos, and disclaimers.", screen_pdf),
    ("10_premium_tools.png", "Unlock heritage tools", "Premium scans, AI summaries, memorial collections, and PDF exports.", screen_paywall),
]


def add_footer(draw):
    rounded(draw, (82, H - 178, W - 82, H - 92), 28, (36, 34, 31), outline=(91, 78, 54), width=1)
    draw.text((116, H - 150), "Informational historical tool only. OCR and genealogy links require review.", font=F["small"], fill=(205, 190, 154))


def compose(idx, filename, headline, subtitle, renderer):
    img = background(idx)
    draw = ImageDraw.Draw(img)
    draw_brand(draw)
    draw_headline(draw, headline, subtitle)
    rect = phone_frame(img, 241, 760)
    draw = ImageDraw.Draw(img)
    renderer(draw, rect)
    add_footer(draw)
    img.save(OUT / filename, "PNG", optimize=True)


def main():
    OUT.mkdir(exist_ok=True)
    for idx, item in enumerate(SCREENS, start=1):
        compose(idx, *item)
    print(f"Generated {len(SCREENS)} screenshots in {OUT}")


if __name__ == "__main__":
    main()
