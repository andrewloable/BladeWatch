import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/rpc/connect_error.dart';

void main() {
  group('ConnectError', () {
    test('toString includes the code, http status, and message', () {
      const error = ConnectError(httpStatus: 404, code: 'not_found', message: 'no such thing');

      expect(error.toString(), contains('not_found'));
      expect(error.toString(), contains('404'));
      expect(error.toString(), contains('no such thing'));
    });

    test('two errors with the same fields are equal and share a hashCode', () {
      const a = ConnectError(httpStatus: 500, code: 'internal', message: 'x');
      const b = ConnectError(httpStatus: 500, code: 'internal', message: 'x');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('errors differing in any field are not equal', () {
      const base = ConnectError(httpStatus: 500, code: 'internal', message: 'x');

      expect(base, isNot(const ConnectError(httpStatus: 400, code: 'internal', message: 'x')));
      expect(base, isNot(const ConnectError(httpStatus: 500, code: 'unavailable', message: 'x')));
      expect(base, isNot(const ConnectError(httpStatus: 500, code: 'internal', message: 'y')));
      expect(base, isNot('not even a ConnectError'));
    });
  });
}
