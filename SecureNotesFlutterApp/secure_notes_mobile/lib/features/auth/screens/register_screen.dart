import 'package:flutter/material.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/auth/models/register_response.dart';
import 'package:secure_notes_mobile/features/auth/services/auth_api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthApiService _authApiService = AuthApiService();

  bool _isRegistering = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _emailError;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    if (_isRegistering) {
      return;
    }

    final FormState? formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final RegisterResponse response = await _authApiService.register(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(response.email);
    } on ApiException catch (apiError) {
      if (!mounted) {
        return;
      }

      if (apiError.statusCode == 409) {
        setState(() {
          _emailError = apiError.message;
        });
      } else {
        await showErrorDialog(
          context,
          title: 'Registracija nije uspjela',
          message: apiError.message,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('Greška pri registraciji: $error');
      await showErrorDialog(
        context,
        title: 'Server nije dostupan',
        message: 'Provjerite internet vezu i pokušajte ponovo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email adresa je obavezna';
    }

    if (email.length > 254) {
      return 'Email adresa može imati najviše 254 znaka';
    }

    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return 'Email adresa nije ispravna';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Lozinka je obavezna';
    }

    if (password.length < 8 || password.length > 128) {
      return 'Lozinka mora imati između 8 i 128 znakova';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final String confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Potvrda lozinke je obavezna';
    }

    if (confirmPassword != _passwordController.text) {
      return 'Lozinke se ne podudaraju';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.08),
        colorScheme.surface,
      ),
      appBar: AppBar(title: const Text('Registracija'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 5, color: colorScheme.primary),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 64,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kreirajte korisnički nalog',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _emailController,
                                enabled: !_isRegistering,
                                validator: _validateEmail,
                                forceErrorText: _emailError,
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() {
                                      _emailError = null;
                                    });
                                  }
                                },
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: 'Email adresa',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isRegistering,
                                validator: _validatePassword,
                                obscureText: _hidePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Lozinka',
                                  helperText:
                                      'Najmanje 8, a najviše 128 znakova',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: _isRegistering
                                        ? null
                                        : () {
                                            setState(() {
                                              _hidePassword = !_hidePassword;
                                            });
                                          },
                                    tooltip: _hidePassword
                                        ? 'Prikaži lozinku'
                                        : 'Sakrij lozinku',
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !_isRegistering,
                                validator: _validateConfirmPassword,
                                obscureText: _hideConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  _register();
                                },
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Potvrdite lozinku',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: _isRegistering
                                        ? null
                                        : () {
                                            setState(() {
                                              _hideConfirmPassword =
                                                  !_hideConfirmPassword;
                                            });
                                          },
                                    tooltip: _hideConfirmPassword
                                        ? 'Prikaži lozinku'
                                        : 'Sakrij lozinku',
                                    icon: Icon(
                                      _hideConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _isRegistering ? null : _register,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: const StadiumBorder(),
                                ),
                                icon: _isRegistering
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.person_add_outlined),
                                label: Text(
                                  _isRegistering
                                      ? 'Registracija...'
                                      : 'Registrujte se',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _isRegistering
                                    ? null
                                    : () {
                                        Navigator.of(context).pop();
                                      },
                                child: const Text(
                                  'Već imate nalog? Prijavite se',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
