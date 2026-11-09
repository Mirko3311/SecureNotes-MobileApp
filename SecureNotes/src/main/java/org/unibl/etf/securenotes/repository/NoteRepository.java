package org.unibl.etf.securenotes.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.unibl.etf.securenotes.entity.Note;

import java.util.List;
import java.util.Optional;

public interface NoteRepository
        extends JpaRepository<Note, Long> {

    List<Note>
    findAllByUserAccountIdOrderByUpdatedAtDesc(
            Long userId
    );

    Optional<Note>
    findByIdAndUserAccountId(
            Long noteId,
            Long userId
    );
}