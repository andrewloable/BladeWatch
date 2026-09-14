import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four BladeWatch status roles must be REACHABLE from a widget.
///
/// They were defined in `BwColorTokens` from the start and parity-tested against
/// Android's `bladewatch_status_*` XML, but they were never mapped into
/// `ColorScheme` — which has no success/warning slot — and never registered as a
/// theme extension. So no widget could get at them.
///
/// What followed was predictable: screens hand-rolled their own. `settings_daemons_screen.dart`
/// branched on `theme.brightness` to produce `0xFF6EE7A8` / `0xFFFFB870` under a
/// comment reading "the theme has no success/warning role" — and `0xFFFFB870` is
/// `statusWarning` for dark, verbatim. A token reimplemented by hand is a token
/// that has stopped being one.
///
/// These pin that the extension is registered on BOTH themes and that it carries
/// the token values, so the roles cannot silently become unreachable again.
void main() {
  group('BwStatusColors is reachable from the theme', () {
    test('light theme exposes the light token values', () {
      final ext = BladeWatchTheme.light().extension<BwStatusColors>();
      expect(ext, isNotNull, reason: 'status roles must be registered on the light theme');
      expect(ext!.success, BwColorTokens.light.statusSuccess);
      expect(ext.warning, BwColorTokens.light.statusWarning);
      expect(ext.danger, BwColorTokens.light.statusDanger);
      expect(ext.info, BwColorTokens.light.statusInfo);
    });

    test('dark theme exposes the dark token values', () {
      final ext = BladeWatchTheme.dark().extension<BwStatusColors>();
      expect(ext, isNotNull, reason: 'status roles must be registered on the dark theme');
      expect(ext!.success, BwColorTokens.dark.statusSuccess);
      expect(ext.warning, BwColorTokens.dark.statusWarning);
      expect(ext.danger, BwColorTokens.dark.statusDanger);
      expect(ext.info, BwColorTokens.dark.statusInfo);
    });

    // If light and dark resolved to the same colour the extension would be
    // pointless — a hardcoded constant would do the same job.
    test('the two themes actually differ', () {
      final l = BladeWatchTheme.light().extension<BwStatusColors>()!;
      final d = BladeWatchTheme.dark().extension<BwStatusColors>()!;
      expect(l.success, isNot(d.success));
      expect(l.warning, isNot(d.warning));
      expect(l.danger, isNot(d.danger));
      expect(l.info, isNot(d.info));
    });

    testWidgets('a widget can read the roles through Theme.of', (tester) async {
      late BwStatusColors seen;
      await tester.pumpWidget(MaterialApp(
        theme: BladeWatchTheme.dark(),
        home: Builder(builder: (context) {
          seen = Theme.of(context).extension<BwStatusColors>()!;
          return const SizedBox.shrink();
        }),
      ));
      expect(seen.warning, BwColorTokens.dark.statusWarning);
    });

    // lerp is what makes a theme animate between light and dark. A
    // ThemeExtension that returns `this` regardless would snap instead.
    test('lerp interpolates between the two themes', () {
      final l = BladeWatchTheme.light().extension<BwStatusColors>()!;
      final d = BladeWatchTheme.dark().extension<BwStatusColors>()!;
      expect(l.lerp(d, 0).danger, l.danger);
      expect(l.lerp(d, 1).danger, d.danger);
      expect(l.lerp(d, 0.5).danger, isNot(l.danger));
    });

    /// `copyWith` is required by the `ThemeExtension` interface, so it cannot
    /// simply be deleted as unused — but an unexercised one is free to be wrong,
    /// and the usual way it goes wrong is copy-paste: a field assigned from the
    /// wrong parameter. Overriding each role one at a time catches that.
    test('copyWith replaces only the role it is given', () {
      final base = BladeWatchTheme.light().extension<BwStatusColors>()!;
      const red = Color(0xFFFF0000);

      expect(base.copyWith(success: red).success, red);
      expect(base.copyWith(success: red).warning, base.warning);
      expect(base.copyWith(warning: red).warning, red);
      expect(base.copyWith(danger: red).danger, red);
      expect(base.copyWith(info: red).info, red);
      expect(base.copyWith(info: red).danger, base.danger);
    });

    /// `lerp` is handed a `ThemeExtension<BwStatusColors>?`, so Flutter can pass
    /// null (or, in principle, another implementation) mid-animation.
    test('lerp against a non-BwStatusColors keeps this instance', () {
      final base = BladeWatchTheme.light().extension<BwStatusColors>()!;
      expect(base.lerp(null, 0.5), same(base));
    });
  });
}
