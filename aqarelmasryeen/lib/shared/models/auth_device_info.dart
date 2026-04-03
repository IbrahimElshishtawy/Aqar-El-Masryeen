import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class AuthDeviceInfo extends Equatable {
  const AuthDeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.model,
    required this.manufacturer,
    required this.isPhysicalDevice,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final String model;
  final String manufacturer;
  final bool isPhysicalDevice;

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'model': model,
      'manufacturer': manufacturer,
      'isPhysicalDevice': isPhysicalDevice,
      'lastSeenAt': DateTime.now(),
    };
  }

  factory AuthDeviceInfo.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return AuthDeviceInfo(
      deviceId: data['deviceId'] as String? ?? '',
      deviceName: data['deviceName'] as String? ?? 'Unknown device',
      platform: data['platform'] as String? ?? defaultTargetPlatform.name,
      osVersion: data['osVersion'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '',
      buildNumber: data['buildNumber'] as String? ?? '',
      model: data['model'] as String? ?? '',
      manufacturer: data['manufacturer'] as String? ?? '',
      isPhysicalDevice: data['isPhysicalDevice'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    platform,
    osVersion,
    appVersion,
    buildNumber,
    model,
    manufacturer,
    isPhysicalDevice,
  ];
}
