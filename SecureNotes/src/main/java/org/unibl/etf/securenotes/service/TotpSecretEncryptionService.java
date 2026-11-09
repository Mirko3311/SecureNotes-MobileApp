package org.unibl.etf.securenotes.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.unibl.etf.securenotes.exception.TotpSecretEncryptionException;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;

@Service
public class TotpSecretEncryptionService {

    private static final String TRANSFORMATION =
            "AES/GCM/NoPadding";

    private static final int KEY_LENGTH_BYTES = 32;
    private static final int IV_LENGTH_BYTES = 12;
    private static final int TAG_LENGTH_BITS = 128;

    private static final byte FORMAT_VERSION = 1;

    private final SecretKey secretKey;
    private final SecureRandom secureRandom;

    public TotpSecretEncryptionService(
            @Value("${security.totp.encryption-key}")
            String encodedKey
    ) {
        byte[] keyBytes;

        try {
            keyBytes = Base64.getDecoder().decode(encodedKey);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(
                    "Ključ za šifrovanje TOTP tajne nije ispravno zapisan u Base64 formatu.",
                    exception
            );
        }

        if (keyBytes.length != KEY_LENGTH_BYTES) {
            throw new IllegalStateException(
                    "Ključ za šifrovanje TOTP tajne mora imati tačno 32 bajta."
            );
        }

        this.secretKey = new SecretKeySpec(keyBytes, "AES");
        this.secureRandom = new SecureRandom();
    }

    public String encrypt(String plainSecret) {

        if (plainSecret == null || plainSecret.isBlank()) {
            throw new IllegalArgumentException(
                    "TOTP tajna za šifrovanje ne smije biti prazna."
            );
        }

        try {
            byte[] iv = new byte[IV_LENGTH_BYTES];
            secureRandom.nextBytes(iv);

            Cipher cipher = Cipher.getInstance(TRANSFORMATION);

            GCMParameterSpec parameterSpec =
                    new GCMParameterSpec(
                            TAG_LENGTH_BITS,
                            iv
                    );

            cipher.init(
                    Cipher.ENCRYPT_MODE,
                    secretKey,
                    parameterSpec
            );

            byte[] plainBytes =
                    plainSecret.getBytes(StandardCharsets.UTF_8);

            byte[] encryptedBytes =
                    cipher.doFinal(plainBytes);

            ByteBuffer output = ByteBuffer.allocate(
                    1 + iv.length + encryptedBytes.length
            );

            output.put(FORMAT_VERSION);
            output.put(iv);
            output.put(encryptedBytes);

            return Base64.getEncoder()
                    .encodeToString(output.array());

        } catch (GeneralSecurityException exception) {
            throw new TotpSecretEncryptionException(
                    "Šifrovanje TOTP tajne nije uspjelo.",
                    exception
            );
        }
    }

    public String decrypt(String storedValue) {

        if (storedValue == null || storedValue.isBlank()) {
            throw new IllegalArgumentException(
                    "Šifrovana TOTP tajna ne smije biti prazna."
            );
        }

        try {
            byte[] storedBytes =
                    Base64.getDecoder().decode(storedValue);

            int minimumLength =
                    1 + IV_LENGTH_BYTES + 16;

            if (storedBytes.length < minimumLength) {
                throw new TotpSecretEncryptionException(
                        "Šifrovana TOTP tajna ima neispravan format."
                );
            }

            ByteBuffer input =
                    ByteBuffer.wrap(storedBytes);

            byte formatVersion = input.get();

            if (formatVersion != FORMAT_VERSION) {
                throw new TotpSecretEncryptionException(
                        "Verzija formata šifrovane TOTP tajne nije podržana."
                );
            }

            byte[] iv = new byte[IV_LENGTH_BYTES];
            input.get(iv);

            byte[] encryptedBytes =
                    new byte[input.remaining()];

            input.get(encryptedBytes);

            Cipher cipher = Cipher.getInstance(TRANSFORMATION);

            GCMParameterSpec parameterSpec =
                    new GCMParameterSpec(
                            TAG_LENGTH_BITS,
                            iv
                    );

            cipher.init(
                    Cipher.DECRYPT_MODE,
                    secretKey,
                    parameterSpec
            );

            byte[] plainBytes =
                    cipher.doFinal(encryptedBytes);

            return new String(
                    plainBytes,
                    StandardCharsets.UTF_8
            );

        } catch (IllegalArgumentException |
                 GeneralSecurityException exception) {

            throw new TotpSecretEncryptionException(
                    "Dešifrovanje TOTP tajne nije uspjelo.",
                    exception
            );
        }
    }
}