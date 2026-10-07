/// Extension point for a future AI tutor / speech recognition (not used in v1,
/// no network or API keys involved). Implement this interface and inject it in
/// AppState to add features without touching the lesson screens.
abstract class AiTutorService {
  /// Returns a short encouraging hint for the child, or null when unavailable.
  Future<String?> hintFor({required String skill, required String itemId});

  /// Future: compare the child's spoken answer with [expected]. Null = unsupported.
  Future<bool?> checkSpokenAnswer({required String expected, required List<int> audioPcm});
}

class NoAiTutorService implements AiTutorService {
  const NoAiTutorService();
  @override
  Future<String?> hintFor({required String skill, required String itemId}) async => null;
  @override
  Future<bool?> checkSpokenAnswer({required String expected, required List<int> audioPcm}) async => null;
}
