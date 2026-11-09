import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics =
          await _localAuthentication.canCheckBiometrics;

      final List<BiometricType> availableBiometrics = await _localAuthentication
          .getAvailableBiometrics();

      return canCheckBiometrics && availableBiometrics.isNotEmpty;
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        return false;
      }

      final bool isAuthenticated = await _localAuthentication.authenticate(
        localizedReason: 'Potvrdite identitet za pristup privatnim bilješkama.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      return isAuthenticated;
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
