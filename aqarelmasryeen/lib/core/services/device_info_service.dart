import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  DeviceInfoService(this._plugin);

  final DeviceInfoPlugin _plugin;

  Future<String> currentDeviceLabel() async {
    if (kIsWeb) {
      final info = await _plugin.webBrowserInfo;
      return '${info.browserName.name} ${info.platform ?? ''}'.trim();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await _plugin.androidInfo;
        return '${info.brand} ${info.model}';
      case TargetPlatform.iOS:
        final info = await _plugin.iosInfo;
        return '${info.name} ${info.systemVersion}';
      case TargetPlatform.macOS:
        final info = await _plugin.macOsInfo;
        return '${info.model} ${info.osRelease}';
      case TargetPlatform.windows:
        final info = await _plugin.windowsInfo;
        return '${info.computerName} ${info.productName}';
      case TargetPlatform.linux:
        final info = await _plugin.linuxInfo;
        return '${info.prettyName} ${info.version ?? ''}'.trim();
      default:
        return 'unknown-device';
    }
  }
}
