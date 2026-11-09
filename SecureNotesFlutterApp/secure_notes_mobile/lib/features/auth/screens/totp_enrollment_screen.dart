import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_notes_mobile/core/auth/session_gate.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/auth/models/totp_enrollment_response.dart';
import 'package:secure_notes_mobile/features/auth/screens/login_screen.dart';
import 'package:secure_notes_mobile/features/auth/services/auth_api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:secure_notes_mobile/features/auth/models/access_token_response.dart';
import 'package:secure_notes_mobile/core/storage/token_storage_service.dart';
import 'package:intl/intl.dart';

class TotpEnrollmentScreen extends StatefulWidget {
  final String preMfaToken;

  const TotpEnrollmentScreen({super.key, required this.preMfaToken});

  @override
  State<TotpEnrollmentScreen> createState() {
    return _TotpEnrollmentScreenState();
  }
}

class _TotpEnrollmentScreenState extends State<TotpEnrollmentScreen> {
  final AuthApiService _authApiService = AuthApiService();

  TotpEnrollmentResponse? _enrollmentResponse;

  bool _isLoading = true;

  String? _errorMessage;

  final TokenStorageService _tokenStorageService = TokenStorageService();

  final GlobalKey<FormState> _codeFormKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();

  bool _isVerifying = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _loadEnrollmentData();
  }

  Future<void> _loadEnrollmentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final TotpEnrollmentResponse response = await _authApiService
          .startTotpEnrollment(preMfaToken: widget.preMfaToken);

      if (!mounted) {
        return;
      }

      setState(() {
        _enrollmentResponse = response;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'TOTP podaci nisu mogli biti učitani';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyEnrollmentCode() async {
    final bool isFormValid = _codeFormKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final AccessTokenResponse accessTokenResponse = await _authApiService
          .verifyTotpEnrollment(
            preMfaToken: widget.preMfaToken,
            code: _codeController.text,
          );

      await _tokenStorageService.saveAccessToken(
        accessToken: accessTokenResponse.accessToken,
        tokenType: accessTokenResponse.tokenType,
        expiresAt: accessTokenResponse.expiresAt,
      );

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
      debugPrint(
        'Greška pri podeša: '
        '$error',
      );

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
        title: const Text('Podešavanje TOTP-a'),
        centerTitle: true,
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
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadEnrollmentData,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final TotpEnrollmentResponse enrollment = _enrollmentResponse!;
    final localDateTime = enrollment.expiresAt.toLocal();
    final formattedDateTime = DateFormat(
      'dd.MM.yyyy HH:mm:ss',
    ).format(localDateTime);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: QrImageView(
              data: enrollment.otpauthUri,
              version: QrVersions.auto,
              size: 220,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Povežite aplikaciju za autentifikaciju',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Dodajte novi nalog u aplikaciji za '
            'autentifikaciju koristeći QR kod ili '
            'ručni ključ',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text('Izdavalac', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(enrollment.issuer),
          const SizedBox(height: 20),
          Text(
            'Korisnički nalog',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(enrollment.accountName),
          const SizedBox(height: 20),
          Text('Ručni ključ', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                enrollment.manualEntryKey,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MFA transakcija ističe: $formattedDateTime',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 32),
          Form(
            key: _codeFormKey,
            child: TextFormField(
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
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Šestocifreni TOTP kod',
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
                  return 'TOTP kod mora imati tačno šest cifara';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!_isVerifying) {
                  _verifyEnrollmentCode();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isVerifying ? null : _verifyEnrollmentCode,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Potvrdi kod'),
            ),
          ),
        ],
      ),
    );
  }
}
