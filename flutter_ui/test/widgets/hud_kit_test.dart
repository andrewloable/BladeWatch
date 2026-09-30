import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:bladewatch_ui/widgets/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-oxcx: the reusable HUD pieces, and the demo harness that pumps one of every stock control on
/// the HUD ThemeData in both modes.
Widget app(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
  theme: BladeWatchTheme.light(),
  darkTheme: BladeWatchTheme.dark(),
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: c!),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  for (final b in [Brightness.dark, Brightness.light]) {
    final hud = b == Brightness.dark ? BwHud.dark : BwHud.light;

    group('kit in ${b.name}', () {
      testWidgets(
        'HudTitleBar: pulsing square, the title in the accent (glow in dark), rule, optional trailing and back',
        (tester) async {
          var backs = 0;
          await tester.pumpWidget(
            app(
              HudTitleBar(
                title: 'RECORDINGS',
                titleKey: const ValueKey('t'),
                trailing: const Text('LIVE'),
                onBack: () => backs++,
                backTooltip: 'Back',
              ),
              brightness: b,
            ),
          );
          final title = tester.widget<Text>(find.byKey(const ValueKey('t')));
          expect(title.data, 'RECORDINGS');
          expect(
            (title.style!.fontSize, title.style!.fontWeight, title.style!.color),
            (20, FontWeight.w700, hud.accent),
          );
          expect(title.style!.shadows, BwHud.hudGlowList(hud.glowCyan));
          expect(find.byType(HudPulse), findsOneWidget);
          expect(find.text('LIVE'), findsOneWidget);
          final rule =
              (tester.widget<Container>(find.byType(Container).first).decoration! as BoxDecoration).border! as Border;
          expect(rule.bottom.color, hud.titleRule);
          await tester.tap(find.byKey(const ValueKey('hud.back')));
          expect(backs, 1);
          expect(tester.getSize(find.byKey(const ValueKey('hud.back'))).height, greaterThanOrEqualTo(40));
        },
      );

      testWidgets('HudTitleBar without a back button or trailing is just square and title', (tester) async {
        await tester.pumpWidget(app(const HudTitleBar(title: 'X'), brightness: b));
        expect(find.byKey(const ValueKey('hud.back')), findsNothing);
        expect(find.text('X'), findsOneWidget);
      });

      testWidgets(
        'HudSectionLabel upper-cases, 12 dp bold, tracking 0.1em, with an optional magenta icon and trailing',
        (tester) async {
          await tester.pumpWidget(
            app(
              HudSectionLabel('recording', icon: Icons.memory, trailing: const Text('MORE')),
              brightness: b,
            ),
          );
          final label = tester.widget<Text>(find.text('RECORDING'));
          expect((label.style!.fontSize, label.style!.color), (12, hud.accent));
          expect(label.style!.letterSpacing, closeTo(1.2, 1e-9));
          expect(tester.widget<Icon>(find.byIcon(Icons.memory)).color, hud.magenta);
          expect(find.text('MORE'), findsOneWidget);
        },
      );

      testWidgets('HudSectionLabel with no icon or trailing', (tester) async {
        await tester.pumpWidget(app(const HudSectionLabel('a'), brightness: b));
        expect(find.text('A'), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('HudChip: upper-case, chip border, not a button; live has the strong border and a pulsing dot', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(
            const Column(
              children: [
                HudChip(label: 'Gear P'),
                HudChip(label: 'Recording', live: true, dotKey: ValueKey('dot')),
              ],
            ),
            brightness: b,
          ),
        );
        final panels = tester.widgetList<HudPanel>(find.byType(HudPanel)).toList();
        expect((panels[0].borderColor, panels[1].borderColor), (hud.chipBorder, hud.panelBorderStrong));
        expect(find.text('GEAR P'), findsOneWidget);
        expect(find.byKey(const ValueKey('dot')), findsOneWidget);
        expect(find.descendant(of: find.byType(HudChip).first, matching: find.byType(InkWell)), findsNothing);
      });

      testWidgets('HudListRow: 48 dp minimum, taps, selected is the accent border on the soft fill', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          app(
            Column(
              children: [
                HudListRow(
                  icon: Icons.videocam,
                  title: 'Front',
                  subtitle: '12 clips',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => taps++,
                ),
                const HudListRow(title: 'Chosen', selected: true),
              ],
            ),
            brightness: b,
          ),
        );
        expect(tester.getSize(find.byType(HudListRow).first).height, greaterThanOrEqualTo(48));
        await tester.tap(find.text('Front'));
        expect(taps, 1);
        final panels = tester.widgetList<HudPanel>(find.byType(HudPanel)).toList();
        expect((panels[0].color, panels[0].borderColor), (hud.panel, hud.panelBorder));
        expect((panels[1].color, panels[1].borderColor), (Color.alphaBlend(hud.viewAllFill, hud.panel), hud.accent));
        expect(tester.widget<Text>(find.text('Chosen')).style!.color, hud.accent);
        expect(tester.widget<Icon>(find.byIcon(Icons.videocam)).color, hud.iconAccent);
        expect(find.text('12 clips'), findsOneWidget);
      });

      testWidgets('HudListRow takes a custom leading widget', (tester) async {
        await tester.pumpWidget(
          app(
            const HudListRow(
              leading: SizedBox(key: ValueKey('lead'), width: 8, height: 8),
              title: 'T',
            ),
            brightness: b,
          ),
        );
        expect(find.byKey(const ValueKey('lead')), findsOneWidget);
      });

      testWidgets('HudNavItem: vertical is a 64 dp box (52 dense), active has the accent border and a bold label', (
        tester,
      ) async {
        var taps = 0;
        Widget item({required bool selected, bool dense = false, int badge = 0}) => app(
          Center(
            child: SizedBox(
              width: 72,
              child: HudNavItem(
                icon: Icons.videocam,
                label: 'Live',
                selected: selected,
                dense: dense,
                badge: badge,
                onTap: () => taps++,
              ),
            ),
          ),
          brightness: b,
        );
        BoxDecoration box() =>
            tester
                    .widget<Container>(
                      find.descendant(of: find.byType(HudNavItem), matching: find.byType(Container)).first,
                    )
                    .decoration!
                as BoxDecoration;

        await tester.pumpWidget(item(selected: false));
        expect(tester.getSize(find.byType(HudNavItem)).height, 64);
        expect(find.text('LIVE'), findsOneWidget, reason: 'upper-cased');
        expect(box().gradient, isNull);
        expect(tester.widget<Icon>(find.byIcon(Icons.videocam)).size, 18);
        await tester.tap(find.byType(HudNavItem));
        expect(taps, 1);

        await tester.pumpWidget(item(selected: true, dense: true));
        expect(tester.getSize(find.byType(HudNavItem)).height, 52);
        expect((box().border! as Border).top.color, hud.navActiveBorder);
        expect((box().gradient! as LinearGradient).colors, hud.navActiveGradient);
        expect(box().boxShadow, hud.navActiveShadow);
        expect(tester.widget<Icon>(find.byIcon(Icons.videocam)).size, 20);
        expect(tester.widget<Text>(find.text('LIVE')).style!.fontWeight, FontWeight.w700);
        expect(find.byType(Badge), findsNothing);

        await tester.pumpWidget(item(selected: false, badge: 3));
        expect(find.descendant(of: find.byType(Badge), matching: find.text('3')), findsOneWidget);
      });

      testWidgets('HudNavItem horizontal: icon beside a 12 dp label, 48 dp tall, scaled down never wrapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(
            SizedBox(
              width: 120,
              child: HudNavItem(
                icon: Icons.settings,
                label: 'A very long localized label',
                selected: true,
                horizontal: true,
                onTap: () {},
              ),
            ),
            brightness: b,
          ),
        );
        expect(tester.getSize(find.byType(HudNavItem)).height, 48);
        final text = find.text('A VERY LONG LOCALIZED LABEL');
        expect(tester.widget<Text>(text).style!.fontSize, 12);
        expect(tester.widget<Text>(text).maxLines, 1);
        expect(find.ancestor(of: text, matching: find.byType(FittedBox)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('HudStatusDot: four different states, glow where it means something, pulse only when asked', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(
            const Column(
              children: [
                HudStatusDot(HudDotState.ok, key: ValueKey('ok')),
                HudStatusDot(HudDotState.warning, key: ValueKey('warn')),
                HudStatusDot(HudDotState.bad, key: ValueKey('bad'), pulse: true),
                HudStatusDot(HudDotState.idle, key: ValueKey('idle'), size: 12),
              ],
            ),
            brightness: b,
          ),
        );
        BoxDecoration deco(String k) =>
            tester
                    .widget<Container>(find.descendant(of: find.byKey(ValueKey(k)), matching: find.byType(Container)))
                    .decoration!
                as BoxDecoration;
        expect(deco('ok').color, hud.dot);
        expect(deco('ok').boxShadow!.single.color, hud.dotGlow);
        expect(deco('warn').color, hud.warning);
        expect(deco('bad').color, hud.magenta);
        expect(deco('idle').color, hud.textSecondary.withValues(alpha: 0.5));
        expect(deco('idle').boxShadow, isEmpty);
        expect({deco('ok').color, deco('warn').color, deco('bad').color, deco('idle').color}, hasLength(4));
        expect(find.descendant(of: find.byKey(const ValueKey('bad')), matching: find.byType(HudPulse)), findsOneWidget);
        expect(find.descendant(of: find.byKey(const ValueKey('ok')), matching: find.byType(HudPulse)), findsNothing);
        expect(tester.getSize(find.byKey(const ValueKey('idle'))), const Size(12, 12));
      });

      testWidgets('HudEmptyState, HudErrorState (with retry) and HudLoading', (tester) async {
        var retries = 0;
        await tester.pumpWidget(
          app(
            Column(
              children: [
                const SizedBox(
                  height: 140,
                  child: HudEmptyState(icon: Icons.inbox, message: 'No clips'),
                ),
                SizedBox(
                  height: 220,
                  child: HudErrorState(message: 'Could not load', retryLabel: 'Retry', onRetry: () => retries++),
                ),
                const SizedBox(height: 140, child: HudErrorState(message: 'No retry offered')),
                const SizedBox(height: 140, child: HudLoading(label: 'Loading')),
                const SizedBox(height: 60, child: HudLoading()),
              ],
            ),
            brightness: b,
          ),
        );
        expect(find.text('NO CLIPS'), findsOneWidget);
        expect(tester.widget<Icon>(find.byIcon(Icons.inbox)).color, hud.textSecondary);
        expect(tester.widget<Text>(find.text('Could not load')).style!.color, hud.magenta);
        expect(tester.widget<Icon>(find.byIcon(Icons.error_outline).first).color, hud.magenta);
        await tester.tap(find.text('Retry'));
        expect(retries, 1);
        expect(find.byType(OutlinedButton), findsOneWidget, reason: 'no retry button without a handler');
        expect(find.text('LOADING'), findsOneWidget);
        expect(
          tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator).first).color,
          hud.accent,
        );
      });

      testWidgets('HudScope applies the HUD ThemeData for the ambient brightness', (tester) async {
        late ThemeData inside;
        await tester.pumpWidget(
          app(
            HudScope(
              child: Builder(
                builder: (c) {
                  inside = Theme.of(c);
                  return const SizedBox();
                },
              ),
            ),
            brightness: b,
          ),
        );
        expect(inside.extension<BwHud>(), same(hud));
        expect(inside.scaffoldBackgroundColor, hud.pageBackground);
        expect(inside.colorScheme.primary, hud.accent);
      });

      testWidgets('showHudDialog and showHudSheet run on the HUD theme (they use the root navigator)', (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          app(
            Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
            brightness: b,
          ),
        );
        ThemeData? dialogTheme;
        showHudDialog<void>(
          context: ctx,
          builder: (c) {
            dialogTheme = Theme.of(c);
            return const AlertDialog(title: Text('Sure?'), content: Text('Body'));
          },
        );
        await tester.pumpAndSettle();
        expect(dialogTheme!.extension<BwHud>(), same(hud));
        expect(dialogTheme!.colorScheme.primary, hud.accent);
        expect(find.text('Sure?'), findsOneWidget);
        Navigator.of(ctx, rootNavigator: true).pop();
        await tester.pumpAndSettle();

        ThemeData? sheetTheme;
        showHudSheet<void>(
          context: ctx,
          isScrollControlled: true,
          builder: (c) {
            sheetTheme = Theme.of(c);
            return const SizedBox(height: 80, child: Text('Sheet'));
          },
        );
        await tester.pumpAndSettle();
        expect(sheetTheme!.extension<BwHud>(), same(hud));
        expect(sheetTheme!.colorScheme.primary, hud.accent);
        // The sheet's own chrome (route-built) is the HUD's too, not the root theme's.
        final chrome = tester.widget<BottomSheet>(find.byType(BottomSheet));
        expect(chrome.backgroundColor, hud.panel);
        expect((chrome.shape! as RoundedRectangleBorder).side.color, hud.cardBorder);
        expect(chrome.clipBehavior, Clip.antiAlias);
        expect(find.text('Sheet'), findsOneWidget);
      });
    });

    // The demo harness: one of every stock control on the HUD ThemeData. Nothing here is styled by hand; what
    // renders is what the ThemeData says, so a broken component theme fails as an exception or a wrong colour.
    group('demo harness in ${b.name}', () {
      testWidgets('every themed stock control renders on the HUD theme, in the HUD colours', (tester) async {
        tester.view.physicalSize = const Size(1280, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var switchOn = true;
        await tester.pumpWidget(
          app(
            HudScope(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, set) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Card(
                        key: ValueKey('card'),
                        child: Padding(padding: EdgeInsets.all(16), child: Text('Card')),
                      ),
                      ListTile(
                        key: const ValueKey('tile'),
                        leading: const Icon(Icons.settings),
                        title: const Text('Tile'),
                        subtitle: const Text('sub'),
                        onTap: () {},
                      ),
                      SwitchListTile(
                        key: const ValueKey('switch'),
                        value: switchOn,
                        onChanged: (v) => set(() => switchOn = v),
                        title: const Text('Switch'),
                      ),
                      const CheckboxListTile(value: true, onChanged: null, title: Text('Check')),
                      RadioGroup<int>(
                        groupValue: 1,
                        onChanged: (_) {},
                        child: const RadioListTile<int>(value: 1, title: Text('Radio')),
                      ),
                      Slider(value: 0.4, onChanged: (_) {}),
                      const LinearProgressIndicator(value: 0.5),
                      const TextField(
                        key: ValueKey('field'),
                        decoration: InputDecoration(labelText: 'Label', hintText: 'hint', helperText: 'help'),
                      ),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('drop'),
                        initialValue: 'a',
                        items: const [
                          DropdownMenuItem(value: 'a', child: Text('A')),
                          DropdownMenuItem(value: 'b', child: Text('B')),
                        ],
                        onChanged: (_) {},
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('One')),
                          ButtonSegment(value: 2, label: Text('Two')),
                        ],
                        selected: const {1},
                        onSelectionChanged: (_) {},
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            key: const ValueKey('chipOn'),
                            label: const Text('On'),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          ChoiceChip(
                            key: const ValueKey('chipOff'),
                            label: const Text('Off'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                          FilterChip(label: const Text('Filter'), selected: false, onSelected: (_) {}),
                          const Chip(label: Text('Plain')),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(key: const ValueKey('filled'), onPressed: () {}, child: const Text('Filled')),
                          const FilledButton(onPressed: null, child: Text('Disabled')),
                          OutlinedButton(
                            key: const ValueKey('outlined'),
                            onPressed: () {},
                            child: const Text('Outlined'),
                          ),
                          TextButton(key: const ValueKey('text'), onPressed: () {}, child: const Text('Text')),
                          ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
                        ],
                      ),
                      const Divider(),
                      const ExpansionTile(title: Text('Expansion'), children: [Text('inside')]),
                      const Tooltip(message: 'tip', child: Icon(Icons.info)),
                      const DefaultTabController(
                        length: 2,
                        child: TabBar(
                          tabs: [
                            Tab(text: 'A'),
                            Tab(text: 'B'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            brightness: b,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        Material materialOf(String key) => tester.widget<Material>(
          find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Material)).first,
        );
        final card = materialOf('card');
        expect(card.color, hud.panel);
        expect((card.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(4));
        expect((card.shape! as RoundedRectangleBorder).side.color, hud.panelBorder);

        final filled = materialOf('filled');
        expect(filled.color, Color.alphaBlend(hud.viewAllFill, hud.panel));
        expect((filled.shape! as RoundedRectangleBorder).side.color, hud.accent);
        final outlined = materialOf('outlined');
        expect((outlined.color, (outlined.shape! as RoundedRectangleBorder).side.color), (hud.panel, hud.chipBorder));
        expect(
          tester
              .widget<DefaultTextStyle>(
                find
                    .descendant(of: find.byKey(const ValueKey('filled')), matching: find.byType(DefaultTextStyle))
                    .first,
              )
              .style
              .fontFamily,
          BwHud.fontFamily,
        );

        // The field's floating label, the tile's title and a button's label are Space Mono.
        String? familyOf(Finder f) {
          final own = tester.widget<Text>(f).style;
          final base = DefaultTextStyle.of(tester.element(f)).style;
          return (own == null ? base : base.merge(own)).fontFamily;
        }

        expect(familyOf(find.text('Label')), BwHud.fontFamily);
        expect(familyOf(find.text('Tile')), BwHud.fontFamily);
        expect(familyOf(find.text('Filled')), BwHud.fontFamily);
      });
    });
  }
}
