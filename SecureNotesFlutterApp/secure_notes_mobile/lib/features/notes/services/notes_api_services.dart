import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/features/notes/models/note.dart';
import 'package:secure_notes_mobile/core/network/api_client.dart';

class NotesApiService {
  final ApiClient _apiClient;

  NotesApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<Note>> getAllNotes({required String accessToken}) async {
    final http.Response response = await _apiClient.get(
      path: '/api/notes',
      bearerToken: accessToken,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> responseBody =
          jsonDecode(response.body) as List<dynamic>;

      return responseBody
          .map((dynamic item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 401) {
      throw ApiException(
        'Sesija je istekla. Prijavite se ponovo.',
        statusCode: 401,
      );
    }

    throw ApiException(
      'Učitavanje bilješki nije uspjelo.',
      statusCode: response.statusCode,
    );
  }

  Future<Note> createNote({
    required String accessToken,
    required String title,
    required String content,
  }) async {
    final Map<String, dynamic> requestBody = {
      'title': title.trim(),
      'content': content.trim(),
    };

    final http.Response response = await _apiClient.post(
      path: '/api/notes',
      bearerToken: accessToken,
      body: requestBody,
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return Note.fromJson(responseBody);
    }
    if (response.statusCode == 401) {
      throw ApiException(
        'Sesija je istekla. Prijavite se ponovo.',
        statusCode: 401,
      );
    }
    throw ApiException(
      'Kreiranje bilješke nije uspjelo.',
      statusCode: response.statusCode,
    );
  }

  Future<Note> updateNote({
    required String accessToken,
    required int noteId,
    required String title,
    required String content,
  }) async {
    final Map<String, dynamic> requestBody = {
      'title': title.trim(),
      'content': content.trim(),
    };

    final http.Response response = await _apiClient.put(
      path: '/api/notes/$noteId',
      bearerToken: accessToken,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      return Note.fromJson(responseBody);
    }

    if (response.statusCode == 401) {
      throw ApiException(
        'Sesija je istekla. Prijavite se ponovo.',
        statusCode: 401,
      );
    }

    throw ApiException(
      'Izmjena bilješke nije uspjela.',
      statusCode: response.statusCode,
    );
  }

  Future<void> deleteNote({
    required String accessToken,
    required int noteId,
  }) async {
    final http.Response response = await _apiClient.delete(
      path: '/api/notes/$noteId',
      bearerToken: accessToken,
    );

    if (response.statusCode == 204) {
      return;
    }
    if (response.statusCode == 401) {
      throw ApiException(
        'Sesija je istekla. Prijavite se ponovo.',
        statusCode: 401,
      );
    }
    throw ApiException(
      'Brisanje bilješke nije uspjelo.',
      statusCode: response.statusCode,
    );
  }
}
