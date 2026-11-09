package org.unibl.etf.securenotes.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.unibl.etf.securenotes.dto.note.NoteCreateRequest;
import org.unibl.etf.securenotes.dto.note.NoteResponse;
import org.unibl.etf.securenotes.dto.note.NoteUpdateRequest;
import org.unibl.etf.securenotes.entity.Note;
import org.unibl.etf.securenotes.entity.UserAccount;
import org.unibl.etf.securenotes.entity.UserStatus;
import org.unibl.etf.securenotes.exception.InvalidCredentialsException;
import org.unibl.etf.securenotes.exception.NoteNotFoundException;
import org.unibl.etf.securenotes.repository.NoteRepository;
import org.unibl.etf.securenotes.repository.UserAccountRepository;

import java.util.List;

@Service
public class NoteService {

    private final NoteRepository noteRepository;
    private final UserAccountRepository
            userAccountRepository;

    public NoteService(
            NoteRepository noteRepository,
            UserAccountRepository userAccountRepository
    ) {
        this.noteRepository = noteRepository;
        this.userAccountRepository =
                userAccountRepository;
    }

    @Transactional
    public NoteResponse createNote(
            Long userId,
            NoteCreateRequest request
    ) {
        UserAccount userAccount =
                loadActiveUser(userId);

        Note note = new Note(
                userAccount,
                request.title().trim(),
                request.content()
        );

        Note savedNote =
                noteRepository.saveAndFlush(note);

        return toResponse(savedNote);
    }

    @Transactional(readOnly = true)
    public List<NoteResponse> getAllNotes(
            Long userId
    ) {
        loadActiveUser(userId);

        return noteRepository
                .findAllByUserAccountIdOrderByUpdatedAtDesc(
                        userId
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public NoteResponse getNote(
            Long userId,
            Long noteId
    ) {
        loadActiveUser(userId);

        Note note = loadOwnedNote(
                noteId,
                userId
        );

        return toResponse(note);
    }

    @Transactional
    public NoteResponse updateNote(
            Long userId,
            Long noteId,
            NoteUpdateRequest request
    ) {
        loadActiveUser(userId);

        Note note = loadOwnedNote(
                noteId,
                userId
        );
        note.update(
                request.title().trim(),
                request.content()
        );

        return toResponse(note);
    }

    @Transactional
    public void deleteNote(
            Long userId,
            Long noteId
    ) {
        loadActiveUser(userId);

        Note note = loadOwnedNote(
                noteId,
                userId
        );

        noteRepository.delete(note);
    }

    private UserAccount loadActiveUser(
            Long userId
    ) {
        UserAccount userAccount =
                userAccountRepository
                        .findById(userId)
                        .orElseThrow(
                                InvalidCredentialsException::new
                        );

        if (userAccount.getStatus()
                != UserStatus.ACTIVE) {

            throw new InvalidCredentialsException();
        }

        return userAccount;
    }

    private Note loadOwnedNote(
            Long noteId,
            Long userId
    ) {
        return noteRepository
                .findByIdAndUserAccountId(
                        noteId,
                        userId
                )
                .orElseThrow(
                        NoteNotFoundException::new
                );
    }

    private NoteResponse toResponse(
            Note note
    ) {
        return new NoteResponse(
                note.getId(),
                note.getTitle(),
                note.getContent(),
                note.getCreatedAt(),
                note.getUpdatedAt()
        );
    }
}