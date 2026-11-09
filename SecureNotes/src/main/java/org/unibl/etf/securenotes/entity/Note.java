package org.unibl.etf.securenotes.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(
        name = "notes",
        indexes = {
                @Index(
                        name = "idx_notes_user_id",
                        columnList = "user_id"
                ),
                @Index(
                        name = "idx_notes_user_updated_at",
                        columnList = "user_id, updated_at"
                )
        }
)
public class Note {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(
            fetch = FetchType.LAZY,
            optional = false
    )
    @JoinColumn(
            name = "user_id",
            nullable = false,
            foreignKey = @ForeignKey(
                    name = "fk_notes_user"
            )
    )
    private UserAccount userAccount;

    @Column(
            name = "title",
            nullable = false,
            length = 200
    )
    private String title;

    @Lob
    @Column(
            name = "content",
            nullable = false
    )
    private String content;

    @Column(
            name = "created_at",
            nullable = false,
            updatable = false
    )
    private Instant createdAt;

    @Column(
            name = "updated_at",
            nullable = false
    )
    private Instant updatedAt;

    @Version
    private Long version;

    protected Note() {
    }

    public Note(
            UserAccount userAccount,
            String title,
            String content
    ) {
        this.userAccount = userAccount;
        this.title = title;
        this.content = content;
    }

    @PrePersist
    private void beforeInsert() {
        Instant now = Instant.now();

        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    private void beforeUpdate() {
        this.updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public UserAccount getUserAccount() {
        return userAccount;
    }

    public String getTitle() {
        return title;
    }

    public String getContent() {
        return content;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Long getVersion() {
        return version;
    }

    public void update(
            String title,
            String content
    ) {
        this.title = title;
        this.content = content;
    }
}