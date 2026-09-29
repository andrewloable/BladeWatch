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

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

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

/// AuthService: cache invalidation only. The web login (Login, Logout, GetAuthStatus over
/// /auth/token, /auth/logout, /auth/status) was removed with the web app (BladeWatch-rdtj.22);
/// a companion pairs and logs in over /auth/pair and /auth/companion.
///
///   InvalidateAuthCache  TCP  auth_invalidate (calls AuthManager.invalidateCache() directly)
class AuthServiceApi {
  final $pb.RpcClient _client;

  AuthServiceApi(this._client);

  $async.Future<InvalidateAuthCacheResponse> invalidateAuthCache(
          $pb.ClientContext? ctx, InvalidateAuthCacheRequest request) =>
      _client.invoke<InvalidateAuthCacheResponse>(ctx, 'AuthService',
          'InvalidateAuthCache', request, InvalidateAuthCacheResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
