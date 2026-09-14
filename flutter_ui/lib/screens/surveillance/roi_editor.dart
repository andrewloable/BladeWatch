import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A touch-drawn motion zone. Ground truth: `RoiDrawingView.kt`
/// (app/src/main/java/com/loabletech/bladewatch/ui/view/) — which was written
/// but never wired to anything on any platform (BladeWatch-9b0f). The
/// interaction model is ported from it exactly; the geometry is kept as plain
/// functions so it can be tested without pumping a widget.

/// Fewer than this many vertices is not a zone. This is the ENGINE's rule, not
/// a UI nicety: `SurveillanceEngineGpu.applyQuadrantRoi` clears the quadrant
/// when given fewer than 3 points.
const int kRoiMinPoints = 3;

/// `RoiDrawingView.maxPoints`. Past this a tap does nothing rather than
/// silently replacing a vertex.
const int kRoiMaxPoints = 8;

/// `RoiDrawingView.touchSlop` — the radius, in logical pixels, within which a
/// touch grabs an existing vertex instead of adding a new one. Generous
/// because this is a car dashboard operated with a fingertip, often in motion.
const double kRoiTouchSlop = 48;

/// Index of the vertex under [at], or null when the touch is on empty canvas.
///
/// First match wins, matching native's `findPointAt` — with overlapping
/// vertices the earlier one is grabbed, which keeps repeated drags stable
/// instead of alternating between two points.
int? roiHitTest(List<Offset> normalised, Offset at, Size size, {double slop = kRoiTouchSlop}) {
  for (var i = 0; i < normalised.length; i++) {
    if ((roiToLocal(normalised[i], size) - at).distance <= slop) return i;
  }
  return null;
}

/// Local widget coordinates -> normalised 0..1, clamped.
///
/// Normalised so a zone drawn on this screen still means the same region after
/// a resolution or layout change — the engine rasterises it against its own
/// 10x7 block grid, not against pixels.
Offset roiToNormalised(Offset local, Size size) => Offset(
      size.width <= 0 ? 0 : (local.dx / size.width).clamp(0.0, 1.0),
      size.height <= 0 ? 0 : (local.dy / size.height).clamp(0.0, 1.0),
    );

/// Normalised 0..1 -> local widget coordinates.
Offset roiToLocal(Offset normalised, Size size) =>
    Offset(normalised.dx * size.width, normalised.dy * size.height);

/// Whether [points] form a zone the engine would actually apply.
bool roiIsApplied(List<Offset> points) => points.length >= kRoiMinPoints;

/// Draws the polygon, its vertices and their order.
class RoiPainter extends CustomPainter {
  final List<Offset> normalised;
  final Color color;
  final Color vertexColor;

  const RoiPainter({required this.normalised, required this.color, required this.vertexColor});

  @override
  void paint(Canvas canvas, Size size) {
    final points = [for (final n in normalised) roiToLocal(n, size)];
    if (points.isEmpty) return;

    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      // Only close the shape once it IS one — two points are a line, and
      // drawing them as a degenerate "polygon" implies a zone that the engine
      // would refuse to apply.
      if (roiIsApplied(normalised)) {
        path.close();
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.25));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..isAntiAlias = true,
      );
    }

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 9, Paint()..color = vertexColor);
      canvas.drawCircle(
        points[i],
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(RoiPainter old) =>
      old.color != color || old.vertexColor != vertexColor || !_sameOffsets(old.normalised, normalised);

  static bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The drawing surface: tap empty canvas to add a vertex, drag a vertex to move
/// it. Ports `RoiDrawingView.onTouchEvent` — including that a tap beyond
/// [kRoiMaxPoints] is simply ignored.
class RoiEditor extends StatefulWidget {
  final List<Offset> points;
  final ValueChanged<List<Offset>> onChanged;

  const RoiEditor({super.key, required this.points, required this.onChanged});

  @override
  State<RoiEditor> createState() => _RoiEditorState();
}

class _RoiEditorState extends State<RoiEditor> {
  int? _dragging;
  Size _size = Size.zero;

  void _addAt(Offset local) {
    // Past the maximum a tap does nothing, rather than silently replacing a
    // vertex — same as RoiDrawingView.
    if (widget.points.length >= kRoiMaxPoints) return;
    widget.onChanged([...widget.points, roiToNormalised(local, _size)]);
  }

  void _beginDrag(Offset local) => setState(() => _dragging = roiHitTest(widget.points, local, _size));

  void _onMove(Offset local) {
    final index = _dragging;
    if (index == null || index >= widget.points.length) return;
    final moved = [...widget.points]..[index] = roiToNormalised(local, _size);
    widget.onChanged(moved);
  }

  void _releaseDrag() {
    if (_dragging != null) setState(() => _dragging = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return RawGestureDetector(
          key: const ValueKey('roi.canvas'),
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            // A tap adds a vertex. Deliberately a TAP and not a pan-down: the
            // editor sits inside the settings pane's ListView, and claiming
            // every press would mean a user trying to SCROLL past the editor
            // drew a row of stray points instead.
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              TapGestureRecognizer.new,
              (r) => r.onTapUp = (d) => _addAt(d.localPosition),
            ),
            // A pan is claimed ONLY when it starts on an existing vertex, so a
            // drag anywhere else stays with the scrollable and the pane scrolls
            // normally.
            _VertexDragRecognizer:
                GestureRecognizerFactoryWithHandlers<_VertexDragRecognizer>(
              () => _VertexDragRecognizer(
                isOnVertex: (local) => roiHitTest(widget.points, local, _size) != null,
              ),
              (r) {
                r.onStart = (d) => _beginDrag(d.localPosition);
                r.onUpdate = (d) => _onMove(d.localPosition);
                r.onEnd = (_) => _releaseDrag();
                r.onCancel = _releaseDrag;
              },
            ),
          },
          child: CustomPaint(
            size: _size,
            painter: RoiPainter(
              normalised: widget.points,
              color: theme.colorScheme.primary,
              vertexColor: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

/// A pan that only enters the gesture arena when the press lands on an existing
/// vertex.
///
/// Without this the editor competes with the settings pane's own scroll for
/// every drag, and since it is `HitTestBehavior.opaque` it wins — so scrolling
/// past the editor drew points instead of scrolling. Rejecting the pointer
/// outright (rather than accepting and then ignoring it) is what lets the
/// ListView take the gesture.
class _VertexDragRecognizer extends PanGestureRecognizer {
  final bool Function(Offset local) isOnVertex;

  _VertexDragRecognizer({required this.isOnVertex});

  @override
  bool isPointerAllowed(PointerEvent event) =>
      isOnVertex(event.localPosition) && super.isPointerAllowed(event);
}
