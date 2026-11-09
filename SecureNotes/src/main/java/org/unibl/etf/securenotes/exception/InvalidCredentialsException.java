package org.unibl.etf.securenotes.exception;
public class InvalidCredentialsException extends RuntimeException {

    public InvalidCredentialsException() {
        super("Email adresa ili lozinka nisu ispravni.");
    }
}