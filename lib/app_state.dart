import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'core/l10n/app_strings.dart';
import 'services/adaptive_service.dart';
import 'services/ai/ai_tutor_service.dart';
import 'services/audio_service.dart';
import 'services/content_repository.dart';
import 'services/progress_controller.dart';

/// Root object shared through [AppScope]. Owns services; no UI inside.
class AppState extends ChangeNotifier {
  AppState({
    required this.repo,
    required this.progress,
    required this.audio,
    this.ai = const NoAiTutorService(),
  }) {
    adaptive = AdaptiveService(progress);
    progress.addListener(_onProgress);
  }

  final ContentRepository repo;
  final ProgressController progress;
  final AudioService audio;
  final AiTutorService ai;
  late final AdaptiveService adaptive;

  final math.Random random = math.Random();
  Timer? _usageTimer;
  bool _restDismissed = false;
  bool greeted = false;
  bool? _musicState;

  AppStrings get strings => AppStrings(progress.locale);

  Future<void> init() async {
    await progress.load();
    await audio.init();
    _applyAudioSettings();
  }

  void _applyAudioSettings() {
    audio.voiceEnabled = progress.voiceOn;
    audio.sfxEnabled = progress.sfxOn;
    if (_musicState != progress.musicOn) {
      _musicState = progress.musicOn;
      unawaited(audio.setMusic(progress.musicOn));
    }
  }

  void _onProgress() {
    _applyAudioSettings();
    notifyListeners();
  }

  // ------------------------------------------------------------ usage / rest
  void startUsage() {
    _usageTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      final before = limitReached;
      progress.addUsage(5);
      if (limitReached != before) notifyListeners();
    });
    unawaited(audio.resumeMusic());
  }

  void stopUsage() {
    _usageTimer?.cancel();
    _usageTimer = null;
    unawaited(progress.save());
    unawaited(audio.pauseAll());
  }

  bool get limitReached =>
      !_restDismissed &&
      progress.dailyLimitMinutes > 0 &&
      progress.todaySeconds >= progress.dailyLimitMinutes * 60;

  void dismissRest() {
    _restDismissed = true;
    notifyListeners();
  }

  // ------------------------------------------------------------ helpers
  String cheerKey() => 'cheer_${1 + random.nextInt(4)}';

  /// Speaks a UI phrase (recorded file `assets/audio/ui/<key>.*` or local TTS).
  Future<void> say(String key, [Map<String, String> args = const {}]) =>
      audio.speak(key, strings.get(key, args), lang: progress.locale, folder: 'ui');

  @override
  void dispose() {
    _usageTimer?.cancel();
    progress.removeListener(_onProgress);
    super.dispose();
  }
}
