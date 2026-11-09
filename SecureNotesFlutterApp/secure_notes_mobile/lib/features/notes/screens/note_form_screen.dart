import 'package:flutter/material.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/network/unauthorized_exception.dart';
import 'package:secure_notes_mobile/core/storage/token_storage_service.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/auth/screens/login_screen.dart';
import 'package:secure_notes_mobile/features/notes/models/note.dart';
import 'package:secure_notes_mobile/features/notes/services/notes_api_services.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;
  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() {
    return _NoteFormScreenState();
  }
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;

  late final TextEditingController _contentController;

  final TokenStorageService _tokenStorageService = TokenStorageService();

  final NotesApiService _notesApiService = NotesApiService();

  bool _isSaving = false;

  bool get _isEditing {
    return widget.note != null;
  }

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title ?? '');

    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  Future<void> _handleSessionExpired() async {
    await _tokenStorageService.deleteAccessToken();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sesija je istekla'),
          content: const Text('Prijavite se ponovo'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Prijavi se ponovo'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const LoginScreen();
        },
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _saveNote() async {
    if (_isSaving) {
      return;
    }

    final FormState? formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String? accessToken = await _tokenStorageService.readAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const UnauthorizedException();
      }

      final Note savedNote;

      if (_isEditing) {
        savedNote = await _notesApiService.updateNote(
          accessToken: accessToken,
          noteId: widget.note!.id,
          title: _titleController.text,
          content: _contentController.text,
        );
      } else {
        savedNote = await _notesApiService.createNote(
          accessToken: accessToken,
          title: _titleController.text,
          content: _contentController.text,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(savedNote);
    } on UnauthorizedException {
      await _handleSessionExpired();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }

      if (!mounted) {
        return;
      }

      await showErrorDialog(
        context,
        title: 'Bilješka nije sačuvana',
        message: error.message,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('Greska pri cuvanju biljeske: $error');

      await showErrorDialog(
        context,
        title: 'Bilješka nije sačuvana',
        message: 'Server nije dostupan. Pokušajte ponovo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateTitle(String? value) {
    final String title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Naslov bilješke je obavezan';
    }

    if (title.length > 200) {
      return 'Naslov može sadržati najviše 200 znakova';
    }

    return null;
  }

  String? _validateContent(String? value) {
    final String content = value?.trim() ?? '';

    if (content.isEmpty) {
      return 'Sadržaj bilješke je obavezan';
    }

    if (content.length > 20000) {
      return 'Sadržaj može sadržati najviše 20000 znakova';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.10),
        colorScheme.surface,
      ),
      body: Column(
        children: [
          _buildHeader(colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: _buildFormCard(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    tooltip: 'Nazad',
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Izmijeni bilješku' : 'Nova bilješka',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing ? 'Uredi svoju bilješku' : 'Sačuvaj svoju bilješku',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        children: [
          Container(height: 5, color: colorScheme.primary),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSaving,
                    maxLength: 200,
                    validator: _validateTitle,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Naslov',
                      hintText: 'Npr. Plan za danas',
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: Color.alphaBlend(
                        colorScheme.primary.withValues(alpha: 0.06),
                        colorScheme.surface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentController,
                    enabled: !_isSaving,
                    maxLength: 20000,
                    minLines: 8,
                    maxLines: 12,
                    validator: _validateContent,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'Sadržaj',
                      hintText: 'Zapiši detalje...',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 170),
                        child: Icon(Icons.notes),
                      ),
                      filled: true,
                      fillColor: Color.alphaBlend(
                        colorScheme.primary.withValues(alpha: 0.06),
                        colorScheme.surface,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Privatna bilješka',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                          ),
                          child: const Text('Odustani'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveNote,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            shape: const StadiumBorder(),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _isSaving
                                ? 'Čuvanje...'
                                : _isEditing
                                ? 'Izmijeni'
                                : 'Sačuvaj',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
