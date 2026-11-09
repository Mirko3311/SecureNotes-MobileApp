package org.unibl.etf.securenotes.exception;

public class TotpSecretEncryptionException extends RuntimeException {

    public TotpSecretEncryptionException(
            String message,
            Throwable cause
    ) {
        super(message, cause);
    }

    public TotpSecretEncryptionException(String message) {
        super(message);
    }
}