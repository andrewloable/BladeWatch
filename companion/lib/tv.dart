import 'dart:io';

import 'package:bladewatch_theme/hud_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether this is an Android TV (BladeWatch 1.4.1.2): Android's own TV feature flag, which every
/// Android TV and Google TV device declares. [features] replaces the platform query in tests.
Future<bool> isAndroidTv({Future<List<String>> Function()? features}) async {
  if (features == null && !Platform.isAndroid) return false;
  try {
    final list = await (features ?? () async => (await DeviceInfoPlugin().androidInfo).systemFeatures)();
    return list.contains('android.software.leanback');
  } catch (_) {
    return false;
  }
}

/// Whether this screen is on a TV: anything under [DpadFieldExit], which only a TV gets.
bool isTv(BuildContext context) => context.findAncestorWidgetOfExactType<DpadFieldExit>() != null;

/// One column of a TV screen -- the side panel, or the page beside it. The remote's up and down
/// never leave it (left and right do): the panel's items sat "below" a page's last control, so down
/// went across into the panel, and from Events' tab bar down went to the panel instead of into the
/// list of alerts (the owner, 2026-10-04). Marks its subtree and nothing more.
class TvPane extends StatefulWidget {
  const TvPane({super.key, required this.child});

  final Widget child;

  /// The pane [context] is in, if any.
  static State<TvPane>? of(BuildContext? context) => context?.findAncestorStateOfType<_TvPaneState>();

  @override
  State<TvPane> createState() => _TvPaneState();
}

class _TvPaneState extends State<TvPane> {
  @override
  Widget build(BuildContext context) => widget.child;
}

/// On a TV, [child] can take focus even though it does nothing when pressed, so the remote can walk
/// down a list of things to read -- Events' alerts, most of which open nothing -- and the page
/// scrolls along. Elsewhere it is [child] unchanged.
Widget tvReadable(BuildContext context, Widget child) => isTv(context) ? Focus(child: child) : child;

/// [slider] on a TV keeps left and right for its value and leaves up and down to move on. A Flutter
/// slider takes all four arrows unless the navigation is directional, so on Surveillance the remote
/// stuck on Sensitivity -- and each up or down changed the car's setting (the owner, 2026-10-04).
Widget tvSlider(BuildContext context, Widget slider) => isTv(context)
    ? MediaQuery(data: MediaQuery.of(context).copyWith(navigationMode: NavigationMode.directional), child: slider)
    : slider;

/// The remote's up and down on a TV.
///
/// They move focus out of a text field: Flutter's text fields keep those keys for the caret, so the
/// remote could never get past the first field to the buttons below it (seen on a Sony BRAVIA,
/// 2026-10-04). Left and right still move the caret, and the select button still opens the keyboard.
///
/// And they scroll a page before they leave it. Focus only lands on controls, so text above the
/// first control of a page, or below the last, could never be scrolled back into view: up from
/// Diagnostics' "Run speed test" jumped straight out of the page (the owner, 2026-10-04). Now, while
/// focus would leave the page (or has nowhere to go) and the page is not at its edge, the page
/// scrolls instead and focus stays put.
class DpadFieldExit extends StatelessWidget {
  const DpadFieldExit({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): _TvMoveIntent(TraversalDirection.up),
          SingleActivator(LogicalKeyboardKey.arrowDown): _TvMoveIntent(TraversalDirection.down),
        },
        child: Actions(actions: {_TvMoveIntent: _TvMoveAction()}, child: child),
      );
}

class _TvMoveIntent extends Intent {
  const _TvMoveIntent(this.direction);

  final TraversalDirection direction;
}

