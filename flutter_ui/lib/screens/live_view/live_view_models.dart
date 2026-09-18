/// Ground truth: `LiveViewModels.kt`. View-mode integers must match the
/// daemon's `StreamingApiHandler` mapping (`stream.proto`'s `ViewMode` enum
/// has a 6th value, `VIEW_MODE_RAW = 5`, but native's own `LiveViewDirection`
/// enum only defines 5 values, 0-4 — Raw is never exposed by the native UI,
/// confirmed by reading `LiveViewModels.kt` directly rather than assumed —
/// so this port does not add it either).
enum LiveViewDirection {
  mosaic(0),
  front(1),
  right(2),
  rear(3),
  left(4);

  final int viewMode;
  const LiveViewDirection(this.viewMode);
}

enum LiveStreamPhase { idle, connecting, live, error, unavailable }

/// Ground truth: `LiveStreamStatus` sealed interface. [reason] is only ever
/// non-null for [LiveStreamPhase.error]/[LiveStreamPhase.unavailable] —
/// modeled as one class with a nullable field rather than a sealed
/// hierarchy of 5 classes because, unlike e.g. `VehicleState`, there is no
/// other per-phase data to carry, so a `switch` on [phase] with one shared
/// shape is simpler without losing any type safety a caller depends on.
class LiveStreamStatus {
  final LiveStreamPhase phase;
  final String? reason;

  const LiveStreamStatus._(this.phase, this.reason);

  const LiveStreamStatus.idle() : this._(LiveStreamPhase.idle, null);
  const LiveStreamStatus.connecting() : this._(LiveStreamPhase.connecting, null);
  const LiveStreamStatus.live() : this._(LiveStreamPhase.live, null);
  const LiveStreamStatus.error(String reason) : this._(LiveStreamPhase.error, reason);
  const LiveStreamStatus.unavailable(String reason) : this._(LiveStreamPhase.unavailable, reason);
}

/// BladeWatch-nmao.4: no native ground truth for this one -- the one-tap bookmark
/// is a new feature, not a port.
enum MarkStatus { idle, marking }

class LiveViewState {
  final LiveViewDirection direction;
  final LiveStreamStatus status;
  final bool isRecording;
  final MarkStatus markStatus;
  // Transient feedback from the last mark attempt (success or failure); null when
  // there is nothing to show. The screen is expected to clear it after display.
  final String? markMessage;

  const LiveViewState({
    this.direction = LiveViewDirection.front,
    this.status = const LiveStreamStatus.idle(),
    this.isRecording = false,
    this.markStatus = MarkStatus.idle,
    this.markMessage,
  });

  LiveViewState copyWith({
    LiveViewDirection? direction,
    LiveStreamStatus? status,
    bool? isRecording,
    MarkStatus? markStatus,
    String? markMessage,
    bool clearMarkMessage = false,
  }) =>
      LiveViewState(
        direction: direction ?? this.direction,
        status: status ?? this.status,
        isRecording: isRecording ?? this.isRecording,
        markStatus: markStatus ?? this.markStatus,
        markMessage: clearMarkMessage ? null : (markMessage ?? this.markMessage),
      );
}
