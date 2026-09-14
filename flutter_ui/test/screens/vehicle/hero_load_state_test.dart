import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/vehicle/hero_load_state.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeroLoadState', () {
    test('starts in loading, because the GLB is always fetched on mount', () {
      expect(HeroLoadState().phase, HeroPhase.loading);
    });

    test('onModelState(true) clears the indicator and records what is showing', () {
      final s = HeroLoadState();
      s.beginLoad();

      s.onModelState(true, file: 'seal.glb');

      expect(s.phase, HeroPhase.loaded);
      expect(s.loadedFile, 'seal.glb');
    });

    test('onModelState(false) falls back to the placeholder, not a stuck spinner', () {
      final s = HeroLoadState();
      s.beginLoad();

      s.onModelState(false);

      expect(s.phase, HeroPhase.failed);
      expect(s.loadedFile, isNull, reason: 'nothing is on screen, so nothing may be recorded');
    });

    test('markFailed covers the hero never coming up at all', () {
      // Native's "no 3D engine available" branch: show the silhouette, do not spin.
      final s = HeroLoadState();

      s.markFailed();

      expect(s.phase, HeroPhase.failed);
    });

    test('notifies listeners on every real phase change, and not on a repeat', () {
      final s = HeroLoadState();
      var notified = 0;
      s.addListener(() => notified++);

      s.onModelState(true, file: 'a.glb');
      s.onModelState(true, file: 'a.glb'); // already loaded
      s.markFailed();

      expect(notified, 2);
    });

    group('same-model no-flash rule', () {
      test('a different model is a real swap', () {
        final s = HeroLoadState()..onModelState(true, file: 'seal.glb');

        expect(s.shouldLoad('dolphin.glb'), isTrue);
      });

      test('re-selecting the model already showing is not', () {
        // Native guards this with willChangeModel so re-applying the current
        // car does not flash the spinner over it.
        final s = HeroLoadState()..onModelState(true, file: 'seal.glb');

        expect(s.shouldLoad('seal.glb'), isFalse);
      });

      test('a model that FAILED is still eligible for retry', () {
        // The file must not latch on failure, or a transient error would
        // suppress every later attempt — the exact bug the _pageReady work fixed.
        final s = HeroLoadState()..beginLoad();
        s.onModelState(false);

        expect(s.shouldLoad('seal.glb'), isTrue);
      });

      test('beginLoad returns to loading so a swap shows the indicator again', () {
        final s = HeroLoadState()..onModelState(true, file: 'seal.glb');

        s.beginLoad();

        expect(s.phase, HeroPhase.loading);
      });
    });

    group('timeout', () {
      test('a load that is never answered becomes the placeholder, not a permanent spinner', () async {
        final s = HeroLoadState(timeout: const Duration(milliseconds: 30));
        s.beginLoad();

        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(s.phase, HeroPhase.failed);
      });

      test('a load answered in time is not later clobbered by its own timeout', () async {
        final s = HeroLoadState(timeout: const Duration(milliseconds: 30));
        s.beginLoad();
        s.onModelState(true, file: 'seal.glb');

        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(s.phase, HeroPhase.loaded);
      });

      test('the timer is dropped on dispose so a disposed state never notifies', () async {
        final s = HeroLoadState(timeout: const Duration(milliseconds: 30));
        s.beginLoad();
        s.dispose();

        // A live timer here would call notifyListeners() after dispose and throw.
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
    });

    test('a page reload forgets the old document entirely', () {
      final s = HeroLoadState()..onModelState(true, file: 'seal.glb');

      s.onPageRestarted();

      expect(s.phase, HeroPhase.loading);
      expect(s.loadedFile, isNull);
      expect(s.shouldLoad('seal.glb'), isTrue, reason: 'the new document is showing nothing yet');
    });
  });

  group('HeroOverlay', () {
    Future<void> pump(WidgetTester tester, HeroPhase phase, {bool dark = false}) => tester.pumpWidget(MaterialApp(
          theme: dark ? BladeWatchTheme.dark() : BladeWatchTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HeroOverlay(phase: phase)),
        ));

    testWidgets('loading shows a progress indicator', (tester) async {
      await pump(tester, HeroPhase.loading);

      expect(find.byKey(const ValueKey('hero.loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('loaded shows nothing at all, so the car is unobstructed', (tester) async {
      await pump(tester, HeroPhase.loaded);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('hero.placeholder')), findsNothing);
    });

    testWidgets('failed shows the placeholder and NO spinner', (tester) async {
      // The spinner would never resolve in this state; native drops it too.
      await pump(tester, HeroPhase.failed);

      expect(find.byKey(const ValueKey('hero.placeholder')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders without error in dark theme', (tester) async {
      for (final phase in HeroPhase.values) {
        await pump(tester, phase, dark: true);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
