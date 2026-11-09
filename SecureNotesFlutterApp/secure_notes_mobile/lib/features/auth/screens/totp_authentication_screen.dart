import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_notes_mobile/core/auth/session_gate.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/storage/token_storage_service.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/auth/models/access_token_response.dart';
import 'package:secure_notes_mobile/features/auth/screens/login_screen.dart';
import 'package:secure_notes_mobile/features/auth/services/auth_api_service.dart';
import 'package:intl/intl.dart';

class TotpAuthenticationScreen extends StatefulWidget {
  final String preMfaToken;
  final DateTime expiresAt;

  const TotpAuthenticationScreen({
    super.key,
    required this.preMfaToken,
    required this.expiresAt,
  });

  @override
  State<TotpAuthenticationScreen> createState() {
    return _TotpAuthenticationScreenState();
  }
}

class _TotpAuthenticationScreenState extends State<TotpAuthenticationScreen> {
  final AuthApiService _authApiService = AuthApiService();

  final TokenStorageService _tokenStorageService = TokenStorageService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();

  bool _isVerifying = false;
  String? _codeError;
  Future<void> _verifyAuthenticationCode() async {
    final bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final AccessTokenResponse accessTokenResponse = await _authApiService
          .verifyTotpAuthentication(
            preMfaToken: widget.preMfaToken,
            code: _codeController.text,
          );

      try {
        await _tokenStorageService.saveAccessToken(
          accessToken: accessTokenResponse.accessToken,
          tokenType: accessTokenResponse.tokenType,
          expiresAt: accessTokenResponse.expiresAt,
        );
      } catch (storageError) {
        if (!mounted) {
          return;
        }

        await showErrorDialog(
          context,
          title: 'Prijava nije završena',
          message: 'Sesija nije mogla biti sigurno sačuvana. Pokušajte ponovo',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const SessionGate(startAuthenticated: true);
          },
        ),
        (Route<dynamic> route) => false,
      );
    } on ApiException catch (apiError) {
      if (!mounted) {
        return;
      }
      if (apiError.statusCode == 400) {
        setState(() {
          _codeError = apiError.message;
        });
        _codeController.clear();
        return;
      }
      if (apiError.statusCode == 401) {
        await showErrorDialog(
          context,
          title: 'Prijava je prekinuta',
          message:
              'Iskoristili ste pokušaje ili je vrijeme isteklo. Prijavite se ponovo',
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) => const LoginScreen(),
          ),
          (Route<dynamic> route) => false,
        );
        return;
      }
      await showErrorDialog(
        context,
        title: 'Provjera nije uspjela',
        message: apiError.message,
      );
    } catch (error) {
      debugPrint('Greška pri TOTP autentifikaciji: $error');
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: 'Server nije dostupan',
        message: 'Pokušajte ponovo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOTP provjera'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Otkaži prijavu',
            onPressed: _isVerifying
                ? null
                : () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.password, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    'Potvrdite prijavu',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unesite trenutni šestocifreni kod '
                    'iz aplikacije za autentifikaciju',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MFA postupak ističe: ${DateFormat('dd.MM.yyyy. u HH:mm:ss').format(widget.expiresAt.toLocal())}',

                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codeController,
                    forceErrorText: _codeError,
                    onChanged: (_) {
                      if (_codeError != null) {
                        setState(() {
                          _codeError = null;
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'TOTP kod',
                      hintText: '123456',
                      prefixIcon: Icon(Icons.password),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (String? value) {
                      final String code = value?.trim() ?? '';

                      if (code.isEmpty) {
                        return 'Unesite TOTP kod';
                      }

                      if (code.length != 6) {
                        return 'TOTP kod mora imati '
                            'tačno šest cifara';
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_isVerifying) {
                        _verifyAuthenticationCode();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isVerifying ? null : _verifyAuthenticationCode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Potvrdi prijavu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
