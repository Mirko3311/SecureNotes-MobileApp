package org.unibl.etf.securenotes.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

        @NotBlank(message = "Email adresa je obavezna.")
        @Email(message = "Email adresa nije ispravna.")
        @Size(
                max = 254,
                message = "Email adresa može imati najviše 254 znaka."
        )
        String email,

        @NotBlank(message = "Lozinka je obavezna.")
        @Size(
                min = 8,
                max = 128,
                message = "Lozinka mora imati između 8 i 128 znakova."
        )
        String password

) {
}