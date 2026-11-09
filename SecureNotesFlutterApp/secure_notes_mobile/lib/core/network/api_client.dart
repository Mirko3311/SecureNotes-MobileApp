import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:secure_notes_mobile/core/network/api_config.dart';

class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<http.Response> get({required String path, String? bearerToken}) async {
    try {
      return await _httpClient
          .get(
            _buildUri(path),
            headers: _buildHeaders(bearerToken: bearerToken),
          )
          .timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw const SocketException('Nema internet konekcije.');
    }
  }

  Future<http.Response> post({
    required String path,
    String? bearerToken,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _httpClient
          .post(
            _buildUri(path),
            headers: _buildHeaders(
              bearerToken: bearerToken,
              hasJsonBody: body != null,
            ),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw const SocketException('Nema internet konekcije.');
    }
  }

  Future<http.Response> put({
    required String path,
    String? bearerToken,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _httpClient
          .put(
            _buildUri(path),
            headers: _buildHeaders(
              bearerToken: bearerToken,
              hasJsonBody: body != null,
            ),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw const SocketException('Nema internet konekcije.');
    }
  }

  Future<http.Response> delete({
    required String path,
    String? bearerToken,
  }) async {
    try {
      return await _httpClient
          .delete(
            _buildUri(path),
            headers: _buildHeaders(bearerToken: bearerToken),
          )
          .timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw const SocketException('Nema internet konekcije.');
    }
  }

  Uri _buildUri(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Map<String, String> _buildHeaders({
    String? bearerToken,
    bool hasJsonBody = false,
  }) {
    return {
      'Accept': 'application/json',
      if (hasJsonBody) 'Content-Type': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    };
  }

  void close() {
    _httpClient.close();
  }
}
