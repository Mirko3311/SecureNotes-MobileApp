package org.unibl.etf.securenotes.exception;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.UNAUTHORIZED)
public class InvalidPreMfaTokenException
        extends RuntimeException {

    public InvalidPreMfaTokenException() {
        super(
                "Pre-MFA token ne sadrži potrebne podatke."
        );
    }
}