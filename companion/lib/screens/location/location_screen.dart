import 'dart:convert';

import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/car_map.dart';
import '../common/loader.dart';

/// Where the car is: its last GPS fix (GpsMonitor via VehicleService.GetGpsLocation), polled
/// every 10 s, on a map, with a copyable Google Maps link.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

/// A usable fix out of `location_json`, or null.
({LatLng at, bool stale, double? accuracy})? parseFix(String locationJson) {
  if (locationJson.isEmpty) return null;
  try {
    final d = jsonDecode(locationJson) as Map<String, dynamic>;
    final lat = (d['lat'] ?? d['latitude'] ?? 0 as num) as num;
    final lng = (d['lng'] ?? d['lon'] ?? d['longitude'] ?? 0 as num) as num;
    if (lat == 0 && lng == 0) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return (at: LatLng(lat.toDouble(), lng.toDouble()), stale: d['isStale'] == true, accuracy: (d['accuracy'] as num?)?.toDouble());
  } catch (_) {
    return null;
  }
}

class _LocationScreenState extends State<LocationScreen> with LoadersState {
  late final _gps = loader(() => VehicleServiceClient(context.session.rpc).getGpsLocation(GetGpsLocationRequest()),
      poll: const Duration(seconds: 10));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _gps,
      builder: (context, r) {
        final fix = parseFix(r.locationJson);
        if (fix == null) {
          return ListView(children: [
            Padding(padding: const EdgeInsets.all(32), child: Text(tr('vehicle.no_gps_fix'), textAlign: TextAlign.center)),
          ]);
        }
        return Column(children: [
          Expanded(child: CarMap(key: ValueKey(fix.at), center: fix.at, markers: [fix.at])),
          ListTile(
            title: Text('${fix.at.latitude.toStringAsFixed(5)}, ${fix.at.longitude.toStringAsFixed(5)}'),
            subtitle: Text([
              if (fix.stale) tr('status.stale'),
              if (fix.accuracy != null) '± ${fix.accuracy!.toStringAsFixed(0)} m',
            ].join(' · ')),
            trailing: r.googleMapsUrl.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('location.copy'),
                    tooltip: tr('vehicle.open_in_google_maps'),
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: r.googleMapsUrl));
                      if (context.mounted) {
                        say(ScaffoldMessenger.of(context), tr('toast.copied'));
                      }
                    },
                  ),
          ),
        ]);
      },
    );
  }
}
