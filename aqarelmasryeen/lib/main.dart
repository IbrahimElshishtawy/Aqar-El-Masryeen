import 'package:aqarelmasryeen/app/app.dart';
import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  runApp(AqarApp(bootstrap: bootstrap));
}
