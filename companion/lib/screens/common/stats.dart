import 'dart:math' as math;

import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import 'format.dart';

/// [info] glows cyan and [drive] magenta, as the in-car week's first row; [plain] does not glow,
/// as its costs and the VEHICLE card.
enum StatTone { info, drive, plain }

typedef Stat = (String value, String label, StatTone tone);

/// The one text scale at which every text fits its width: [base] (the system's own by default)
/// when they all do, smaller otherwise. Sized per group, never per text: shrinking each on its own put "₱0.00" beside
/// a smaller "₱49.96" and one tiny label among full-size ones (the owner, 2026-10-04).
TextScaler fitScaler(BuildContext context, TextStyle style, Iterable<(String text, double width)> texts, {TextScaler? base}) {
  final system = base ?? MediaQuery.textScalerOf(context);
  final size = style.fontSize ?? 14;
  final items = texts.toList();
  TextScaler at(double k) => TextScaler.linear(system.scale(size) / size * k);
  double widthAt(String text, double k) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: at(k),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  // Letter spacing does not shrink with the text, so one proportional pass lands a hair over and
  // clipped "Electric Cost" to "Electric Cos" on the phone: shrink until every text measures in.
  var k = 1.0;
  for (var pass = 0; pass < 4; pass++) {
    var worst = 1.0;
    for (final (text, width) in items) {
      final w = widthAt(text, k);
      if (width > 0 && w > width) worst = math.min(worst, width / w);
    }
    if (worst >= 1) break;
    k *= worst * 0.995;
  }
  return at(k);
}

/// Rows of stats that read as one table, each a value over its label as the in-car cards draw them.
/// Every value is one size, the largest at which all of them fit their columns on one line, so the
/// figures line up row to row. Labels share a size too, but wrap between words before they shrink:
/// one long label used to shrink every label in the grid to unreadable (only a word too long for its
/// column shrinks them). [center] centres each in its column, as the in-car Trips page's period
/// summary does.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.rows, this.center = false});

  final List<List<Stat>> rows;
  final bool center;

  /// Between columns: 8 let "13.9 kWh" run into "81.0 km" (design review 2026-10-04).
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    TextStyle valueStyle(StatTone tone) => hudText(20, tone == StatTone.drive ? hud.driveTimeValue : hud.textPrimary,
        lineHeight: 28,
        weight: FontWeight.w700,
        em: -0.025,
        shadows: tone == StatTone.plain ? null : hudGlow(tone == StatTone.drive ? hud.glowMagenta : hud.glowCyan));
    TextStyle labelStyle(StatTone tone) =>
        hudText(12, tone == StatTone.drive ? hud.magenta : hud.statLabel, lineHeight: 16, weight: hud.labelWeight, em: 0.05);
    return LayoutBuilder(builder: (context, constraints) {
      double width(List<Stat> row) => (constraints.maxWidth - _gap * (row.length - 1)) / row.length;
      final values = fitScaler(context, valueStyle(StatTone.plain), [for (final r in rows) for (final s in r) (s.$1, width(r))]);
      final labels = fitScaler(context, labelStyle(StatTone.plain), [
        for (final r in rows)
          for (final s in r)
            for (final word in s.$2.split(' ')) (word, width(r)),
      ]);
      final align = center ? TextAlign.center : TextAlign.start;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var j = 0; j < rows[i].length; j++) ...[
              if (j > 0) const SizedBox(width: _gap),
              Expanded(
                child: Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
                  Text(rows[i][j].$1, maxLines: 1, softWrap: false, textAlign: align, textScaler: values, style: valueStyle(rows[i][j].$3)),
                  Text(rows[i][j].$2, maxLines: 2, textAlign: align, textScaler: labels, style: labelStyle(rows[i][j].$3)),
                ]),
              ),
            ],
          ]),
        ],
      ]);
    });
  }
}

/// A period's fuel, electric and total cost as stat cells (BladeWatch-39d2, -mgi9, -c149), to sit
/// in the same [StatGrid] as the figures above them; null when there is no sum to show, and then
/// [CostMessage] says why. Fuel is left out on a period that recorded none, as in the car.
List<Stat>? costCells(TripCosts c, Tr tr) => !c.costed
    ? null
    : [
        if (c.hasFuel) (Fmt.money(c.fuel, c.currency), tr('trips.fuel_cost'), StatTone.plain),
        (Fmt.money(c.electric, c.currency), tr('trips.electric_cost'), StatTone.plain),
        (Fmt.money(c.total, c.currency), tr('companion.total_cost'), StatTone.plain),
      ];

/// Why a period has no cost figures: no rate set, or trips in more than one currency, which are
/// never added.
class CostMessage extends StatelessWidget {
  const CostMessage({super.key, required this.costs});

  final TripCosts costs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(context.tr(costs.mixedCurrencies ? 'companion.costs_mixed_currency' : 'trip.cost_hint'),
            key: const ValueKey('costs.message')),
      );
}

/// 0-100 scores as bars with their numbers, as the in-car Stats and trip detail draw them, every
/// label one size so the bars start in one column. [banded] colours each by band (70 and up the
/// accent, 40 and up amber, below that magenta), as the trip detail does; otherwise the accent.
class ScoreBars extends StatelessWidget {
  const ScoreBars({super.key, required this.bars, this.banded = false});

  final List<(String label, int score)> bars;
  final bool banded;

  static const _number = 36.0;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final style = hudText(14, hud.textPrimary, lineHeight: 20);
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return LayoutBuilder(builder: (context, constraints) {
      // Labels and bars share the row equally: at 2/5 "Speed discipline" shrank every label below
      // the size of its score (design review 2026-10-04).
      final labelWidth = (constraints.maxWidth - _number) / 2 - 8;
      final scaler = fitScaler(context, style, [for (final (label, _) in bars) (label, labelWidth)]);
      return Column(children: [
        for (final (label, score) in bars)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(label, maxLines: 1, softWrap: false, textScaler: scaler, style: style),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.clamp(0, 100) / 100,
                    minHeight: 8,
                    backgroundColor: track,
                    color: !banded || score >= 70 ? hud.accent : (score >= 40 ? hud.warning : hud.magenta),
                  ),
                ),
              ),
              SizedBox(
                width: _number,
                child: Text('$score', textAlign: TextAlign.end, style: hudText(12, hud.textSecondary, lineHeight: 16)),
              ),
            ]),
          ),
      ]);
    });
  }
}
