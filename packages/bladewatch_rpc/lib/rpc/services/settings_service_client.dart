// Hand-written Connect RPC wrapper for bladewatch.v1.SettingsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class SettingsServiceClient {
  final RpcTransport _transport;

  const SettingsServiceClient(this._transport);

  // BladeWatch-qwqq: the telemetry-field picker, moved off direct REST.
  Future<GetTelemetryOverlayFieldsResponse> getTelemetryOverlayFields(
          GetTelemetryOverlayFieldsRequest request) =>
      _transport.call(
        'SettingsService',
        'GetTelemetryOverlayFields',
        request,
        (json) => GetTelemetryOverlayFieldsResponse()
          ..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetTelemetryOverlayFieldsResponse> setTelemetryOverlayFields(
          SetTelemetryOverlayFieldsRequest request) =>
      _transport.call(
        'SettingsService',
        'SetTelemetryOverlayFields',
        request,
        (json) => SetTelemetryOverlayFieldsResponse()
          ..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetQualityResponse> getQuality(GetQualityRequest request) => _transport.call(
        'SettingsService',
        'GetQuality',
        request,
        (json) => GetQualityResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetQualityResponse> setQuality(SetQualityRequest request) => _transport.call(
        'SettingsService',
        'SetQuality',
        request,
        (json) => SetQualityResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetAppearanceResponse> getAppearance(GetAppearanceRequest request) => _transport.call(
        'SettingsService',
        'GetAppearance',
        request,
        (json) => GetAppearanceResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetAppearanceResponse> setAppearance(SetAppearanceRequest request) => _transport.call(
        'SettingsService',
        'SetAppearance',
        request,
        (json) => SetAppearanceResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetLocaleResponse> getLocale(GetLocaleRequest request) => _transport.call(
        'SettingsService',
        'GetLocale',
        request,
        (json) => GetLocaleResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetLocaleResponse> setLocale(SetLocaleRequest request) => _transport.call(
        'SettingsService',
        'SetLocale',
        request,
        (json) => SetLocaleResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetRecordingModeResponse> setRecordingMode(SetRecordingModeRequest request) => _transport.call(
        'SettingsService',
        'SetRecordingMode',
        request,
        (json) => SetRecordingModeResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetStatusOverlayResponse> getStatusOverlay(GetStatusOverlayRequest request) => _transport.call(
        'SettingsService',
        'GetStatusOverlay',
        request,
        (json) => GetStatusOverlayResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetStatusOverlayResponse> setStatusOverlay(SetStatusOverlayRequest request) => _transport.call(
        'SettingsService',
        'SetStatusOverlay',
        request,
        (json) => SetStatusOverlayResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );
}
