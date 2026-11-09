package org.unibl.etf.securenotes.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record TotpCodeRequest(
        @NotBlank(message = "TOTP kod je obavezan.")
        @Pattern(regexp="[0-9]{6}",message="TOTP kod mora sadrzati tacno sest cifara")
        String code) {
}
