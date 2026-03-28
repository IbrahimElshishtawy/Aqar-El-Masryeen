import 'package:aqarelmasryeen/app/bindings/initial_binding.dart';
import 'package:aqarelmasryeen/app/routes/app_pages.dart';
import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/localization/app_translations.dart';
import 'package:aqarelmasryeen/core/localization/locale_service.dart';
import 'package:aqarelmasryeen/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

class AqarApp extends StatelessWidget {
  const AqarApp({super.key, required this.bootstrap});

  final BootstrapState bootstrap;

  @override
  Widget build(BuildContext context) {
    return InitialBindingScope(
      bootstrap: bootstrap,
      child: GetBuilder<LocaleService>(
        init: Get.find<LocaleService>(),
        builder: (localeService) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Aqar El Masryeen',
            theme: AppTheme.light(),
            translations: AppTranslations(),
            locale: localeService.currentLocale,
            fallbackLocale: AppTranslations.fallbackLocale,
            supportedLocales: AppTranslations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppPages.initial,
            getPages: AppPages.pages,
            defaultTransition: Transition.fadeIn,
            initialBinding: InitialBinding(bootstrap),
          );
        },
      ),
    );
  }
}

class InitialBindingScope extends StatelessWidget {
  const InitialBindingScope({
    super.key,
    required this.bootstrap,
    required this.child,
  });

  final BootstrapState bootstrap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BootstrapState>()) {
      Get.put<BootstrapState>(bootstrap, permanent: true);
    }
    return child;
  }
}
