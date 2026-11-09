package org.unibl.etf.securenotes.dto.note;
import java.time.Instant;

public record NoteResponse(
        Long id,
        String title,
        String content,
        Instant createdAt,
        Instant updatedAt
) {
}