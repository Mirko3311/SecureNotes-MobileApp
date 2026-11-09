package org.unibl.etf.securenotes.exception;

public class InvalidAccessTokenException
        extends RuntimeException {

    public InvalidAccessTokenException() {
        super("Access token ne sadrži ispravan identitet korisnika.");
    }
}