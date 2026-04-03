import 'dart:io';

import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:aqarelmasryeen/shared/models/auth_device_info.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  DeviceInfoService(this._plugin, this._secureStorage);

  final DeviceInfoPlugin _plugin;
  final SecureStorageService _secureStorage;

  Future<String> currentDeviceLabel() async {
    final info = await currentDeviceInfo();
    return info.deviceName;
  }

  Future<AuthDeviceInfo> currentDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await _resolveTrustedDeviceId();
    if (kIsWeb) {
      final info = await _plugin.webBrowserInfo;
      return AuthDeviceInfo(
        deviceId: deviceId,
        deviceName: '${info.browserName.name} ${info.platform ?? ''}'.trim(),
        platform: 'web',
        osVersion: info.userAgent ?? '',
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        model: info.appName ?? '',
        manufacturer: 'browser',
        isPhysicalDevice: false,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await _plugin.androidInfo;
        return AuthDeviceInfo(
          deviceId: deviceId,
          deviceName: '${info.brand} ${info.model}',
          platform: 'android',
          osVersion: 'Android ${info.version.release}',
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          model: info.model,
          manufacturer: info.brand,
          isPhysicalDevice: info.isPhysicalDevice,
        );
      case TargetPlatform.iOS:
        final info = await _plugin.iosInfo;
        return AuthDeviceInfo(
          deviceId: deviceId,
          deviceName: info.name,
          platform: 'ios',
          osVersion: '${info.systemName} ${info.systemVersion}',
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          model: info.model,
          manufacturer: 'Apple',
          isPhysicalDevice: info.isPhysicalDevice,
        );
      case TargetPlatform.macOS:
        final info = await _plugin.macOsInfo;
        return AuthDeviceInfo(
          deviceId: deviceId,
          deviceName: info.computerName,
          platform: 'macos',
          osVersion: info.osRelease,
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          model: info.model,
          manufacturer: 'Apple',
          isPhysicalDevice: false,
        );
      case TargetPlatform.windows:
        final info = await _plugin.windowsInfo;
        return AuthDeviceInfo(
          deviceId: deviceId,
          deviceName: info.computerName,
          platform: 'windows',
          osVersion: info.productName,
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          model: info.displayVersion,
          manufacturer: 'Microsoft',
          isPhysicalDevice: true,
        );
      case TargetPlatform.linux:
        final info = await _plugin.linuxInfo;
        return AuthDeviceInfo(
          deviceId: deviceId,
          deviceName: info.prettyName,
          platform: 'linux',
          osVersion: info.version ?? '',
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          model: info.name,
          manufacturer: 'Linux',
          isPhysicalDevice: true,
        );
      default:
        return AuthDeviceInfo(
          deviceId: deviceId,
          deviceName: Platform.operatingSystem,
          platform: Platform.operatingSystem,
          osVersion: Platform.operatingSystemVersion,
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          model: 'unknown',
          manufacturer: 'unknown',
          isPhysicalDevice: true,
        );
    }
  }

  Future<String> _resolveTrustedDeviceId() async {
    final existing = await _secureStorage.read(
      'security.trusted_device_id',
    );
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated =
        'device_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
    await _secureStorage.write('security.trusted_device_id', generated);
    return generated;
  }
}
