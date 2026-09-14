// Hand-written Connect RPC wrapper for bladewatch.v1.StorageService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_ui/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class StorageServiceClient {
  final RpcTransport _transport;

  const StorageServiceClient(this._transport);

  Future<GetStorageSettingsResponse> getStorageSettings(GetStorageSettingsRequest request) => _transport.call(
        'StorageService',
        'GetStorageSettings',
        request,
        (json) => GetStorageSettingsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetStorageSettingsResponse> setStorageSettings(SetStorageSettingsRequest request) => _transport.call(
        'StorageService',
        'SetStorageSettings',
        request,
        (json) => SetStorageSettingsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetExternalStorageResponse> getExternalStorage(GetExternalStorageRequest request) => _transport.call(
        'StorageService',
        'GetExternalStorage',
        request,
        (json) => GetExternalStorageResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetExternalConfigResponse> setExternalConfig(SetExternalConfigRequest request) => _transport.call(
        'StorageService',
        'SetExternalConfig',
        request,
        (json) => SetExternalConfigResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<TriggerCleanupResponse> triggerCleanup(TriggerCleanupRequest request) => _transport.call(
        'StorageService',
        'TriggerCleanup',
        request,
        (json) => TriggerCleanupResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<PreviewCleanupResponse> previewCleanup(PreviewCleanupRequest request) => _transport.call(
        'StorageService',
        'PreviewCleanup',
        request,
        (json) => PreviewCleanupResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<RefreshExternalStorageResponse> refreshExternalStorage(RefreshExternalStorageRequest request) => _transport.call(
        'StorageService',
        'RefreshExternalStorage',
        request,
        (json) => RefreshExternalStorageResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<ListFormatVolumesResponse> listFormatVolumes(ListFormatVolumesRequest request) => _transport.call(
        'StorageService',
        'ListFormatVolumes',
        request,
        (json) => ListFormatVolumesResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<FormatVolumeResponse> formatVolume(FormatVolumeRequest request) => _transport.call(
        'StorageService',
        'FormatVolume',
        request,
        (json) => FormatVolumeResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
