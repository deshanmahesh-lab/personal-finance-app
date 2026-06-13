import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class LocalAuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true;
      }

      // [වෙනස] Version Conflicts මඟහැරීම සඳහා 'options' පරාමිතිය ඉවත් කර ඇත.
      // මෙය සියලුම local_auth සංස්කරණ සඳහා දෝෂයකින් තොරව ක්‍රියාත්මක වේ.
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
      );
    } on PlatformException catch (e) {
      print('Auth Error: $e');
      return false;
    }
  }
}