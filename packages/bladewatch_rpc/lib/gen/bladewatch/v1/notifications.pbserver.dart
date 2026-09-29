// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/notifications.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart' as $0;
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pbjson.dart';

export 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';

abstract class NotificationsServiceBase extends $pb.GeneratedService {
  $async.Future<$0.GetCategoriesResponse> getCategories(
      $pb.ServerContext ctx, $0.GetCategoriesRequest request);
  $async.Future<$0.SendTestResponse> sendTest(
      $pb.ServerContext ctx, $0.SendTestRequest request);
  $async.Future<$0.ListInboxResponse> listInbox(
      $pb.ServerContext ctx, $0.ListInboxRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetCategories':
        return $0.GetCategoriesRequest();
      case 'SendTest':
        return $0.SendTestRequest();
      case 'ListInbox':
        return $0.ListInboxRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetCategories':
        return getCategories(ctx, request as $0.GetCategoriesRequest);
      case 'SendTest':
        return sendTest(ctx, request as $0.SendTestRequest);
      case 'ListInbox':
        return listInbox(ctx, request as $0.ListInboxRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json =>
      NotificationsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => NotificationsServiceBase$messageJson;
}
