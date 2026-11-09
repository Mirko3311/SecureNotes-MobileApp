create table users
(
    id            bigint auto_increment
        primary key,
    email         varchar(254)                               not null,
    created_at    datetime(6)                                not null,
    password_hash varchar(255)                               not null,
    status        enum ('ACTIVE', 'DISABLED', 'PENDING_MFA') not null,
    updated_at    datetime(6)                                not null,
    constraint UK6dotkott2kjsp8vw4d0m25fb7
        unique (email)
);

create table mfa_transactions
(
    id              bigint auto_increment
        primary key,
    completed_at    datetime(6)                                        null,
    created_at      datetime(6)                                        not null,
    expires_at      datetime(6)                                        not null,
    failed_attempts int                                                not null,
    max_attempts    int                                                not null,
    purpose         enum ('TOTP_AUTHENTICATION', 'TOTP_ENROLLMENT')    not null,
    status          enum ('COMPLETED', 'EXPIRED', 'LOCKED', 'PENDING') not null,
    user_id         bigint                                             not null,
    version         bigint                                             not null,
    constraint FK34a5heibjosjkgju0stmxw6h9
        foreign key (user_id) references users (id)
);

create table notes
(
    id         bigint auto_increment
        primary key,
    content    tinytext     not null,
    created_at datetime(6)  not null,
    title      varchar(200) not null,
    updated_at datetime(6)  not null,
    version    bigint       not null,
    user_id    bigint       not null,
    constraint fk_notes_user
        foreign key (user_id) references users (id)
);

create index idx_notes_user_id
    on notes (user_id);

create index idx_notes_user_updated_at
    on notes (user_id, updated_at);

create table totp_credentials
(
    id               bigint auto_increment
        primary key,
    activated_at     datetime(6)                            null,
    created_at       datetime(6)                            not null,
    encrypted_secret varchar(512)                           not null,
    status           enum ('ACTIVE', 'DISABLED', 'PENDING') not null,
    version          bigint                                 not null,
    user_id          bigint                                 not null,
    constraint uk_totp_credentials_user_id
        unique (user_id),
    constraint FKcky8855xwkr91ur76fpavibng
        foreign key (user_id) references users (id)
);

