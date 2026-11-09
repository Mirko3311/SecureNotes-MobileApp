package org.unibl.etf.securenotes.dto.note;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NoteCreateRequest(

        @NotBlank(
                message = "Naslov bilješke je obavezan."
        )
        @Size(
                max = 200,
                message = "Naslov može sadržati najviše 200 znakova."
        )
        String title,

        @NotBlank(
                message = "Sadržaj bilješke je obavezan."
        )
        @Size(
                max = 20000,
                message = "Sadržaj može sadržati najviše 20000 znakova."
        )
        String content

) {
}