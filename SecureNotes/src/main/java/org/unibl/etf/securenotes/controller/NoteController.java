package org.unibl.etf.securenotes.controller;

import org.unibl.etf.securenotes.exception.InvalidAccessTokenException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
        import org.unibl.etf.securenotes.dto.note.NoteCreateRequest;
import org.unibl.etf.securenotes.dto.note.NoteResponse;
import org.unibl.etf.securenotes.dto.note.NoteUpdateRequest;
import org.unibl.etf.securenotes.service.NoteService;

import java.util.List;

@RestController
@RequestMapping("/api/notes")
public class NoteController {

    private final NoteService noteService;

    public NoteController(
            NoteService noteService
    ) {
        this.noteService = noteService;
    }

    @PostMapping
    public ResponseEntity<NoteResponse> createNote(
            @AuthenticationPrincipal Jwt jwt,
            @Valid
            @RequestBody
            NoteCreateRequest request
    ) {
        Long userId = extractUserId(jwt);

        NoteResponse response =
                noteService.createNote(
                        userId,
                        request
                );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @GetMapping
    public ResponseEntity<List<NoteResponse>>
    getAllNotes(
            @AuthenticationPrincipal Jwt jwt
    ) {
        Long userId = extractUserId(jwt);

        List<NoteResponse> response =
                noteService.getAllNotes(userId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{noteId}")
    public ResponseEntity<NoteResponse> getNote(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long noteId
    ) {
        Long userId = extractUserId(jwt);

        NoteResponse response =
                noteService.getNote(
                        userId,
                        noteId
                );

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{noteId}")
    public ResponseEntity<NoteResponse> updateNote(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long noteId,
            @Valid
            @RequestBody
            NoteUpdateRequest request
    ) {
        Long userId = extractUserId(jwt);

        NoteResponse response =
                noteService.updateNote(
                        userId,
                        noteId,
                        request
                );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{noteId}")
    public ResponseEntity<Void> deleteNote(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long noteId
    ) {
        Long userId = extractUserId(jwt);

        noteService.deleteNote(
                userId,
                noteId
        );

        return ResponseEntity
                .noContent()
                .build();
    }

    private Long extractUserId(
            Jwt jwt
    ) {
        if (jwt == null) {
            throw new InvalidAccessTokenException();
        }

        String subject = jwt.getSubject();

        if (subject == null
                || subject.isBlank()) {

            throw new InvalidAccessTokenException();
        }

        try {
            long userId =
                    Long.parseLong(subject);

            if (userId <= 0) {
                throw new InvalidAccessTokenException();
            }

            return userId;

        } catch (NumberFormatException exception) {
            throw new InvalidAccessTokenException();
        }
    }
}