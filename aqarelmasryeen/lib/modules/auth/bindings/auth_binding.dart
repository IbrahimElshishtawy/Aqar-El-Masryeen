import 'package:aqarelmasryeen/modules/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(AuthController.new, fenix: true);
  }
}
