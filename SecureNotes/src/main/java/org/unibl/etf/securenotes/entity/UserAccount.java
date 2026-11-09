package org.unibl.etf.securenotes.entity;
import jakarta.persistence.*;

import java.time.Duration;
import java.time.Instant;

@Entity
@Table(name="users")

public class UserAccount
{
    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    @Column(name="email", nullable=false, unique=true,length = 254)
    private String email;

    @Column(name="password_hash", nullable=false, length = 255)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name="status",nullable = false, length = 30)
    private UserStatus status;

    @Column(name="created_at", nullable = false,updatable = false)
    private Instant createdAt;

    @Column(name="updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "failed_login_attempts", columnDefinition = "INT NOT NULL DEFAULT 0")
    private int failedLoginAttempts = 0;

    @Column(name = "locked_until")
    private Instant lockedUntil;
    protected  UserAccount()
    {}

    public String getPasswordHash() {
        return passwordHash;
    }

    public UserAccount(String email, String passwordHash, UserStatus status) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.status = status;
    }

    public Long getId() {
        return id;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public UserStatus getStatus() {
        return status;
    }

    public String getEmail() {
        return email;
    }

    @PrePersist
    private void beforeInsert()
    {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    private void beforeUpdate()
    {
       this.updatedAt = Instant.now();
    }

    public void activate()
    {
        this.status = UserStatus.ACTIVE;
    }

    public boolean isLoginLocked(Instant now)
    {
        return lockedUntil != null && now.isBefore(lockedUntil);
    }

    public void registerFailedLogin(Instant now, int maxAttempts, Duration lockDuration)
    {
        failedLoginAttempts++;
        if (failedLoginAttempts >= maxAttempts)
        {
            lockedUntil = now.plus(lockDuration);
            failedLoginAttempts = 0;
        }
    }

    public void resetFailedLogins()
    {
        failedLoginAttempts = 0;
        lockedUntil = null;
    }
    public void disable()
    {
        this.status = UserStatus.DISABLED;
    }
}
