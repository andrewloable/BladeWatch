import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/util/recording_state.dart';
import 'package:flutter_test/flutter_test.dart';

GetStatusResponse _status(Map<String, Object?> json) => GetStatusResponse()..mergeFromProto3Json(json);

void main() {
  // BladeWatch-uymd: the pipeline's own flag wins; the camera list only for a daemon without it.
  test('recordingStatus.isRecording decides, whatever the camera list says', () {
    expect(_status({'recordingStatus': {'isRecording': true}, 'recording': []}).isRecordingNow, isTrue,
        reason: 'a continuous dashcam clip with an empty camera list: seen on the head unit');
    expect(_status({'recordingStatus': {'isRecording': false}, 'recording': [1]}).isRecordingNow, isFalse);
  });

  test('without recordingStatus (an older daemon) the camera list is used', () {
    expect(_status({'recording': [1]}).isRecordingNow, isTrue);
    expect(_status({}).isRecordingNow, isFalse);
  });
}
