import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../storage/token_storage_service.dart';
import 'biometric_auth_service.dart';

enum _SessionStatus { loading, loginRequired, biometricFailed, authenticated }

class SessionGate extends StatefulWidget {
  final bool startAuthenticated;
  const SessionGate({super.key, this.startAuthenticated = false});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  final TokenStorageService _tokenStorageService = TokenStorageService();

  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  _SessionStatus _status = _SessionStatus.loading;

  bool _isAuthenticating = false;

  static const Duration _backgroundLockDelay = Duration(seconds: 10);
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    if (widget.startAuthenticated) {
      _status = _SessionStatus.authenticated;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _handleAppBackgrounded();
    }

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppBackgrounded() {
    if (_status != _SessionStatus.authenticated ||
        _isAuthenticating ||
        _backgroundedAt != null) {
      return;
    }

    _backgroundedAt = DateTime.now();
  }

  Future<void> _handleAppResumed() async {
    final DateTime? backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null || _isAuthenticating) {
      return;
    }
    final Duration timeInBackground = DateTime.now().difference(backgroundedAt);

    if (timeInBackground < _backgroundLockDelay) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _status = _SessionStatus.loading;
    });

    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);

    await _checkSession();
  }

  Future<void> _checkSession() async {
    final String? accessToken = await _tokenStorageService.readAccessToken();

    final DateTime? expiresAt = await _tokenStorageService.readExpiresAt();

    final DateTime now = DateTime.now().toUtc();

    final bool tokenIsMissing =
        accessToken == null || accessToken.trim().isEmpty;

    final bool tokenIsExpired =
        expiresAt == null || !expiresAt.toUtc().isAfter(now);

    if (tokenIsMissing || tokenIsExpired) {
      await _tokenStorageService.deleteAccessToken();

      if (!mounted) {
        return;
      }

      setState(() {
        _status = _SessionStatus.loginRequired;
      });

      return;
    }

    if (!mounted) {
      return;
    }
    await _unlockWithBiometrics();
  }

  Future<void> _unlockWithBiometrics() async {
    if (_isAuthenticating) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _status = _SessionStatus.loading;
    });

    final bool isAuthenticated = await _biometricAuthService.authenticate();

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticating = false;

      _status = isAuthenticated
          ? _SessionStatus.authenticated
          : _SessionStatus.biometricFailed;
    });
  }

  Future<void> _useFullLogin() async {
    await _tokenStorageService.deleteAccessToken();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = _SessionStatus.loginRequired;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _SessionStatus.loading:
        return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        );

      case _SessionStatus.loginRequired:
        return const LoginScreen();

      case _SessionStatus.authenticated:
        return const NotesScreen();

      case _SessionStatus.biometricFailed:
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fingerprint, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'Aplikacija je zaključana',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Potvrdite identitet biometrijom '
                      'za pristup privatnim bilješkama.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _unlockWithBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Pokušaj ponovo'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _useFullLogin,
                      child: const Text('Prijavi se lozinkom i TOTP kodom'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}
