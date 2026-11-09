package org.unibl.etf.securenotes.repository;


import org.springframework.data.jpa.repository.JpaRepository;
import org.unibl.etf.securenotes.entity.TotpCredential;
import org.unibl.etf.securenotes.entity.TotpCredentialStatus;

import java.util.Optional;

public interface TotpCredentialRepository
        extends JpaRepository<TotpCredential, Long> {

    Optional<TotpCredential> findByUserAccountId(Long userId);

    Optional<TotpCredential> findByUserAccountIdAndStatus(
            Long userId,
            TotpCredentialStatus status
    );

    boolean existsByUserAccountIdAndStatus(
            Long userId,
            TotpCredentialStatus status
    );
}