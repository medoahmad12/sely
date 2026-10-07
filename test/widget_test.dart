import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/app_scope.dart';
import 'package:sely_kids/features/games/game_items.dart';
import 'package:sely_kids/features/games/quiz_view.dart';
import 'package:sely_kids/features/trace/trace_board.dart';
import 'package:sely_kids/models/content_models.dart';
import 'package:sely_kids/widgets/hold_to_unlock.dart';
import 'package:sely_kids/widgets/option_tile.dart';
import 'test_helpers.dart';

Widget wrap(TestEnv env, Widget child) => AppScope(
      state: env.state,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('QuizView: wrong answer is gentle, correct answer gives a star and finishes', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    final pool = buildGameItems(ContentKind.shapes, env.state.repo, env.state.strings);
    final target = pool.first;
    int? finishedCorrect;

    await tester.pumpWidget(wrap(
      env,
      QuizView(pool: pool, targets: [target], optionCount: 3, skill: 'test', onFinished: (c, t) => finishedCorrect = c),
    ));
    await tester.pump();
    expect(env.audio.spoken, contains(target.promptKey));

    // Tap a wrong option first.
    final targetKey = ValueKey('opt_${target.id}');
    final wrong = find
        .byType(OptionTile)
        .evaluate()
        .map((e) => e.widget as OptionTile)
        .firstWhere((w) => w.key != targetKey);
    await tester.tap(find.byWidget(wrong));
    await tester.pump();
    expect(env.state.progress.stars, 0);
    expect(env.audio.spoken, contains('try_again'));

    await tester.tap(find.byKey(targetKey));
    await tester.pump();
    expect(env.state.progress.stars, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(finishedCorrect, isNotNull);
    expect(env.state.progress.results['test']!.length, 1);
  });

  testWidgets('TraceBoard completes when the finger follows the guide', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    var done = false;
    const shape = TraceShape(strokes: [
      [Offset(0.5, 0.1), Offset(0.5, 0.9)]
    ], dots: []);
    await tester.pumpWidget(wrap(
      env,
      Align(alignment: Alignment.topLeft, child: SizedBox(width: 600, height: 700, child: TraceBoard(shape: shape, onComplete: () => done = true))),
    ));
    final surface = find.byKey(const Key('trace_surface'));
    final rect = tester.getRect(surface);
    final pad = rect.width * 0.1;
    final inner = rect.width - 2 * pad;
    final gesture = await tester.startGesture(Offset(rect.left + pad + inner * 0.5, rect.top + pad + inner * 0.1));
    for (var i = 1; i <= 40; i++) {
      await gesture.moveTo(Offset(rect.left + pad + inner * 0.5, rect.top + pad + inner * (0.1 + 0.8 * i / 40)));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
    expect(env.audio.sfx, isNotEmpty);
  });

  testWidgets('HoldToUnlock needs a 3 second hold', (tester) async {
    final env = await TestEnv.create();
    var unlocked = 0;
    await tester.pumpWidget(wrap(env, Center(child: HoldToUnlock(onUnlocked: () => unlocked++))));
    final g1 = await tester.startGesture(tester.getCenter(find.byType(HoldToUnlock)));
    await tester.pump(const Duration(seconds: 1));
    await g1.up();
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);

    final g2 = await tester.startGesture(tester.getCenter(find.byType(HoldToUnlock)));
    await tester.pump(const Duration(milliseconds: 3100));
    await g2.up();
    await tester.pump();
    expect(unlocked, 1);
  });
}
