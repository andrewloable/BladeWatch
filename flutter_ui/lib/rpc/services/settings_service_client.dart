// Hand-written Connect RPC wrapper for bladewatch.v1.SettingsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_ui/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class SettingsServiceClient {
  final RpcTransport _transport;

  const SettingsServiceClient(this._transport);

  Future<GetQualityResponse> getQuality(GetQualityRequest request) => _transport.call(
        'SettingsService',
        'GetQuality',
        request,
        (json) => GetQualityResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetQualityResponse> setQuality(SetQualityRequest request) => _transport.call(
        'SettingsService',
        'SetQuality',
        request,
        (json) => SetQualityResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetAppearanceResponse> getAppearance(GetAppearanceRequest request) => _transport.call(
        'SettingsService',
        'GetAppearance',
        request,
        (json) => GetAppearanceResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetAppearanceResponse> setAppearance(SetAppearanceRequest request) => _transport.call(
        'SettingsService',
        'SetAppearance',
        request,
        (json) => SetAppearanceResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetLocaleResponse> getLocale(GetLocaleRequest request) => _transport.call(
        'SettingsService',
        'GetLocale',
        request,
        (json) => GetLocaleResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetLocaleResponse> setLocale(SetLocaleRequest request) => _transport.call(
        'SettingsService',
        'SetLocale',
        request,
        (json) => SetLocaleResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetRecordingModeResponse> setRecordingMode(SetRecordingModeRequest request) => _transport.call(
        'SettingsService',
        'SetRecordingMode',
        request,
        (json) => SetRecordingModeResponse()..mergeFromProto3Json(json ?? const {}),
      );

}
