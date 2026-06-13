import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class LocalAuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      // [Fix 1] දුරකථනයට කිසිදු Lock එකක් නැත්නම් කෙලින්ම ඇතුළට යවයි
      if (!canCheckBiometrics && !isDeviceSupported) {
        return true;
      }

      // [Fix 2] දුරකථනයේ Fingerprint හෝ Face Data Setup කර ඇත්දැයි බැලීම
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        // Emulator එකක වැනි Biometric Setup නොකළ තැනක App එක හිරවීම වළක්වයි
        return true;
      }

      // Compiler දෝෂ වළක්වා ගැනීමට options නොමැතිව ධාවනය කරයි
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
      );
    } on PlatformException catch (e) {
      print('Auth Error: ${e.code} - ${e.message}');

      // [Fix 3] දෝෂය පැමිණියේ Hardware නැතිකම හෝ Lock වීම නිසා නම් App එක Block නොකරයි
      if (e.code == 'NotAvailable' ||
          e.code == 'NotEnrolled' ||
          e.code == 'LockedOut' ||
          e.code == 'PermanentlyLockedOut') {
        return true;
      }
      return false;
    }
  }
}