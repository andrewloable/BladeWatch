/// The storage-limit slider's shared behaviour, used by BOTH the Recording and
/// Surveillance settings' Storage tabs.
///
/// Ground truth: `RecordingSettingsController.kt` (`formatMb`, and the SeekBar
/// built in `renderStorage`) and the identical pair in
/// `SurveillanceSettingsController.kt`. Extracted rather than written twice
/// because the two tabs are meant to behave identically and previously drifted
/// from native in exactly the same two ways (BladeWatch-htel).
library;

import 'package:flutter/material.dart';

/// Native's `formatMb`: one decimal of GB from 1024 MB up, whole MB below.
///
/// The port showed the raw megabyte count, so a 16 GB limit read "16384 MB" —
/// accurate, and considerably harder to read on a dashboard at a glance.
String formatStorageMb(int mb) =>
    mb >= 1024 ? '${(mb / 1024.0).toStringAsFixed(1)} GB' : '$mb MB';

/// The step the slider moves in, in MB. Native's SeekBar is built as
/// `max = (maxMb - minMb) / 100`, i.e. one notch per 100 MB.
const int storageStepMb = 100;

/// How many notches the slider has between [minMb] and [maxMb].
///
/// At least 1: a zero-division slider throws, and native guards the same case
/// with `coerceAtLeast(1)`.
int storageSliderDivisions(int minMb, int maxMb) {
  final span = maxMb - minMb;
  if (span <= storageStepMb) return 1;
  return span ~/ storageStepMb;
}

/// Rounds a slider value to the nearest whole step above [minMb], then clamps.
///
/// Without this the port's slider was continuous, so dragging it produced
/// values like 3847 MB — impossible to land on a round figure by touch on a
/// head unit, and different every time the same setting was re-applied.
int snapStorageMb(int mb, int minMb, int maxMb) {
  if (maxMb <= minMb) return minMb;
  final steps = ((mb - minMb) / storageStepMb).round();
  return (minMb + steps * storageStepMb).clamp(minMb, maxMb);
}

/// The storage Path row's value, right-aligned like every other info row.
///
/// Native's `infoRow()` right-aligns the path and lets the TextView ellipsise
/// when it does not fit — verified on the head unit, where the full
/// `/storage/E3B7-10F2/BladeWatch/recordings` does fit. A bare [Text] in a
/// [ListTile.trailing] gets loose constraints and would overflow instead of
/// ellipsising, so the width is capped here.
///
/// ponytail: a fixed cap rather than measuring the pane. Paths this app shows
/// are volume-id + a fixed suffix, so they do not vary much; if a longer one
/// ever needs to fit, make this a LayoutBuilder against the pane width.
Widget bwPathValue(String path) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Text(path, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
    );
