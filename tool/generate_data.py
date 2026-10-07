#!/usr/bin/env python3
"""Generates assets/data/*.json (content + trace paths). Run from project root."""
import json, math, os

def r(v): return round(v, 3)
def pts(lst): return [[r(x), r(y)] for x, y in lst]
def stroke(lst, smooth=True): return {"smooth": smooth, "p": pts(lst)}
def ellipse(cx, cy, rx, ry, n=16):
    out = []
    for i in range(n + 1):
        a = -math.pi / 2 + 2 * math.pi * i / n
        out.append((cx + rx * math.cos(a), cy + ry * math.sin(a)))
    return out

BOWL = [(0.88,0.35),(0.85,0.6),(0.7,0.72),(0.5,0.76),(0.3,0.72),(0.15,0.6),(0.12,0.35)]
HAH = [(0.78,0.22),(0.5,0.2),(0.3,0.28),(0.22,0.4),(0.32,0.5),(0.55,0.55),(0.7,0.65),(0.72,0.8),(0.55,0.9),(0.3,0.92)]

def L(id, glyph, name, words, strokes, dots, forms=None):
    return {"id": id, "glyph": glyph, "name": name,
            "words": [{"emoji": e, "word": w} for e, w in words],
            "forms": forms or {},
            "trace": {"strokes": strokes, "dots": pts(dots)}}

def F(glyph, word, emoji): return {"glyph": glyph, "word": word, "emoji": emoji}

letters = [
 L("alef","ا","ألف",[("🐰","أرنب"),("🦁","أسد"),("🍍","أناناس")],[stroke([(0.5,0.1),(0.5,0.9)],False)],[],
   {"final": F("ـا","نار","🔥")}),
 L("ba","ب","باء",[("🦆","بطة"),("🏠","بيت"),("🐄","بقرة")],[stroke(BOWL)],[(0.5,0.92)],
   {"initial": F("بـ","بطة","🦆"),"medial": F("ـبـ","عنبة","🍇"),"final": F("ـب","عنب","🍇")}),
 L("ta","ت","تاء",[("🍎","تفاحة"),("🐊","تمساح"),("👑","تاج")],[stroke(BOWL)],[(0.4,0.45),(0.6,0.45)],
   {"initial": F("تـ","تفاحة","🍎"),"medial": F("ـتـ","بيتزا","🍕"),"final": F("ـت","بيت","🏠")}),
 L("tha","ث","ثاء",[("🦊","ثعلب"),("❄️","ثلج"),("🧄","ثوم")],[stroke(BOWL)],[(0.5,0.28),(0.38,0.47),(0.62,0.47)],
   {"initial": F("ثـ","ثعلب","🦊"),"medial": F("ـثـ","أثاث","🛋️"),"final": F("ـث","حدث","⭐")}),
 L("jeem","ج","جيم",[("🐪","جمل"),("🥕","جزر"),("🔔","جرس")],[stroke(HAH)],[(0.4,0.75)],
   {"initial": F("جـ","جمل","🐪"),"medial": F("ـجـ","نجمة","⭐"),"final": F("ـج","تاج","👑")}),
 L("ha","ح","حاء",[("🐴","حصان"),("🐋","حوت"),("🥛","حليب")],[stroke(HAH)],[],
   {"initial": F("حـ","حصان","🐴"),"medial": F("ـحـ","تفاحة","🍎"),"final": F("ـح","تفاح","🍎")}),
 L("dal","د","دال",[("🐻","دب"),("🐔","دجاجة"),("🚲","دراجة")],
   [stroke([(0.25,0.22),(0.6,0.22),(0.75,0.35),(0.72,0.6),(0.55,0.78),(0.3,0.88)])],[],
   {"final": F("ـد","أسد","🦁")}),
 L("ra","ر","راء",[("📻","راديو"),("🚩","راية")],
   [stroke([(0.62,0.15),(0.66,0.4),(0.58,0.65),(0.4,0.82),(0.2,0.88)])],[],
   {"final": F("ـر","جزر","🥕")}),
 L("seen","س","سين",[("🐟","سمكة"),("⏰","ساعة"),("🚗","سيارة")],
   [stroke([(0.92,0.5),(0.82,0.38),(0.72,0.5),(0.62,0.38),(0.52,0.5),(0.42,0.38),(0.32,0.5),(0.2,0.62),(0.15,0.78),(0.3,0.88),(0.55,0.88)])],[],
   {"initial": F("سـ","سمكة","🐟"),"medial": F("ـسـ","مسطرة","📏"),"final": F("ـس","جرس","🔔")}),
 L("meem","م","ميم",[("🍌","موز"),("🔑","مفتاح"),("☂️","مظلة")],
   [stroke(ellipse(0.58,0.38,0.2,0.17),True), stroke([(0.7,0.52),(0.66,0.72),(0.55,0.88),(0.35,0.92)])],[],
   {"initial": F("مـ","موز","🍌"),"medial": F("ـمـ","نملة","🐜"),"final": F("ـم","قلم","✏️")}),
]

