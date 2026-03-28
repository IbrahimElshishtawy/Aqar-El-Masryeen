import 'package:aqarelmasryeen/core/constants/storage_keys.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocaleService extends GetxController {
  LocaleService(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  Locale _currentLocale = const Locale('ar', 'EG');

  Locale get currentLocale => _currentLocale;

  Future<void> loadSavedLocale() async {
    final code = await _secureStorageService.read(StorageKeys.localeCode);
    if (code == null || code.isEmpty) {
      return;
    }

    _currentLocale =
        code == 'ar' ? const Locale('ar', 'EG') : const Locale('en', 'US');
    update();
  }

  Future<void> changeLocale(Locale locale) async {
    _currentLocale = locale;
    await _secureStorageService.write(StorageKeys.localeCode, locale.languageCode);
    Get.updateLocale(locale);
    update();
  }
}
