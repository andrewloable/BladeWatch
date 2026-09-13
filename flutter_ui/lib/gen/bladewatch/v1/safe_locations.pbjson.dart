// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/safe_locations.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use safeZoneDescriptor instead')
const SafeZone$json = {
  '1': 'SafeZone',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'lat', '3': 3, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lng', '3': 4, '4': 1, '5': 1, '10': 'lng'},
    {'1': 'radius_m', '3': 5, '4': 1, '5': 5, '10': 'radiusM'},
    {'1': 'active', '3': 6, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'created_at_ms', '3': 7, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `SafeZone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List safeZoneDescriptor = $convert.base64Decode(
    'CghTYWZlWm9uZRIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIQCgNsYXQYAy'
    'ABKAFSA2xhdBIQCgNsbmcYBCABKAFSA2xuZxIZCghyYWRpdXNfbRgFIAEoBVIHcmFkaXVzTRIX'
    'CgZhY3RpdmUYBiABKAhSB2VuYWJsZWQSIAoNY3JlYXRlZF9hdF9tcxgHIAEoA1IJY3JlYXRlZE'
    'F0');

@$core.Deprecated('Use listZonesRequestDescriptor instead')
const ListZonesRequest$json = {
  '1': 'ListZonesRequest',
};

/// Descriptor for `ListZonesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listZonesRequestDescriptor =
    $convert.base64Decode('ChBMaXN0Wm9uZXNSZXF1ZXN0');

@$core.Deprecated('Use listZonesResponseDescriptor instead')
const ListZonesResponse$json = {
  '1': 'ListZonesResponse',
  '2': [
    {
      '1': 'zones',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.SafeZone',
      '10': 'zones'
    },
    {'1': 'feature_enabled', '3': 2, '4': 1, '5': 8, '10': 'featureEnabled'},
    {'1': 'currently_in_safe_zone', '3': 3, '4': 1, '5': 8, '10': 'inSafeZone'},
    {'1': 'has_gps', '3': 4, '4': 1, '5': 8, '10': 'hasGps'},
    {'1': 'current_lat', '3': 5, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'current_lng', '3': 6, '4': 1, '5': 1, '10': 'lng'},
  ],
};

/// Descriptor for `ListZonesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listZonesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Wm9uZXNSZXNwb25zZRItCgV6b25lcxgBIAMoCzIXLmJsYWRld2F0Y2gudjEuU2FmZV'
    'pvbmVSBXpvbmVzEicKD2ZlYXR1cmVfZW5hYmxlZBgCIAEoCFIOZmVhdHVyZUVuYWJsZWQSKgoW'
    'Y3VycmVudGx5X2luX3NhZmVfem9uZRgDIAEoCFIKaW5TYWZlWm9uZRIXCgdoYXNfZ3BzGAQgAS'
    'gIUgZoYXNHcHMSGAoLY3VycmVudF9sYXQYBSABKAFSA2xhdBIYCgtjdXJyZW50X2xuZxgGIAEo'
    'AVIDbG5n');

@$core.Deprecated('Use addZoneRequestDescriptor instead')
const AddZoneRequest$json = {
  '1': 'AddZoneRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'lat', '3': 2, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lng', '3': 3, '4': 1, '5': 1, '10': 'lng'},
    {'1': 'radius_m', '3': 4, '4': 1, '5': 5, '10': 'radiusM'},
  ],
};

/// Descriptor for `AddZoneRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addZoneRequestDescriptor = $convert.base64Decode(
    'Cg5BZGRab25lUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1lEhAKA2xhdBgCIAEoAVIDbGF0Eh'
    'AKA2xuZxgDIAEoAVIDbG5nEhkKCHJhZGl1c19tGAQgASgFUgdyYWRpdXNN');

@$core.Deprecated('Use addZoneResponseDescriptor instead')
const AddZoneResponse$json = {
  '1': 'AddZoneResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'zone',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SafeZone',
      '10': 'zone'
    },
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `AddZoneResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addZoneResponseDescriptor = $convert.base64Decode(
    'Cg9BZGRab25lUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIrCgR6b25lGAIgAS'
    'gLMhcuYmxhZGV3YXRjaC52MS5TYWZlWm9uZVIEem9uZRIUCgVlcnJvchgDIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use updateZoneRequestDescriptor instead')
const UpdateZoneRequest$json = {
  '1': 'UpdateZoneRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'lat', '3': 3, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lng', '3': 4, '4': 1, '5': 1, '10': 'lng'},
    {'1': 'radius_m', '3': 5, '4': 1, '5': 5, '10': 'radiusM'},
  ],
};

/// Descriptor for `UpdateZoneRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateZoneRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVab25lUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IQCgNsYXQYAyABKAFSA2xhdBIQCgNsbmcYBCABKAFSA2xuZxIZCghyYWRpdXNfbRgFIAEoBVIH'
    'cmFkaXVzTQ==');

@$core.Deprecated('Use updateZoneResponseDescriptor instead')
const UpdateZoneResponse$json = {
  '1': 'UpdateZoneResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `UpdateZoneResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateZoneResponseDescriptor = $convert.base64Decode(
    'ChJVcGRhdGVab25lUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgVlcnJvch'
    'gCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use deleteZoneRequestDescriptor instead')
