package org.unibl.etf.securenotes.exception;

public class MfaTransactionExpiredException extends RuntimeException
{
    public MfaTransactionExpiredException()
    {
        super("MFA transakcija je istekla. Molimo vas da se ponovo prijavite.");
    }
}
