CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    display_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE TABLE subs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(255) NOT NULL,
    provider_sub VARCHAR(255) NOT NULL,
    CONSTRAINT unique_provider_identity UNIQUE (provider, provider_sub)
);

CREATE INDEX idx_subs_provider_sub ON subs(provider, provider_sub);

INSERT INTO users (id, email) VALUES
    ('431a6bca-0e1b-4820-96cc-8f63b32fdcaf', 'tester@example.com');

INSERT INTO subs (id, user_id, provider, provider_sub) VALUES
    ('f39a42e7-76e2-45ab-9d32-bdc149270506', '431a6bca-0e1b-4820-96cc-8f63b32fdcaf', 'hardcoded', 'abcd-efgh-1234-5678');
