import 'package:flutter/widgets.dart';
import 'app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Reads and subscribes to changes.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }

  /// Reads without subscribing (use inside event handlers / initState).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
  AppState get appRead => AppScope.read(this);
  String tr(String key, [Map<String, String> args = const {}]) => AppScope.of(this).strings.get(key, args);
}
