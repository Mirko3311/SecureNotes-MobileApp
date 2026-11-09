package org.unibl.etf.securenotes.exception;

public class LoginTemporarilyLockedException extends RuntimeException {

    public LoginTemporarilyLockedException() {
        super("Previše neuspješnih pokušaja prijave. Pokušajte ponovo za 15 minuta.");
    }
}