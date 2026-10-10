import 'package:flutter/foundation.dart';

/// Prepares Arabic text for the device's text-to-speech engine.
///
/// Unvowelled single words are the main cause of wrong reading (the engine guesses a
/// case ending and the child hears a tanween). So before speaking:
///  * words we know (letter names, numbers, colors, shapes, common phrases) get full diacritics;
///  * every other word is read in its pausal form: a sukoon on the last letter, and a final
///    taa marbuta is read as "haa" (e.g. بطة -> بطهْ), exactly how a teacher stops on a word;
///  * text that already contains diacritics is left untouched.
/// What is shown on screen never changes: only the text sent to the voice.
class ArabicSpeech {
  ArabicSpeech._();

  static const String _sukoon = '\u0652';
  static final RegExp _token = RegExp('[\u0621-\u0652\u0670]+');
  static final RegExp _harakat = RegExp('[\u064B-\u0652\u0670]');

  static String vocalize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(_token, (m) => _word(m.group(0)!));
  }

  @visibleForTesting
  static bool isKnown(String plainWord) => _known.containsKey(plainWord);

  static String _word(String w) {
    if (_harakat.hasMatch(w)) return w;
    final known = _known[w];
    if (known != null) return known;
    return _pausal(w);
  }

  static String _pausal(String w) {
    if (w.length < 2) return w;
    final last = w[w.length - 1];
    if (last == '\u0629') return '${w.substring(0, w.length - 1)}\u0647$_sukoon';
    if (last == '\u0627' || last == '\u0649' || last == '\u0622') return w;
    return '$w$_sukoon';
  }

  static const Map<String, String> _known = {
    'ألف': 'أَلِفْ',
    'باء': 'بَاءْ',
    'تاء': 'تَاءْ',
    'ثاء': 'ثَاءْ',
    'جيم': 'جِيمْ',
    'حاء': 'حَاءْ',
    'خاء': 'خَاءْ',
    'دال': 'دَالْ',
    'ذال': 'ذَالْ',
    'راء': 'رَاءْ',
    'زاي': 'زَايْ',
    'سين': 'سِينْ',
    'شين': 'شِينْ',
    'صاد': 'صَادْ',
    'ضاد': 'ضَادْ',
    'طاء': 'طَاءْ',
    'ظاء': 'ظَاءْ',
    'عين': 'عَيْنْ',
    'غين': 'غَيْنْ',
    'فاء': 'فَاءْ',
    'قاف': 'قَافْ',
    'كاف': 'كَافْ',
    'لام': 'لَامْ',
    'ميم': 'مِيمْ',
    'نون': 'نُونْ',
    'هاء': 'هَاءْ',
    'واو': 'وَاوْ',
    'ياء': 'يَاءْ',
    'صفر': 'صِفْرْ',
    'واحد': 'وَاحِدْ',
    'اثنان': 'اِثْنَانْ',
    'ثلاثة': 'ثَلَاثَهْ',
    'أربعة': 'أَرْبَعَهْ',
    'خمسة': 'خَمْسَهْ',
    'ستة': 'سِتَّهْ',
    'سبعة': 'سَبْعَهْ',
    'ثمانية': 'ثَمَانِيَهْ',
    'تسعة': 'تِسْعَهْ',
    'عشرة': 'عَشَرَهْ',
    'أحمر': 'أَحْمَرْ',
    'أزرق': 'أَزْرَقْ',
    'أصفر': 'أَصْفَرْ',
    'أخضر': 'أَخْضَرْ',
    'برتقالي': 'بُرْتُقَالِيّ',
    'بنفسجي': 'بَنَفْسَجِيّ',
    'وردي': 'وَرْدِيّ',
    'أسود': 'أَسْوَدْ',
    'أبيض': 'أَبْيَضْ',
    'الدائرة': 'الدَّائِرَهْ',
    'المربع': 'المُرَبَّعْ',
    'المثلث': 'المُثَلَّثْ',
    'المستطيل': 'المُسْتَطِيلْ',
    'النجمة': 'النَّجْمَهْ',
    'القلب': 'القَلْبْ',
    'أين': 'أَيْنَ',
    'حرف': 'حَرْفْ',
    'بحرف': 'بِحَرْفْ',
    'اضغط': 'اِضْغَطْ',
    'على': 'عَلَى',
    'اللون': 'اللَّوْنْ',
    'ما': 'مَا',
    'لا': 'لَا',
    'حاول': 'حَاوِلْ',
    'مرة': 'مَرَّهْ',
    'ثانية': 'ثَانِيَهْ',
    'أنا': 'أَنَا',
    'أرنوب': 'أَرْنُوبْ',
    'ساعدني': 'سَاعِدْنِي',
    'أجد': 'أَجِدْ',
    'الأشياء': 'الأَشْيَاءْ',
    'التي': 'الَّتِي',
    'تبدأ': 'تَبْدَأْ',
    'المس': 'اِلْمِسْ',
    'هذه': 'هَذِهْ',
    'والآن': 'وَالآنَ',
    'نرسم': 'نَرْسُمْ',
    'ارسم': 'اِرْسُمْ',
    'هيا': 'هَيَّا',
    'تعلمنا': 'تَعَلَّمْنَا',
  };
}
