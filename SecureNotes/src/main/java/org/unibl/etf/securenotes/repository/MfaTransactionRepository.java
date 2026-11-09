package org.unibl.etf.securenotes.repository;



import org.springframework.data.jpa.repository.JpaRepository;
import org.unibl.etf.securenotes.entity.MfaTransaction;

public interface MfaTransactionRepository extends JpaRepository<MfaTransaction, Long> {
}