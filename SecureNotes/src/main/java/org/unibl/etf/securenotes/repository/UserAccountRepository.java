package org.unibl.etf.securenotes.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.unibl.etf.securenotes.entity.UserAccount;

import java.util.Optional;

@Repository
public interface UserAccountRepository extends JpaRepository<UserAccount, Long>
{

    Optional<UserAccount> findByEmail(String email);
    boolean existsByEmail(String email);
}
