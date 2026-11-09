package org.unibl.etf.securenotes.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.aspectj.bridge.IMessage;

public record LoginRequest(
        @NotBlank(message="Email adresa je obavezna")
    @Email(message="Email adresa nije ispravna")
    @Size(max=254,message = "Email adresa moze da ima najvise 254 znaka")
    String email,

    @NotBlank(message = "Lozinka je obavezna")
    @Size(max=128, message = "Lozinka moze imati najvise 128 znakova")
    String password)
{}