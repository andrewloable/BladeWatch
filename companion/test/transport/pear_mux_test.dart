import 'dart:typed_data';

import 'package:bladewatch_companion/transport/pear_mux.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-rdtj.8: the companion speaks the car's mux byte for byte. These vectors are the same
/// ones app/src/test/java/com/loabletech/bladewatch/daemon/PearMuxTest.kt pins on the car side.
void main() {
  test('frames have the documented layout', () {
    expect(PearMux.openFrame(7), [1, 0, 0, 0, 7, 1]);
    expect(PearMux.dataFrame(256, 'hi'.codeUnits), [2, 0, 0, 1, 0, 0x68, 0x69]);
    expect(PearMux.closeFrame(0x7fffffff), [3, 0x7f, 0xff, 0xff, 0xff]);
    expect(PearMux.windowFrame(2, 65536), [4, 0, 0, 0, 2, 0, 1, 0, 0]);
  });

  test('every frame round-trips', () {
    final data = PearMux.decode(PearMux.dataFrame(5, [9, 8, 7]))!;
    expect(data.type, PearMux.data);
    expect(data.stream, 5);
    expect(data.payload, [9, 8, 7]);
    expect(PearMux.decode(PearMux.windowFrame(5, 1234))!.credit, 1234);
    expect(PearMux.decode(PearMux.openFrame(5))!.payload, [PearMux.version]);
    expect(PearMux.decode(PearMux.closeFrame(5))!.type, PearMux.close);
  });

  test('malformed frames decode to null instead of throwing', () {
    for (final bad in <List<int>>[
      [],
      [2, 0, 0, 0, 1], // DATA with no payload
      [4, 0, 0, 0, 1, 0, 0, 0, 0], // zero credit
      [3, 0, 0, 0, 1, 0], // CLOSE with a payload
      [1, 0, 0, 0, 1], // OPEN with no version
      [9, 0, 0, 0, 1], // unknown type
      [2, 0, 0, 0, 1, ...List.filled(PearMux.maxData + 1, 0)],
    ]) {
      expect(PearMux.decode(Uint8List.fromList(bad)), isNull, reason: '$bad'.substring(0, '$bad'.length.clamp(0, 30)));
    }
  });

  test('oversized or empty DATA and non-positive credit are refused at encode time', () {
    expect(() => PearMux.dataFrame(1, const []), throwsArgumentError);
    expect(() => PearMux.dataFrame(1, List.filled(PearMux.maxData + 1, 0)), throwsArgumentError);
    expect(() => PearMux.windowFrame(1, 0), throwsArgumentError);
  });
}
