#!/usr/bin/env python3
"""Builds assets/data/arabic_letters.json (all 28 Arabic letters).

The finger-tracing guide of every letter is NOT drawn by hand: it is the centre line
(skeleton) of the real glyph, so the shape the child traces is the shape of the letter.
Run from the project root:   python3 tool/build_letters.py
Needs: Pillow (with raqm), numpy, scikit-image and the FreeSerif Bold font
(Debian/Ubuntu: apt install fonts-freefont-ttf).
Then look at docs/letters_preview.png: every guide (colored) must sit on the grey letter.
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from skimage.morphology import skeletonize
from skimage.measure import label, regionprops

FONT = os.environ.get("LETTER_FONT", "/usr/share/fonts/truetype/freefont/FreeSerifBold.ttf")
N = 700

def render(ch):
    f = ImageFont.truetype(FONT, 520, layout_engine=ImageFont.Layout.RAQM)
    img = Image.new("L", (N*2, N*2), 0)
    d = ImageDraw.Draw(img)
    d.text((N, N), ch, font=f, fill=255, anchor="mm", features=["-liga"], language="ar")
    return np.array(img) > 127

def bbox(mask):
    ys, xs = np.nonzero(mask)
    return xs.min(), ys.min(), xs.max(), ys.max()

NB = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]

def build_graph(sk):
    pix = set(zip(*np.nonzero(sk)))
    adj = {p: [] for p in pix}
    for (y,x) in pix:
        for dy,dx in NB:
            q = (y+dy, x+dx)
            if q in pix: adj[(y,x)].append(q)
    return adj

def prune(adj, minlen):
    changed = True
    while changed:
        changed = False
        ends = [p for p,n in adj.items() if len(n) == 1]
        for e in ends:
            if e not in adj or len(adj[e]) != 1: continue
            path = [e]; prev = None; cur = e
            while True:
                nxt = [q for q in adj[cur] if q != prev and q not in path]
                if len(adj[cur]) >= 3 and cur != e: break
                if not nxt: break
                prev, cur = cur, nxt[0]; path.append(cur)
                if len(path) > minlen: break
            if len(path) <= minlen and len(adj[cur]) >= 3:
                for p in path[:-1]:
                    for q in adj[p]:
                        if q in adj and p in adj[q]: adj[q].remove(p)
                    del adj[p]
                changed = True
    return adj

def bfs(adj, src):
    dist = {src: 0}; par = {src: None}; q = [src]; i = 0
    while i < len(q):
        c = q[i]; i += 1
        for n in adj[c]:
            if n not in dist:
                dist[n] = dist[c] + 1; par[n] = c; q.append(n)
    return dist, par

def components(adj):
    seen = set(); out = []
    for p in adj:
        if p in seen: continue
        comp = set([p]); st = [p]
        while st:
            c = st.pop()
            for n in adj[c]:
                if n not in comp: comp.add(n); st.append(n)
        seen |= comp; out.append(comp)
    return out

def extract_paths(adj, minpix):
    paths = []
    adj = {p: list(n) for p, n in adj.items()}
    while True:
        comps = [c for c in components(adj) if len(c) >= minpix]
        if not comps: break
        comp = max(comps, key=len)
        a = next(iter(comp))
        d1, _ = bfs(adj, a); far = max(comp, key=lambda p: d1[p])
        d2, par = bfs(adj, far); far2 = max(comp, key=lambda p: d2[p])
        path = []; c = far2
        while c is not None: path.append(c); c = par[c]
        paths.append(path)
        used = set(path)
        for p in used:
            for q in adj[p]:
                if q not in used and p in adj[q]: adj[q].remove(p)
        for p in used: del adj[p]
        adj = {p: [q for q in n if q in adj] for p, n in adj.items()}
        if len(paths) > 6: break
    return paths

def rdp(pts, eps):
    if len(pts) < 3: return pts
    a = np.array(pts[0]); b = np.array(pts[-1])
    ab = b - a; L = np.linalg.norm(ab)
    best = -1; bi = 0
    for i in range(1, len(pts)-1):
        p = np.array(pts[i])
        dist = np.linalg.norm(p - a) if L == 0 else abs(ab[0]*(a[1]-p[1]) - ab[1]*(a[0]-p[0]))/L
        if dist > best: best = dist; bi = i
    if best > eps:
        l = rdp(pts[:bi+1], eps); r = rdp(pts[bi:], eps)
        return l[:-1] + r
    return [pts[0], pts[-1]]

def analyze(ch, margin=0.08, eps=0.012):
    m = render(ch)
    x0,y0,x1,y1 = bbox(m)
    w = x1-x0+1; h = y1-y0+1
    s = (1-2*margin)/max(w,h)
    ox = 0.5 - (x0 + w/2)*s; oy = 0.5 - (y0 + h/2)*s
    def norm(y,x): return (round(x*s+ox,3), round(y*s+oy,3))
    lab = label(m, connectivity=2)
    props = sorted(regionprops(lab), key=lambda r: -r.area)
    main = props[0]
    dots = []
    body = (lab == main.label)
    for r in props[1:]:
        if r.area < main.area*0.35:
            cy,cx = r.centroid; dots.append(norm(cy,cx))
        else:
            body |= (lab == r.label)
    sk = skeletonize(body)
    adj = build_graph(sk)
    size = max(w,h)
    adj = prune(adj, int(size*0.06))
    paths = extract_paths(adj, int(size*0.07))
    strokes = []
    for path in paths:
        pts = [norm(y,x) for (y,x) in path]
        pts = rdp(pts, eps)
        # start at the right end (Arabic writing direction), top first on ties
        if (pts[0][0], -pts[0][1]) < (pts[-1][0], -pts[-1][1]): pts = pts[::-1]
        strokes.append(pts)
    strokes.sort(key=lambda p: -p[0][0])
    dots.sort(key=lambda p: (-p[0], p[1]))
    return strokes, dots, m, (s, ox, oy)

def catmull(pts, steps=8):
    if len(pts) < 3: return list(pts)
    out = []
    for i in range(len(pts)-1):
        p0 = pts[i-1] if i > 0 else pts[i]; p1 = pts[i]; p2 = pts[i+1]
        p3 = pts[i+2] if i+2 < len(pts) else pts[i+1]
        for k in range(steps):
            t = k/steps; t2=t*t; t3=t2*t
            f = lambda a,b,c,d: 0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t2+(-a+3*b-3*c+d)*t3)
            out.append((f(p0[0],p1[0],p2[0],p3[0]), f(p0[1],p1[1],p2[1],p3[1])))
    out.append(pts[-1]); return out


MIN_STROKE_LEN = 0.10   # shorter skeleton pieces are noise (spurs), not part of the letter

def stroke_len(pts):
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))

def trace_for(ch):
    strokes, dots, m, tf = analyze(ch)
    if len(strokes) > 1:
        kept = [s for s in strokes if stroke_len(s) >= MIN_STROKE_LEN]
        strokes = kept or [max(strokes, key=stroke_len)]
    return strokes, dots, m, tf

def F(glyph, word, emoji):
    return {"glyph": glyph, "word": word, "emoji": emoji}

# id, glyph, name, words [(emoji, word)], forms {initial/medial/final: (glyph, word, emoji)}
LETTERS = [
 ("alef", "ا", "ألف", [("🐰", "أرنب"), ("🦁", "أسد"), ("🍍", "أناناس")], {"final": ("ـا", "ماما", "👩")}),
 ("ba", "ب", "باء", [("🦆", "بطة"), ("🏠", "بيت"), ("🐄", "بقرة")],
  {"initial": ("بـ", "بطة", "🦆"), "medial": ("ـبـ", "عنبة", "🍇"), "final": ("ـب", "عنب", "🍇")}),
 ("ta", "ت", "تاء", [("🍎", "تفاحة"), ("🐊", "تمساح"), ("👑", "تاج")],
  {"initial": ("تـ", "تفاحة", "🍎"), "medial": ("ـتـ", "بيتزا", "🍕"), "final": ("ـت", "بيت", "🏠")}),
 ("tha", "ث", "ثاء", [("🦊", "ثعلب"), ("❄️", "ثلج"), ("🧄", "ثوم")],
  {"initial": ("ثـ", "ثعلب", "🦊"), "medial": ("ـثـ", "أثاث", "🛋️"), "final": ("ـث", "حدث", "⭐")}),
 ("jeem", "ج", "جيم", [("🐪", "جمل"), ("🥕", "جزر"), ("🔔", "جرس")],
  {"initial": ("جـ", "جمل", "🐪"), "medial": ("ـجـ", "نجمة", "⭐"), "final": ("ـج", "تاج", "👑")}),
 ("ha", "ح", "حاء", [("🐴", "حصان"), ("🐋", "حوت"), ("🥛", "حليب")],
  {"initial": ("حـ", "حصان", "🐴"), "medial": ("ـحـ", "تفاحة", "🍎"), "final": ("ـح", "تفاح", "🍎")}),
 ("kha", "خ", "خاء", [("🐑", "خروف"), ("🥒", "خيار"), ("🍞", "خبز")],
  {"initial": ("خـ", "خروف", "🐑"), "medial": ("ـخـ", "نخلة", "🌴"), "final": ("ـخ", "بطيخ", "🍉")}),
 ("dal", "د", "دال", [("🐻", "دب"), ("🐔", "دجاجة"), ("🚲", "دراجة")], {"final": ("ـد", "أسد", "🦁")}),
 ("thal", "ذ", "ذال", [("🌽", "ذرة"), ("🐺", "ذئب")], {"final": ("ـذ", "تلميذ", "🎒")}),
 ("ra", "ر", "راء", [("📻", "راديو"), ("🚩", "راية")], {"final": ("ـر", "جزر", "🥕")}),
 ("zay", "ز", "زاي", [("🦒", "زرافة"), ("🌸", "زهرة"), ("🔘", "زر")], {"final": ("ـز", "موز", "🍌")}),
 ("seen", "س", "سين", [("🐟", "سمكة"), ("⏰", "ساعة"), ("🚗", "سيارة")],
  {"initial": ("سـ", "سمكة", "🐟"), "medial": ("ـسـ", "مسطرة", "📏"), "final": ("ـس", "جرس", "🔔")}),
 ("sheen", "ش", "شين", [("☀️", "شمس"), ("🌳", "شجرة"), ("🕯️", "شمعة")],
  {"initial": ("شـ", "شمس", "☀️"), "medial": ("ـشـ", "عشب", "🌿"), "final": ("ـش", "قرش", "🦈")}),
 ("sad", "ص", "صاد", [("🦅", "صقر"), ("🧼", "صابون"), ("📦", "صندوق")],
  {"initial": ("صـ", "صقر", "🦅"), "medial": ("ـصـ", "مصباح", "💡")}),
 ("dad", "ض", "ضاد", [("🐸", "ضفدع"), ("💡", "ضوء"), ("🦷", "ضرس")],
  {"initial": ("ضـ", "ضفدع", "🐸"), "medial": ("ـضـ", "بيضة", "🥚"), "final": ("ـض", "بيض", "🥚")}),
 ("tah", "ط", "طاء", [("✈️", "طائرة"), ("🥁", "طبل"), ("🦚", "طاووس")],
  {"initial": ("طـ", "طائرة", "✈️"), "medial": ("ـطـ", "بطة", "🦆"), "final": ("ـط", "قط", "🐱")}),
 ("zah", "ظ", "ظاء", [("✉️", "ظرف"), ("💅", "ظفر"), ("🦌", "ظبي")],
  {"initial": ("ظـ", "ظرف", "✉️"), "medial": ("ـظـ", "نظارة", "👓")}),
 ("ain", "ع", "عين", [("🍇", "عنب"), ("🐦", "عصفور"), ("🍯", "عسل")],
  {"initial": ("عـ", "عنب", "🍇"), "medial": ("ـعـ", "شمعة", "🕯️"), "final": ("ـع", "إصبع", "☝️")}),
 ("ghain", "غ", "غين", [("🌲", "غابة"), ("☁️", "غيمة"), ("🦌", "غزال")],
  {"initial": ("غـ", "غابة", "🌲"), "medial": ("ـغـ", "نغمة", "🎵"), "final": ("ـغ", "دماغ", "🧠")}),
 ("fa", "ف", "فاء", [("🐘", "فيل"), ("🦋", "فراشة"), ("🍓", "فراولة")],
  {"initial": ("فـ", "فيل", "🐘"), "medial": ("ـفـ", "مفتاح", "🔑"), "final": ("ـف", "خروف", "🐑")}),
 ("qaf", "ق", "قاف", [("🌙", "قمر"), ("🐱", "قطة"), ("❤️", "قلب")],
  {"initial": ("قـ", "قمر", "🌙"), "medial": ("ـقـ", "بقرة", "🐄"), "final": ("ـق", "ورق", "📄")}),
 ("kaf", "ك", "كاف", [("📖", "كتاب"), ("⚽", "كرة"), ("🐶", "كلب")],
  {"initial": ("كـ", "كتاب", "📖"), "medial": ("ـكـ", "مكعب", "🧊"), "final": ("ـك", "سمك", "🐟")}),
 ("lam", "ل", "لام", [("🍋", "ليمون"), ("🧸", "لعبة"), ("👅", "لسان")],
  {"initial": ("لـ", "ليمون", "🍋"), "medial": ("ـلـ", "قلم", "✏️"), "final": ("ـل", "جمل", "🐪")}),
 ("meem", "م", "ميم", [("🍌", "موز"), ("🔑", "مفتاح"), ("☂️", "مظلة")],
  {"initial": ("مـ", "موز", "🍌"), "medial": ("ـمـ", "نملة", "🐜"), "final": ("ـم", "قلم", "✏️")}),
 ("noon", "ن", "نون", [("⭐", "نجمة"), ("🐝", "نحلة"), ("🐯", "نمر")],
  {"initial": ("نـ", "نجمة", "⭐"), "medial": ("ـنـ", "عنب", "🍇"), "final": ("ـن", "لبن", "🥛")}),
 ("heh", "ه", "هاء", [("🌙", "هلال"), ("🎁", "هدية"), ("📱", "هاتف")],
  {"initial": ("هـ", "هلال", "🌙"), "medial": ("ـهـ", "نهر", "🏞️"), "final": ("ـه", "وجه", "😀")}),
 ("waw", "و", "واو", [("🌹", "وردة"), ("👦", "ولد"), ("🦆", "وز")], {}),
 ("yeh", "ي", "ياء", [("✋", "يد"), ("🕊️", "يمامة"), ("🌼", "ياسمين")],
  {"initial": ("يـ", "يد", "✋"), "medial": ("ـيـ", "بيت", "🏠"), "final": ("ـي", "كرسي", "🪑")}),
]

def build():
    out = []
    for lid, glyph, name, words, forms in LETTERS:
        strokes, dots, _, _ = trace_for(glyph)
        out.append({
            "id": lid, "glyph": glyph, "name": name,
            "words": [{"emoji": e, "word": w} for e, w in words],
            "forms": {k: F(*v) for k, v in forms.items()},
            "trace": {
                "strokes": [{"smooth": True, "p": [[x, y] for x, y in s]} for s in strokes],
                "dots": [[x, y] for x, y in dots],
            },
        })
    return out

def preview(data, path, cell=200, cols=7):
    rows = math.ceil(len(data) / cols)
    sheet = Image.new("RGB", (cols * cell, rows * cell), "white")
    dr = ImageDraw.Draw(sheet)
    colors = [(220, 40, 40), (40, 120, 220), (30, 160, 60), (200, 120, 0), (150, 50, 200)]
    for i, l in enumerate(data):
        cx, cy = (i % cols) * cell, (i // cols) * cell
        m = render(l["glyph"])
        x0, y0, x1, y1 = bbox(m)
        w, h = x1 - x0 + 1, y1 - y0 + 1
        s = 0.84 / max(w, h)
        ox, oy = 0.5 - (x0 + w / 2) * s, 0.5 - (y0 + h / 2) * s
        ys, xs = np.nonzero(m)
        for y, x in zip(ys[::3], xs[::3]):
            dr.point(((x * s + ox) * cell + cx, (y * s + oy) * cell + cy), fill=(210, 210, 210))
        for k, st in enumerate(l["trace"]["strokes"]):
            pts = [(cx + p[0] * cell, cy + p[1] * cell) for p in catmull([tuple(q) for q in st["p"]])]
            dr.line(pts, fill=colors[k % 5], width=3)
            dr.ellipse((pts[0][0] - 5, pts[0][1] - 5, pts[0][0] + 5, pts[0][1] + 5), fill=colors[k % 5])
        for d in l["trace"]["dots"]:
            dr.ellipse((cx + d[0] * cell - 6, cy + d[1] * cell - 6, cx + d[0] * cell + 6, cy + d[1] * cell + 6), outline=(0, 0, 0), width=2)
        dr.rectangle((cx, cy, cx + cell - 1, cy + cell - 1), outline=(190, 190, 255))
        dr.text((cx + 4, cy + 4), l["id"], fill=(0, 0, 0))
    sheet.save(path)

if __name__ == "__main__":
    data = build()
    os.makedirs("assets/data", exist_ok=True)
    with open("assets/data/arabic_letters.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    os.makedirs("docs", exist_ok=True)
    preview(data, "docs/letters_preview.png")
    print(f"ok: {len(data)} letters -> assets/data/arabic_letters.json, docs/letters_preview.png")
