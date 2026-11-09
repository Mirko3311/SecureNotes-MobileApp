import 'package:flutter/material.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/auth/models/login_response.dart';
import 'package:secure_notes_mobile/features/auth/screens/register_screen.dart';
import 'package:secure_notes_mobile/features/auth/services/auth_api_service.dart';
import 'package:secure_notes_mobile/features/auth/screens/totp_authentication_screen.dart';
import 'package:secure_notes_mobile/features/auth/screens/totp_enrollment_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final AuthApiService _authApiService = AuthApiService();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _openRegisterScreen() async {
    final String? registeredEmail = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) {
          return const RegisterScreen();
        },
      ),
    );

    if (!mounted || registeredEmail == null) {
      return;
    }

    _emailController.text = registeredEmail;
    _passwordController.clear();

    await showInfoDialog(
      context,
      title: 'Registracija uspješna',
      message: 'Prijavite se i podesite aplikaciju za autentifikaciju',
    );
  }

  Future<void> _submitLogin() async {
    final bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final LoginResponse loginResponse = await _authApiService.login(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (loginResponse.purpose == 'TOTP_ENROLLMENT') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return TotpEnrollmentScreen(
                preMfaToken: loginResponse.preMfaToken,
              );
            },
          ),
        );

        return;
      }

      if (loginResponse.purpose == 'TOTP_AUTHENTICATION') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return TotpAuthenticationScreen(
                preMfaToken: loginResponse.preMfaToken,
                expiresAt: loginResponse.expiresAt,
              );
            },
          ),
        );

        return;
      }

      await showErrorDialog(
        context,
        title: 'Prijava nije uspjela',
        message: 'Prijava nije uspjela',
      );
    } on ApiException catch (apiError) {
      if (!mounted) {
        return;
      }

      await showErrorDialog(
        context,
        title: 'Prijava nije uspjela',
        message: apiError.message,
      );
    } catch (error) {
      debugPrint('Greška prilikom prijave: $error');
      if (!mounted) {
        return;
      }

      await showErrorDialog(
        context,
        title: 'Server nije dostupan',
        message: 'Provjerite internet vezu i pokušajte ponovo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Notes'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Prijava',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pristupite svojim privatnim bilješkama',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'korisnik@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Unesite email adresu';
                      }
                      if (!emailPattern.hasMatch(value.trim())) {
                        return 'Unesite ispravnu email adresu';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Lozinka',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Unesite lozinku';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submitLogin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Prijavi se'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _openRegisterScreen,
                    child: const Text('Nemate nalog? Registrujte se'),
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
