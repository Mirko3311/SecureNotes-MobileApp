import 'package:flutter/material.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/network/unauthorized_exception.dart';
import 'package:secure_notes_mobile/core/storage/token_storage_service.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/auth/screens/login_screen.dart';
import 'package:secure_notes_mobile/features/notes/models/note.dart';
import 'package:secure_notes_mobile/features/notes/screens/note_form_screen.dart';
import 'package:secure_notes_mobile/features/notes/services/notes_api_services.dart';

enum NoteDetailResult { updated, deleted }

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() {
    return _NoteDetailScreenState();
  }
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final TokenStorageService _tokenStorageService = TokenStorageService();

  final NotesApiService _notesApiService = NotesApiService();

  bool _isDeleting = false;

  Future<bool> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Izbrisati bilješku?'),
          content: const Text(
            'Da li ste sigurni da želite trajno izbrisati ovu bilješku?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Izbriši'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
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
          content: const Text('Potrebno je da se prijavite ponovo.'),
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

  Future<void> _deleteNote() async {
    if (_isDeleting) {
      return;
    }

    final bool confirmed = await _confirmDelete();

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final String? accessToken = await _tokenStorageService.readAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const UnauthorizedException();
      }

      await _notesApiService.deleteNote(
        accessToken: accessToken,
        noteId: widget.note.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(NoteDetailResult.deleted);
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
        title: 'Bilješka nije izbrisana',
        message: error.message,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('Greška pri brisanju bilješke: $error');

      await showErrorDialog(
        context,
        title: 'Bilješka nije izbrisana',
        message: 'Server nije dostupan. Pokušajte ponovo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _editNote(BuildContext context) async {
    final Note? updatedNote = await Navigator.of(context).push<Note>(
      MaterialPageRoute<Note>(
        builder: (BuildContext context) {
          return NoteFormScreen(note: widget.note);
        },
      ),
    );

    if (!context.mounted || updatedNote == null) {
      return;
    }

    Navigator.of(context).pop(NoteDetailResult.updated);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.10),
        colorScheme.surface,
      ),
      appBar: AppBar(
        title: const Text('Detalji bilješke'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isDeleting
                ? null
                : () {
                    _editNote(context);
                  },
            tooltip: 'Izmijeni bilješku',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _isDeleting ? null : _deleteNote,
            tooltip: 'Izbriši bilješku',
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 5, color: colorScheme.primary),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.note_alt_outlined,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SelectableText(
                              widget.note.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      SelectableText(
                        widget.note.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      Divider(color: colorScheme.outlineVariant),
                      const SizedBox(height: 14),
                      _buildDateRow(
                        context: context,
                        icon: Icons.add_circle_outline,
                        label: 'Kreirano',
                        dateTime: widget.note.createdAt,
                      ),
                      const SizedBox(height: 10),
                      _buildDateRow(
                        context: context,
                        icon: Icons.update,
                        label: 'Posljednja izmjena',
                        dateTime: widget.note.updatedAt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required DateTime dateTime,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            _formatDateTime(dateTime),
            textAlign: TextAlign.end,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final DateTime localDateTime = dateTime.toLocal();

    final String day = localDateTime.day.toString().padLeft(2, '0');

    final String month = localDateTime.month.toString().padLeft(2, '0');

    final String year = localDateTime.year.toString();

    final String hour = localDateTime.hour.toString().padLeft(2, '0');

    final String minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day.$month.$year. $hour:$minute';
  }
}
