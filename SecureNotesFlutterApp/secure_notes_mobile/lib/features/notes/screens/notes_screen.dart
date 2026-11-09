import 'package:flutter/material.dart';
import 'package:secure_notes_mobile/core/exceptions/api_exception.dart';
import 'package:secure_notes_mobile/core/widgets/app_dialog.dart';
import 'package:secure_notes_mobile/features/notes/screens/note_detail_screen.dart';
import 'package:secure_notes_mobile/features/notes/screens/note_form_screen.dart';
import 'package:secure_notes_mobile/core/storage/token_storage_service.dart';
import 'package:secure_notes_mobile/features/auth/screens/login_screen.dart';
import 'package:secure_notes_mobile/features/notes/models/note.dart';
import 'package:secure_notes_mobile/features/notes/services/notes_api_services.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() {
    return _NotesScreenState();
  }
}

class _NotesScreenState extends State<NotesScreen> {
  final TokenStorageService _tokenStorageService = TokenStorageService();
  final NotesApiService _notesApiService = NotesApiService();

  List<Note> _notes = [];
  bool _isLoadingNotes = true;
  String? _notesError;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _tokenStorageService.deleteAccessToken();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const LoginScreen();
          },
        ),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: 'Odjava nije uspjela',
        message: 'Pokušajte ponovo',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoadingNotes = true;
      _notesError = null;
    });

    try {
      final String? accessToken = await _tokenStorageService.readAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw ApiException('Pristupni token nije pronađen', statusCode: 401);
      }

      final List<Note> loadedNotes = await _notesApiService.getAllNotes(
        accessToken: accessToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notes = loadedNotes;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
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
              content: const Text(
                'Radi zaštite privatnih bilješki, '
                'potrebno je da se prijavite ponovo',
              ),
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
      } else {
        if (!mounted) {
          return;
        }
        setState(() {
          _notesError = error.message;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('Greška prilikom učitavanja bilješki: $error');
      setState(() {
        _notesError = 'Provjerite internet vezu i pokušajte ponovo';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
        });
      }
    }
  }

  Future<void> _openCreateNoteScreen() async {
    final Note? createdNote = await Navigator.of(context).push<Note>(
      MaterialPageRoute<Note>(
        builder: (BuildContext context) {
          return const NoteFormScreen();
        },
      ),
    );

    if (!mounted || createdNote == null) {
      return;
    }

    setState(() {
      _notes.insert(0, createdNote);
    });

    await showSuccessDialog(context, message: 'Bilješka je uspješno kreirana');
  }

  Future<void> _openNoteDetails(Note note) async {
    final NoteDetailResult? result = await Navigator.of(context)
        .push<NoteDetailResult>(
          MaterialPageRoute<NoteDetailResult>(
            builder: (BuildContext context) {
              return NoteDetailScreen(note: note);
            },
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    await _loadNotes();

    if (!mounted) {
      return;
    }

    final String message = result == NoteDetailResult.updated
        ? 'Bilješka je uspješno izmijenjena.'
        : 'Bilješka je uspješno izbrisana.';

    await showSuccessDialog(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4C5696);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F7),
      appBar: AppBar(
        title: const Text(
          'Privatne bilješke',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF3B3B66), Color(0xFF725475)],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            tooltip: 'Odjava',
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateNoteScreen,
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        tooltip: 'Kreiraj bilješku',
        icon: const Icon(Icons.add),
        label: const Text('Kreiraj bilješku'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingNotes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Bilješke nije moguće učitati',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(_notesError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadNotes,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.note_alt_outlined, size: 80),
              SizedBox(height: 16),
              Text(
                'Nemate sačuvanih bilješki',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Kada kreirate prvu bilješku, '
                'ona će biti prikazana ovdje',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (BuildContext itemContext, int index) {
          final Note note = _notes[index];

          return Card(
            elevation: 1,
            shadowColor: Colors.black26,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF4C5696), width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C5696).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: Color(0xFF4C5696),
                ),
              ),
              title: Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                _openNoteDetails(note);
              },
            ),
          );
        },
      ),
    );
  }
}
