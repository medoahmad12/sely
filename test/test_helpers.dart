import 'dart:convert';
import 'dart:io';
import 'package:sely_kids/app_state.dart';
import 'package:sely_kids/services/audio_service.dart';
import 'package:sely_kids/services/content_repository.dart';
import 'package:sely_kids/services/progress_controller.dart';
import 'package:sely_kids/storage/storage_service.dart';

/// Reads the real JSON assets straight from disk (works inside `flutter test`).
dynamic readData(String name) => jsonDecode(File('assets/data/$name.json').readAsStringSync());

ContentRepository realRepo() => ContentRepository.fromData(
      letters: readData('arabic_letters'),
      numbers: readData('numbers'),
      english: readData('english'),
      colors: readData('colors'),
      shapes: readData('shapes'),
      math: readData('math'),
    );

class TestEnv {
  TestEnv._(this.state, this.audio, this.storage);
  final AppState state;
  final NoopAudioService audio;
  final MemoryStorage storage;

  static Future<TestEnv> create({MemoryStorage? storage}) async {
    final repo = realRepo();
    final st = storage ?? MemoryStorage();
    final audio = NoopAudioService();
    final progress = ProgressController(storage: st, totals: repo.totals);
    final state = AppState(repo: repo, progress: progress, audio: audio);
    await progress.load();
    return TestEnv._(state, audio, st);
  }
}
