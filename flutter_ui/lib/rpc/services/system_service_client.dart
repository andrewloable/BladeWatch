// Hand-written Connect RPC wrapper for bladewatch.v1.SystemService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class SystemServiceClient {
  final RpcTransport _transport;

  const SystemServiceClient(this._transport);

  Future<GetStatusResponse> getStatus(GetStatusRequest request) => _transport.call(
        'SystemService',
        'GetStatus',
        request,
        (json) => GetStatusResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetPerformanceResponse> getPerformance(GetPerformanceRequest request) => _transport.call(
        'SystemService',
        'GetPerformance',
        request,
        (json) => GetPerformanceResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<PlayAudioTestResponse> playAudioTest(PlayAudioTestRequest request) => _transport.call(
        'SystemService',
        'PlayAudioTest',
        request,
        (json) => PlayAudioTestResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<ListModelsResponse> listModels(ListModelsRequest request) => _transport.call(
        'SystemService',
        'ListModels',
        request,
        (json) => ListModelsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<DownloadModelResponse> downloadModel(DownloadModelRequest request) => _transport.call(
        'SystemService',
        'DownloadModel',
        request,
        (json) => DownloadModelResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetSohNominalResponse> getSohNominal(GetSohNominalRequest request) => _transport.call(
        'SystemService',
        'GetSohNominal',
        request,
        (json) => GetSohNominalResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetSohNominalResponse> setSohNominal(SetSohNominalRequest request) => _transport.call(
        'SystemService',
        'SetSohNominal',
        request,
        (json) => SetSohNominalResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetSohStatusResponse> getSohStatus(GetSohStatusRequest request) => _transport.call(
        'SystemService',
        'GetSohStatus',
        request,
        (json) => GetSohStatusResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<ResetSohResponse> resetSoh(ResetSohRequest request) => _transport.call(
        'SystemService',
        'ResetSoh',
        request,
        (json) => ResetSohResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<ResetPerformanceResponse> resetPerformance(ResetPerformanceRequest request) => _transport.call(
        'SystemService',
        'ResetPerformance',
        request,
        (json) => ResetPerformanceResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetParkingDeltaResponse> getParkingDelta(GetParkingDeltaRequest request) => _transport.call(
        'SystemService',
        'GetParkingDelta',
        request,
        (json) => GetParkingDeltaResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetLastChargeResponse> getLastCharge(GetLastChargeRequest request) => _transport.call(
        'SystemService',
        'GetLastCharge',
        request,
        (json) => GetLastChargeResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetSelectedModelResponse> getSelectedModel(GetSelectedModelRequest request) => _transport.call(
        'SystemService',
        'GetSelectedModel',
        request,
        (json) => GetSelectedModelResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetSelectedModelResponse> setSelectedModel(SetSelectedModelRequest request) => _transport.call(
        'SystemService',
        'SetSelectedModel',
        request,
        (json) => SetSelectedModelResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetModelsManifestResponse> getModelsManifest(GetModelsManifestRequest request) => _transport.call(
        'SystemService',
        'GetModelsManifest',
        request,
        (json) => GetModelsManifestResponse()..mergeFromProto3Json(json ?? const {}),
      );

}