const DeleteZoneRequest$json = {
  '1': 'DeleteZoneRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteZoneRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteZoneRequestDescriptor =
    $convert.base64Decode('ChFEZWxldGVab25lUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use deleteZoneResponseDescriptor instead')
const DeleteZoneResponse$json = {
  '1': 'DeleteZoneResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `DeleteZoneResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteZoneResponseDescriptor = $convert.base64Decode(
    'ChJEZWxldGVab25lUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgVlcnJvch'
    'gCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use toggleSafeLocationsRequestDescriptor instead')
const ToggleSafeLocationsRequest$json = {
  '1': 'ToggleSafeLocationsRequest',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'enabled_set', '3': 2, '4': 1, '5': 8, '10': 'enabledSet'},
  ],
};

/// Descriptor for `ToggleSafeLocationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toggleSafeLocationsRequestDescriptor =
    $convert.base64Decode(
        'ChpUb2dnbGVTYWZlTG9jYXRpb25zUmVxdWVzdBIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEh'
        '8KC2VuYWJsZWRfc2V0GAIgASgIUgplbmFibGVkU2V0');

@$core.Deprecated('Use toggleSafeLocationsResponseDescriptor instead')
const ToggleSafeLocationsResponse$json = {
  '1': 'ToggleSafeLocationsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `ToggleSafeLocationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toggleSafeLocationsResponseDescriptor =
    $convert.base64Decode(
        'ChtUb2dnbGVTYWZlTG9jYXRpb25zUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcx'
        'IYCgdlbmFibGVkGAIgASgIUgdlbmFibGVk');

const $core.Map<$core.String, $core.dynamic> SafeLocationsServiceBase$json = {
  '1': 'SafeLocationsService',
  '2': [
    {
      '1': 'ListZones',
      '2': '.bladewatch.v1.ListZonesRequest',
      '3': '.bladewatch.v1.ListZonesResponse'
    },
    {
      '1': 'AddZone',
      '2': '.bladewatch.v1.AddZoneRequest',
      '3': '.bladewatch.v1.AddZoneResponse'
    },
    {
      '1': 'UpdateZone',
      '2': '.bladewatch.v1.UpdateZoneRequest',
      '3': '.bladewatch.v1.UpdateZoneResponse'
    },
    {
      '1': 'DeleteZone',
      '2': '.bladewatch.v1.DeleteZoneRequest',
      '3': '.bladewatch.v1.DeleteZoneResponse'
    },
    {
      '1': 'Toggle',
      '2': '.bladewatch.v1.ToggleSafeLocationsRequest',
      '3': '.bladewatch.v1.ToggleSafeLocationsResponse'
    },
  ],
};

@$core.Deprecated('Use safeLocationsServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SafeLocationsServiceBase$messageJson = {
  '.bladewatch.v1.ListZonesRequest': ListZonesRequest$json,
  '.bladewatch.v1.ListZonesResponse': ListZonesResponse$json,
  '.bladewatch.v1.SafeZone': SafeZone$json,
  '.bladewatch.v1.AddZoneRequest': AddZoneRequest$json,
  '.bladewatch.v1.AddZoneResponse': AddZoneResponse$json,
  '.bladewatch.v1.UpdateZoneRequest': UpdateZoneRequest$json,
  '.bladewatch.v1.UpdateZoneResponse': UpdateZoneResponse$json,
  '.bladewatch.v1.DeleteZoneRequest': DeleteZoneRequest$json,
  '.bladewatch.v1.DeleteZoneResponse': DeleteZoneResponse$json,
  '.bladewatch.v1.ToggleSafeLocationsRequest': ToggleSafeLocationsRequest$json,
  '.bladewatch.v1.ToggleSafeLocationsResponse':
      ToggleSafeLocationsResponse$json,
};

/// Descriptor for `SafeLocationsService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List safeLocationsServiceDescriptor = $convert.base64Decode(
    'ChRTYWZlTG9jYXRpb25zU2VydmljZRJOCglMaXN0Wm9uZXMSHy5ibGFkZXdhdGNoLnYxLkxpc3'
    'Rab25lc1JlcXVlc3QaIC5ibGFkZXdhdGNoLnYxLkxpc3Rab25lc1Jlc3BvbnNlEkgKB0FkZFpv'
    'bmUSHS5ibGFkZXdhdGNoLnYxLkFkZFpvbmVSZXF1ZXN0Gh4uYmxhZGV3YXRjaC52MS5BZGRab2'
    '5lUmVzcG9uc2USUQoKVXBkYXRlWm9uZRIgLmJsYWRld2F0Y2gudjEuVXBkYXRlWm9uZVJlcXVl'
    'c3QaIS5ibGFkZXdhdGNoLnYxLlVwZGF0ZVpvbmVSZXNwb25zZRJRCgpEZWxldGVab25lEiAuYm'
    'xhZGV3YXRjaC52MS5EZWxldGVab25lUmVxdWVzdBohLmJsYWRld2F0Y2gudjEuRGVsZXRlWm9u'
    'ZVJlc3BvbnNlEl8KBlRvZ2dsZRIpLmJsYWRld2F0Y2gudjEuVG9nZ2xlU2FmZUxvY2F0aW9uc1'
    'JlcXVlc3QaKi5ibGFkZXdhdGNoLnYxLlRvZ2dsZVNhZmVMb2NhdGlvbnNSZXNwb25zZQ==');
