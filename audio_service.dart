import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'arabic_speech.dart';

enum Sfx { tap, correct, wrong, star, win }

/// Audio facade. Voice lines are looked up as recorded files first
/// (assets/audio/<folder>/<key>.mp3|wav|ogg|m4a) and fall back to the device's
/// local text-to-speech. Drop recorded files in without changing any code.
abstract class AudioService {
  bool voiceEnabled = true;
  bool sfxEnabled = true;

  Future<void> init();
  Future<void> speak(String key, String text, {String lang = 'ar', String? folder});
  Future<void> playSfx(Sfx sfx);
  Future<void> setMusic(bool on);
  Future<void> pauseAll();
  Future<void> resumeMusic();
  Future<void> stopVoice();
}

class PlatformAudioService extends AudioService {
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  Set<String> _assets = {};
  bool _musicWanted = false;
  bool _musicPlaying = false;

  static const _sfxFiles = {
    Sfx.tap: 'audio/ui/tap.wav',
    Sfx.correct: 'audio/ui/correct.wav',
    Sfx.wrong: 'audio/ui/oops.wav',
    Sfx.star: 'audio/rewards/star.wav',
    Sfx.win: 'audio/rewards/win.wav',
  };

  @override
  Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
    } catch (_) {}
    try {
      await _sfx.setReleaseMode(ReleaseMode.stop);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.25);
    } catch (_) {}
    try {
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.2);
    } catch (_) {}
  }

  String? _findAsset(String folder, String key) {
    for (final ext in const ['mp3', 'wav', 'ogg', 'm4a']) {
      final p = 'assets/audio/$folder/$key.$ext';
      if (_assets.contains(p)) return p;
    }
    return null;
  }

  @override
  Future<void> speak(String key, String text, {String lang = 'ar', String? folder}) async {
    if (!voiceEnabled) return;
    try {
      await _voice.stop();
      await _tts.stop();
    } catch (_) {}
    final asset = _findAsset(folder ?? lang, key);
    if (asset != null) {
      try {
        await _voice.play(AssetSource(asset.replaceFirst('assets/', '')));
        return;
      } catch (_) {/* fall through to TTS */}
    }
    if (text.trim().isEmpty) return;
    try {
      await _tts.setLanguage(lang == 'ar' ? 'ar-SA' : 'en-US');
      await _tts.speak(lang == 'ar' ? ArabicSpeech.vocalize(text) : text);
    } catch (_) {}
  }

  @override
  Future<void> playSfx(Sfx sfx) async {
    if (!sfxEnabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(_sfxFiles[sfx]!));
    } catch (_) {}
  }

  @override
  Future<void> setMusic(bool on) async {
    _musicWanted = on;
    try {
      if (on && !_musicPlaying) {
        await _music.play(AssetSource('audio/music/sely_theme.wav'));
        _musicPlaying = true;
      } else if (!on && _musicPlaying) {
        await _music.stop();
        _musicPlaying = false;
      }
    } catch (_) {
      _musicPlaying = false;
    }
  }

  @override
  Future<void> pauseAll() async {
    try {
      await _voice.stop();
      await _tts.stop();
      if (_musicPlaying) {
        await _music.pause();
      }
    } catch (_) {}
  }

  @override
  Future<void> resumeMusic() async {
    if (!_musicWanted) return;
    try {
      if (_musicPlaying) {
        await _music.resume();
      } else {
        await setMusic(true);
      }
    } catch (_) {}
  }

  @override
  Future<void> stopVoice() async {
    try {
      await _voice.stop();
      await _tts.stop();
    } catch (_) {}
  }
}

/// Silent implementation for tests; records what would have been spoken.
class NoopAudioService extends AudioService {
  final List<String> spoken = [];
  final List<Sfx> sfx = [];
  bool musicOn = false;

  @override
  Future<void> init() async {}
  @override
  Future<void> speak(String key, String text, {String lang = 'ar', String? folder}) async => spoken.add(key);
  @override
  Future<void> playSfx(Sfx s) async => sfx.add(s);
  @override
  Future<void> setMusic(bool on) async => musicOn = on;
  @override
  Future<void> pauseAll() async {}
  @override
  Future<void> resumeMusic() async {}
  @override
  Future<void> stopVoice() async {}
}
