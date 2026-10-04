import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';

/// The pack's nominal kWh and the tank's litres, behind "77% / 14.1 kWh" (see `energyLeft`);
/// 0 when unknown. Shared by the Dashboard and the Vehicle page.
class EnergySizes {
  const EnergySizes(this.packKwh, this.tankL);

  static const unknown = EnergySizes(0, 0);

  final double packKwh;
  final double tankL;

  static Future<EnergySizes> load(RpcTransport rpc) async {
    final pack = await SystemServiceClient(rpc).getSohNominal(GetSohNominalRequest());
    final config = await TripsServiceClient(rpc).getConfig(GetConfigRequest());
    return EnergySizes(pack.hasNominalKwh() ? pack.nominalKwh : 0, config.config.fuelTankCapacityL);
  }
}
