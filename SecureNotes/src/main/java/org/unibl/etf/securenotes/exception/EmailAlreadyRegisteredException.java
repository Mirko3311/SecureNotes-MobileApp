package org.unibl.etf.securenotes.exception;

public class EmailAlreadyRegisteredException  extends  RuntimeException
{
    public EmailAlreadyRegisteredException()
    {
        super("Korisnik sa email adresom vec postoji");
    }
}
