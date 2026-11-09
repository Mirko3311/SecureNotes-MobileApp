package org.unibl.etf.securenotes.exception;


public class InvalidMfaTransactionException  extends RuntimeException
{
    public InvalidMfaTransactionException()
    {
        super("Transakcija nije važeća ili više nije aktivna.");
    }
}
