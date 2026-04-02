import 'package:aqarelmasryeen/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
