import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'app_state.dart';
import 'services/audio_service.dart';
import 'services/content_repository.dart';
import 'services/progress_controller.dart';
import 'storage/storage_service.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.dumpErrorToConsole(details);
    };
    try {
      await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    } catch (_) {}

    final repo = await ContentRepository.load();
    final progress = ProgressController(storage: PrefsStorage(), totals: repo.totals);
    final state = AppState(repo: repo, progress: progress, audio: PlatformAudioService());
    await state.init();
    runApp(SelyKidsApp(state: state));
  }, (error, stack) {
    if (kDebugMode) debugPrint('Unhandled error: $error');
  });
}