def digit_strokes(n):
    if n == 0: return [stroke(ellipse(0.5,0.5,0.25,0.38,18))]
    if n == 1: return [stroke([(0.4,0.28),(0.55,0.1),(0.55,0.9)],False)]
    if n == 2: return [stroke([(0.25,0.28),(0.35,0.14),(0.55,0.1),(0.72,0.2),(0.74,0.38),(0.6,0.55),(0.25,0.88)]), stroke([(0.25,0.88),(0.8,0.88)],False)]
    if n == 3: return [stroke([(0.25,0.18),(0.5,0.1),(0.72,0.22),(0.65,0.42),(0.45,0.5),(0.7,0.58),(0.78,0.75),(0.6,0.9),(0.25,0.88)])]
    if n == 4: return [stroke([(0.62,0.9),(0.62,0.1),(0.18,0.65),(0.85,0.65)],False)]
    if n == 5: return [stroke([(0.75,0.12),(0.3,0.12),(0.27,0.45)],False), stroke([(0.27,0.45),(0.5,0.4),(0.72,0.5),(0.78,0.7),(0.62,0.88),(0.4,0.9),(0.22,0.8)])]
    if n == 6: return [stroke([(0.7,0.12),(0.45,0.3),(0.28,0.55),(0.28,0.78),(0.45,0.9),(0.65,0.85),(0.72,0.68),(0.6,0.55),(0.42,0.55),(0.3,0.65)])]
    if n == 7: return [stroke([(0.2,0.12),(0.8,0.12),(0.42,0.9)],False)]
    if n == 8: return [stroke(ellipse(0.5,0.3,0.2,0.18)), stroke(ellipse(0.5,0.7,0.25,0.2))]
    if n == 9: return [stroke(ellipse(0.5,0.33,0.22,0.2)), stroke([(0.72,0.33),(0.7,0.65),(0.5,0.9)])]
    if n == 10:
        one = [(0.1+x*0.35, y) for x,y in [(0.4,0.28),(0.55,0.1),(0.55,0.9)]]
        return [stroke(one,False), stroke(ellipse(0.7,0.5,0.2,0.38,18))]

ar_nums = ["صفر","واحد","اثنان","ثلاثة","أربعة","خمسة","ستة","سبعة","ثمانية","تسعة","عشرة"]
en_nums = ["zero","one","two","three","four","five","six","seven","eight","nine","ten"]
numbers = [{"value": n, "ar": ar_nums[n], "en": en_nums[n], "trace": {"strokes": digit_strokes(n), "dots": []}} for n in range(11)]

english = [
 ("apple","A","Apple","🍎"),("ball","B","Ball","⚽"),("cat","C","Cat","🐱"),("dog","D","Dog","🐶"),
 ("egg","E","Egg","🥚"),("fish","F","Fish","🐟"),("hat","H","Hat","🎩"),("sun","S","Sun","☀️"),
 ("car","C","Car","🚗"),("book","B","Book","📖")]
english = [{"id":a,"letter":b,"word":c,"emoji":d} for a,b,c,d in english]

colors = [
 ("red","أحمر","Red",0xFFE53935,"🍎"),("blue","أزرق","Blue",0xFF1E88E5,"🐳"),
 ("yellow","أصفر","Yellow",0xFFFDD835,"🍌"),("green","أخضر","Green",0xFF43A047,"🐸"),
 ("orange","برتقالي","Orange",0xFFFB8C00,"🍊"),("purple","بنفسجي","Purple",0xFF8E24AA,"🍇"),
 ("pink","وردي","Pink",0xFFEC407A,"🌸"),("black","أسود","Black",0xFF212121,"🎱"),
 ("white","أبيض","White",0xFFFAFAFA,"☁️")]
colors = [{"id":a,"ar":b,"en":c,"value":d,"emoji":e} for a,b,c,d,e in colors]
shapes = [("circle","الدائرة","Circle","🌕"),("square","المربع","Square","🎁"),("triangle","المثلث","Triangle","🍕"),
          ("rectangle","المستطيل","Rectangle","🚪"),("star","النجمة","Star","⭐"),("heart","القلب","Heart","❤️")]
shapes = [{"id":a,"ar":b,"en":c,"emoji":d} for a,b,c,d in shapes]

math_data = {
 "emojis": ["🍎","🐥","🍪","🐟","🎈"],
 "add": [{"a":1,"b":1,"level":1},{"a":2,"b":1,"level":1},{"a":1,"b":2,"level":1},{"a":2,"b":2,"level":1},{"a":3,"b":1,"level":1},
         {"a":1,"b":1,"level":2},{"a":2,"b":1,"level":2},{"a":2,"b":2,"level":2},{"a":3,"b":1,"level":3},{"a":3,"b":2,"level":3}],
 "sub": [{"a":2,"b":1,"level":1},{"a":3,"b":1,"level":1},{"a":3,"b":2,"level":1},{"a":4,"b":1,"level":1},{"a":4,"b":2,"level":1},
         {"a":3,"b":1,"level":2},{"a":4,"b":2,"level":2},{"a":5,"b":1,"level":2},{"a":5,"b":3,"level":3},{"a":5,"b":2,"level":3}],
}

os.makedirs("assets/data", exist_ok=True)
for name, data in [("arabic_letters",letters),("numbers",numbers),("english",english),("colors",colors),("shapes",shapes),("math",math_data)]:
    with open(f"assets/data/{name}.json","w",encoding="utf-8") as f:
        json.dump(data,f,ensure_ascii=False,indent=1)
print("ok")
