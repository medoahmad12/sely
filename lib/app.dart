import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_scope.dart';
import 'app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/parent/rest_overlay.dart';
import 'features/splash/splash_screen.dart';

class SelyKidsApp extends StatelessWidget {
  const SelyKidsApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: state.strings.get('app_name'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: Locale(state.progress.locale),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => _LifecycleHost(
            state: state,
            child: Stack(children: [
              Positioned.fill(child: child ?? const SizedBox.shrink()),
              if (state.limitReached) const Positioned.fill(child: RestOverlay()),
            ]),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// Counts play time only while the app is in the foreground and pauses audio in the background.
class _LifecycleHost extends StatefulWidget {
  const _LifecycleHost({required this.state, required this.child});
  final AppState state;
  final Widget child;

  @override
  State<_LifecycleHost> createState() => _LifecycleHostState();
}

class _LifecycleHostState extends State<_LifecycleHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.startUsage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.stopUsage();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      widget.state.startUsage();
    } else if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive || s == AppLifecycleState.hidden) {
      widget.state.stopUsage();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
