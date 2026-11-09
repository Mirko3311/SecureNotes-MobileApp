package org.unibl.etf.securenotes.exception;


public class NoteNotFoundException
        extends RuntimeException {

    public NoteNotFoundException() {
        super("Bilješka nije pronađena.");
    }
}