import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/network/api_client.dart';
import 'package:secure_notes_mobile/features/auth/models/login_response.dart';
import 'package:secure_notes_mobile/features/auth/models/totp_enrollment_response.dart';
import 'package:secure_notes_mobile/features/auth/models/access_token_response.dart';
import 'package:secure_notes_mobile/features/auth/models/register_response.dart';

class AuthApiService {
  final ApiClient _apiClient;
  AuthApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> requestBody = {
      'email': email.trim(),
      'password': password,
    };

    final http.Response response = await _apiClient.post(
      path: '/api/auth/login',
      body: requestBody,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return LoginResponse.fromJson(responseBody);
    }
    if (response.statusCode == 401) {
      throw ApiException(
        'Neispravna email adresa ili lozinka',
        statusCode: 401,
      );
    }
    if (response.statusCode == 429) {
      throw ApiException(
        'Previše neuspješnih pokušaja prijave. Pokušajte ponovo za 15 minuta.',
        statusCode: 429,
      );
    }
    throw ApiException(
      'Prijava trenutno nije moguća. Pokušajte ponovo kasnije.',
      statusCode: response.statusCode,
    );
  }

  Future<TotpEnrollmentResponse> startTotpEnrollment({
    required String preMfaToken,
  }) async {
    final http.Response response = await _apiClient.post(
      path: '/api/auth/totp/enrollment',
      bearerToken: preMfaToken,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return TotpEnrollmentResponse.fromJson(responseBody);
    }

    throw Exception(
      'Pokretanje TOTP registracije nije uspjelo. '
      'HTTP status: ${response.statusCode}',
    );
  }

  Future<AccessTokenResponse> verifyTotpEnrollment({
    required String preMfaToken,
    required String code,
  }) async {
    final Map<String, dynamic> requestBody = {'code': code.trim()};

    final http.Response response = await _apiClient.post(
      path: '/api/auth/totp/enrollment/verify',
      bearerToken: preMfaToken,
      body: requestBody,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return AccessTokenResponse.fromJson(responseBody);
    }

    String errorMessage = 'Provjera TOTP registracije nije uspjela';
    try {
      final Map<String, dynamic> errorBody =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (errorBody.containsKey('message')) {
        errorMessage = errorBody['message'] as String;
      }
    } catch (_) {}

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  Future<AccessTokenResponse> verifyTotpAuthentication({
    required String preMfaToken,
    required String code,
  }) async {
    final Map<String, dynamic> requestBody = {'code': code.trim()};

    final http.Response response = await _apiClient.post(
      path: '/api/auth/totp/authentication/verify',
      bearerToken: preMfaToken,
      body: requestBody,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return AccessTokenResponse.fromJson(responseBody);
    }

    String errorMessage = 'Provjera TOTP autentifikacije nije uspjela';
    try {
      final Map<String, dynamic> errorBody =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (errorBody.containsKey('message')) {
        errorMessage = errorBody['message'] as String;
      }
    } catch (_) {}
    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  Future<RegisterResponse> register({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> requestBody = {
      'email': email.trim(),
      'password': password,
    };

    final http.Response response = await _apiClient.post(
      path: '/api/auth/register',
      body: requestBody,
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return RegisterResponse.fromJson(responseBody);
    }
    if (response.statusCode == 409) {
      throw ApiException(
        'Email adresa je zauzeta',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 400) {
      throw ApiException(
        'Neispravni podaci za registraciju',
        statusCode: response.statusCode,
      );
    }
    throw ApiException(
      'Registracija nije uspjela. Pokušajte ponovo',
      statusCode: response.statusCode,
    );
  }
}
