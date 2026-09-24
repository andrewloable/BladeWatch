// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// LoginRequest carries the device token used to obtain a JWT session cookie.
class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? token,
  }) {
    final result = LoginRequest._();
    if (token != null) result.token = token;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: LoginRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginRequest() / LoginRequest.new instead')
  static LoginRequest create() => LoginRequest._();
  static $pb.GeneratedMessage $_createMessage() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => LoginRequest._();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginRequest>(
          LoginRequest.$_createMessage);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $core.bool? success,
    $core.String? deviceId,
    $fixnum.Int64? expiresIn,
    $core.String? error,
  }) {
    final result = LoginResponse._();
    if (success != null) result.success = success;
    if (deviceId != null) result.deviceId = deviceId;
    if (expiresIn != null) result.expiresIn = expiresIn;
    if (error != null) result.error = error;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: LoginResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aInt64(3, _omitFieldNames ? '' : 'expiresIn')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginResponse() / LoginResponse.new instead')
  static LoginResponse create() => LoginResponse._();
  static $pb.GeneratedMessage $_createMessage() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => LoginResponse._();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginResponse>(
          LoginResponse.$_createMessage);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Populated on success.
  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  /// JWT lifetime in seconds.
  @$pb.TagNumber(3)
  $fixnum.Int64 get expiresIn => $_getI64(2);
  @$pb.TagNumber(3)
  set expiresIn($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresIn() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresIn() => $_clearField(3);

  /// Human-readable error on failure.
  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

class LogoutRequest extends $pb.GeneratedMessage {
  factory LogoutRequest() => LogoutRequest._();

  LogoutRequest._();

  factory LogoutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromBuffer(data, registry);
  factory LogoutRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: LogoutRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest copyWith(void Function(LogoutRequest) updates) =>
      super.copyWith((message) => updates(message as LogoutRequest))
          as LogoutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutRequest() / LogoutRequest.new instead')
  static LogoutRequest create() => LogoutRequest._();
  static $pb.GeneratedMessage $_createMessage() => LogoutRequest._();
  @$core.override
  LogoutRequest createEmptyInstance() => LogoutRequest._();
  @$core.pragma('dart2js:noInline')
  static LogoutRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogoutRequest>(
          LogoutRequest.$_createMessage);
  static LogoutRequest? _defaultInstance;
}

class LogoutResponse extends $pb.GeneratedMessage {
  factory LogoutResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = LogoutResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  LogoutResponse._();

  factory LogoutResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutResponse()..mergeFromBuffer(data, registry);
  factory LogoutResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: LogoutResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse copyWith(void Function(LogoutResponse) updates) =>
      super.copyWith((message) => updates(message as LogoutResponse))
          as LogoutResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutResponse() / LogoutResponse.new instead')
  static LogoutResponse create() => LogoutResponse._();
  static $pb.GeneratedMessage $_createMessage() => LogoutResponse._();
  @$core.override
  LogoutResponse createEmptyInstance() => LogoutResponse._();
  @$core.pragma('dart2js:noInline')
  static LogoutResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogoutResponse>(
          LogoutResponse.$_createMessage);
  static LogoutResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class GetAuthStatusRequest extends $pb.GeneratedMessage {
  factory GetAuthStatusRequest() => GetAuthStatusRequest._();

  GetAuthStatusRequest._();

  factory GetAuthStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthStatusRequest()..mergeFromBuffer(data, registry);
  factory GetAuthStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetAuthStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusRequest copyWith(void Function(GetAuthStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetAuthStatusRequest))
          as GetAuthStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAuthStatusRequest() / GetAuthStatusRequest.new instead')
  static GetAuthStatusRequest create() => GetAuthStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAuthStatusRequest._();
  @$core.override
  GetAuthStatusRequest createEmptyInstance() => GetAuthStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAuthStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthStatusRequest>(
          GetAuthStatusRequest.$_createMessage);
  static GetAuthStatusRequest? _defaultInstance;
}

class GetAuthStatusResponse extends $pb.GeneratedMessage {
  factory GetAuthStatusResponse({
    $core.String? status,
    $core.String? deviceId,
  }) {
    final result = GetAuthStatusResponse._();
    if (status != null) result.status = status;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  GetAuthStatusResponse._();

  factory GetAuthStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthStatusResponse()..mergeFromBuffer(data, registry);
  factory GetAuthStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetAuthStatusResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthStatusResponse copyWith(
          void Function(GetAuthStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetAuthStatusResponse))
          as GetAuthStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAuthStatusResponse() / GetAuthStatusResponse.new instead')
  static GetAuthStatusResponse create() => GetAuthStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAuthStatusResponse._();
  @$core.override
  GetAuthStatusResponse createEmptyInstance() => GetAuthStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAuthStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthStatusResponse>(
          GetAuthStatusResponse.$_createMessage);
  static GetAuthStatusResponse? _defaultInstance;

  /// "ok" when authenticated.
  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);
}

class InvalidateAuthCacheRequest extends $pb.GeneratedMessage {
  factory InvalidateAuthCacheRequest() => InvalidateAuthCacheRequest._();

  InvalidateAuthCacheRequest._();

  factory InvalidateAuthCacheRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvalidateAuthCacheRequest()..mergeFromBuffer(data, registry);
  factory InvalidateAuthCacheRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvalidateAuthCacheRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvalidateAuthCacheRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: InvalidateAuthCacheRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateAuthCacheRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateAuthCacheRequest copyWith(
          void Function(InvalidateAuthCacheRequest) updates) =>
      super.copyWith(
              (message) => updates(message as InvalidateAuthCacheRequest))
          as InvalidateAuthCacheRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use InvalidateAuthCacheRequest() / InvalidateAuthCacheRequest.new instead')
  static InvalidateAuthCacheRequest create() => InvalidateAuthCacheRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      InvalidateAuthCacheRequest._();
  @$core.override
  InvalidateAuthCacheRequest createEmptyInstance() =>
      InvalidateAuthCacheRequest._();
  @$core.pragma('dart2js:noInline')
  static InvalidateAuthCacheRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvalidateAuthCacheRequest>(
          InvalidateAuthCacheRequest.$_createMessage);
  static InvalidateAuthCacheRequest? _defaultInstance;
}

class InvalidateAuthCacheResponse extends $pb.GeneratedMessage {
  factory InvalidateAuthCacheResponse({
    $core.bool? success,
  }) {
    final result = InvalidateAuthCacheResponse._();
    if (success != null) result.success = success;
    return result;
  }

  InvalidateAuthCacheResponse._();

  factory InvalidateAuthCacheResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvalidateAuthCacheResponse()..mergeFromBuffer(data, registry);
  factory InvalidateAuthCacheResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvalidateAuthCacheResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvalidateAuthCacheResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: InvalidateAuthCacheResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateAuthCacheResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateAuthCacheResponse copyWith(
          void Function(InvalidateAuthCacheResponse) updates) =>
      super.copyWith(
              (message) => updates(message as InvalidateAuthCacheResponse))
          as InvalidateAuthCacheResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use InvalidateAuthCacheResponse() / InvalidateAuthCacheResponse.new instead')
  static InvalidateAuthCacheResponse create() =>
      InvalidateAuthCacheResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      InvalidateAuthCacheResponse._();
  @$core.override
  InvalidateAuthCacheResponse createEmptyInstance() =>
      InvalidateAuthCacheResponse._();
  @$core.pragma('dart2js:noInline')
  static InvalidateAuthCacheResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvalidateAuthCacheResponse>(
          InvalidateAuthCacheResponse.$_createMessage);
  static InvalidateAuthCacheResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

/// AuthService exposes login, logout, and status endpoints.
///
/// HTTP mapping:
///   Login                POST /auth/token
///   Logout               POST /auth/logout
///   GetAuthStatus        GET  /auth/status
///   InvalidateAuthCache  TCP  auth_invalidate (calls AuthManager.invalidateCache() directly)
class AuthServiceApi {
  final $pb.RpcClient _client;

  AuthServiceApi(this._client);

  $async.Future<LoginResponse> login(
          $pb.ClientContext? ctx, LoginRequest request) =>
      _client.invoke<LoginResponse>(
          ctx, 'AuthService', 'Login', request, LoginResponse());
  $async.Future<LogoutResponse> logout(
          $pb.ClientContext? ctx, LogoutRequest request) =>
      _client.invoke<LogoutResponse>(
          ctx, 'AuthService', 'Logout', request, LogoutResponse());
  $async.Future<GetAuthStatusResponse> getAuthStatus(
          $pb.ClientContext? ctx, GetAuthStatusRequest request) =>
      _client.invoke<GetAuthStatusResponse>(ctx, 'AuthService', 'GetAuthStatus',
          request, GetAuthStatusResponse());
  $async.Future<InvalidateAuthCacheResponse> invalidateAuthCache(
          $pb.ClientContext? ctx, InvalidateAuthCacheRequest request) =>
      _client.invoke<InvalidateAuthCacheResponse>(ctx, 'AuthService',
          'InvalidateAuthCache', request, InvalidateAuthCacheResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
