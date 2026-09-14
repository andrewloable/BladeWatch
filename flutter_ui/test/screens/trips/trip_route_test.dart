import 'package:bladewatch_ui/screens/trips/trip_route.dart';
import 'package:bladewatch_ui/screens/trips/trips_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

TelemetryPoint at(double lat, double lon) =>
    TelemetryPoint(timestampMs: 0, speedKmh: 0, accelPercent: 0, brakePercent: 0, lat: lat, lon: lon);

void main() {
  group('tripRoutePoints', () {
    test('keeps every sample that carries a fix, in order', () {
      final points = tripRoutePoints([at(37.1, -122.1), at(37.2, -122.2), at(37.3, -122.3)]);

      expect(points, [
        const LatLng(37.1, -122.1),
        const LatLng(37.2, -122.2),
        const LatLng(37.3, -122.3),
      ]);
    });

    test('drops samples with no fix rather than drawing them at null island', () {
      // Telemetry is sampled on a timer whether or not GPS has a lock, so a trip
      // that starts underground has leading (0,0) rows. Native filters the same way.
      final points = tripRoutePoints([at(0, 0), at(37.2, -122.2), at(0, 0), at(37.3, -122.3)]);

      expect(points.length, 2);
      expect(points.any((p) => p.latitude == 0 && p.longitude == 0), isFalse);
    });

    test('a valid latitude of exactly 0 is still dropped, matching native hasGps', () {
      // hasGps requires BOTH to be non-zero, so a genuine equator/prime-meridian
      // fix is lost. That is native's rule and this port must not silently differ;
      // pinned here so a future change to hasGps is a deliberate one.
      expect(tripRoutePoints([at(0, -122.2)]), isEmpty);
      expect(tripRoutePoints([at(37.2, 0)]), isEmpty);
    });

    test('an empty telemetry list yields no points', () {
      expect(tripRoutePoints(const []), isEmpty);
    });
  });

  group('tripRouteBounds', () {
    test('spans every point of the route', () {
      final bounds = tripRouteBounds(const [
        LatLng(37.1, -122.3),
        LatLng(37.5, -122.1),
        LatLng(37.3, -122.9),
      ]);

      expect(bounds.north, 37.5);
      expect(bounds.south, 37.1);
      expect(bounds.east, -122.1);
      expect(bounds.west, -122.9);
    });

    test('two points are enough, which is the threshold the screen enforces', () {
      final bounds = tripRouteBounds(const [LatLng(1, 2), LatLng(3, 4)]);

      expect(bounds.north, 3);
      expect(bounds.south, 1);
    });
  });
}
