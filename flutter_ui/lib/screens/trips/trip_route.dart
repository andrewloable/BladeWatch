import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'trips_models.dart';

/// Turning a trip's telemetry into something a map can draw.
///
/// Ground truth: `TripDetailController.renderRoute()` — pure list/geometry work
/// with no widgets, so it is unit-testable and the widget stays declarative.
/// Plain top-level functions rather than a class of statics: there is no state
/// to hold, and a private constructor purely to prevent instantiation is a line
/// no test can ever reach.

/// The route, in order, keeping only samples that actually carry a fix.
///
/// Telemetry samples are emitted on a timer whether or not GPS has a lock, so
/// a trip that starts in a car park has leading rows at (0, 0). Native drops
/// them with the same `filter { it.hasGps }`; without it the route would draw
/// a line from the Gulf of Guinea to wherever the car actually was.
List<LatLng> tripRoutePoints(List<TelemetryPoint> telemetry) =>
    telemetry.where((t) => t.hasGps).map((t) => LatLng(t.lat, t.lon)).toList(growable: false);

/// The bounding box the camera fits to.
///
/// [LatLngBounds] throws on an empty list, and a single point yields a
/// zero-area box that `CameraFit.bounds` cannot resolve a zoom for — callers
/// must therefore not reach here below 2 points, which is exactly the
/// threshold native uses to hide the map entirely.
LatLngBounds tripRouteBounds(List<LatLng> points) => LatLngBounds.fromPoints(points);
