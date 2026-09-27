import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';

/// Whether the car is recording video right now (BladeWatch-uymd).
///
/// `recording_status.is_recording` is the pipeline's own flag, the one the companion and the web
/// app read. The older `recording` camera list is filled only in the pipeline's recording MODE, so
/// it stayed empty while a continuous dashcam clip was being written: the dashboard said Idle and
/// the Live view's mark button stayed off. The list is kept only for a daemon too old to send the
/// status.
extension RecordingNow on GetStatusResponse {
  bool get isRecordingNow => hasRecordingStatus() ? recordingStatus.isRecording : recording.isNotEmpty;
}