class _TvMoveAction extends Action<_TvMoveIntent> {
  @override
  void invoke(_TvMoveIntent intent) {
    final from = primaryFocus;
    if (from == null) return;
    final up = intent.direction == TraversalDirection.up;
    final scrolled = _verticalScrollable(from.context);
    var moved = from.focusInDirection(intent.direction);
    // Focus changes are applied at the end of the event; apply this one now to see where it went.
    // Without this, "where it went" was always "where it was", and nothing above ever scrolled
    // back: up from Diagnostics' first control jumped into the side panel (the owner, 2026-10-04).
    FocusManager.instance.applyFocusChangesIfNeeded();
    final to = primaryFocus;
    // Up and down stay in their pane (TvPane): the side panel, or the page.
    final pane = TvPane.of(from.context);
    if (moved && pane != null && TvPane.of(to?.context) != pane) {
      _back(from);
      moved = false;
    }
    // Focus outside any scrolling page -- a title bar's button -- with nowhere to go: scroll the
    // page under it. A trip's summary has nothing to focus below its title bar, so down did nothing
    // and its scores could never be seen (the owner, 2026-10-04).
    final page = scrolled ?? (moved ? null : _pageAround(from));
    if (page == null) return;
    if (moved && _verticalScrollable(to?.context)?.position == page.position) return;
    final position = page.position;
    final atEdge = up ? position.pixels <= position.minScrollExtent : position.pixels >= position.maxScrollExtent;
    if (atEdge) return;
    if (moved) _back(from);
    final step = position.viewportDimension * 0.8;
    position.animateTo(
      (position.pixels + (up ? -step : step)).clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// Undoes a move: focus back on [node], and the move forgotten. Flutter remembers each directional
  /// move so the opposite key can retrace it; left in place, the next up after an undone down
  /// "retraced" to where focus already was and did nothing (Location, on the BRAVIA, 2026-10-04).
  static void _back(FocusNode node) {
    final scope = node.nearestScope;
    if (scope != null) FocusTraversalGroup.maybeOfNode(node)?.invalidateScopeData(scope);
    node.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
  }

  /// The page in [node]'s pane (or, outside one, its screen) when [node] is not in it: the largest
  /// vertical scrollable there that has somewhere to scroll.
  static ScrollableState? _pageAround(FocusNode node) {
    final context = node.context;
    if (context == null) return null;
    final root = TvPane.of(context)?.context ?? ModalRoute.of(context)?.subtreeContext;
    if (root is! Element) return null;
    ScrollableState? best;
    void visit(Element e) {
      final s = e is StatefulElement ? e.state : null;
      if (s is ScrollableState &&
          axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
          s.position.hasContentDimensions &&
          s.position.maxScrollExtent > s.position.minScrollExtent &&
          s.position.viewportDimension > (best?.position.viewportDimension ?? 0)) {
        best = s;
      }
      e.visitChildren(visit);
    }

    root.visitChildren(visit);
    return best;
  }

  /// The nearest vertical scrollable around [context]: a horizontal one (a row of chips) is skipped.
  static ScrollableState? _verticalScrollable(BuildContext? context) {
    var s = context == null ? null : Scrollable.maybeOf(context);
    while (s != null && axisDirectionToAxis(s.axisDirection) != Axis.vertical) {
      s = Scrollable.maybeOf(s.context);
    }
    return s;
  }
}

/// Where focus is, on a TV (BladeWatch 1.4.1.2). The remote moves focus, but the HUD's controls
/// show it barely or not at all -- on a Sony BRAVIA the owner could not tell what OK would press
/// (2026-10-04). So one bright ring is drawn around whatever control has focus, whatever its kind,
/// and follows it as the page scrolls.
///
/// A whole-screen node (a page, a scope) gets no ring: it is not a control.
class TvFocusRing extends StatefulWidget {
  const TvFocusRing({super.key, required this.child});

  final Widget child;

  @override
  State<TvFocusRing> createState() => _TvFocusRingState();
}

class _TvFocusRingState extends State<TvFocusRing> {
  final _moved = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_ping);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_ping);
    _moved.dispose();
    super.dispose();
  }

  void _ping() => _moved.value++;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _ping();
          return false;
        },
        child: Stack(children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _RingPainter(_moved, BwHud.of(context).accent))),
          ),
        ]),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(Listenable moved, this.color) : super(repaint: moved);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final node = FocusManager.instance.primaryFocus;
    if (node == null || node is FocusScopeNode || node.context == null) return;
    final rect = node.rect;
    if (rect.isEmpty || rect.width * rect.height > size.width * size.height * 0.6) return;
    final ring = RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(10));
    canvas
      ..drawRRect(ring, Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6))
      ..drawRRect(ring, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}
