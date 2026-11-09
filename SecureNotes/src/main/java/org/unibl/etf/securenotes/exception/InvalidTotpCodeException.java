package org.unibl.etf.securenotes.exception;


public class InvalidTotpCodeException
        extends RuntimeException {

    private final int remainingAttempts;

    public InvalidTotpCodeException(
            int remainingAttempts
    ) {
        super(createMessage(remainingAttempts));
        this.remainingAttempts =
                remainingAttempts;
    }

    public int getRemainingAttempts() {
        return remainingAttempts;
    }

    private static String createMessage(
            int remainingAttempts
    ) {
        if (remainingAttempts <= 0) {
            return "TOTP kod nije ispravan. "
                    + "MFA transakcija je zaključana.";
        }

        return "TOTP kod nije ispravan. "
                + "Preostali broj pokušaja: "
                + remainingAttempts + ".";
    }
}