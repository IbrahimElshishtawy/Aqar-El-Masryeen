import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes egyptian local phone numbers to e164', () {
    expect(PhoneUtils.normalize('01012345678'), '+201012345678');
  });

  test('builds deterministic synthetic auth email from phone', () {
    expect(
      PhoneUtils.syntheticEmail('+201012345678'),
      'auth_201012345678@auth.aqarelmasryeen.app',
    );
  });
}
