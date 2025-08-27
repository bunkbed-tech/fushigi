CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL DEFAULT 'apple',
    provider_user_id VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT unique_provider_identity UNIQUE (provider, provider_user_id)
);

INSERT INTO users (id, provider, provider_user_id, email) VALUES
    ('431a6bca-0e1b-4820-96cc-8f63b32fdcaf', 'hardcoded', 'tester123', 'tester@example.com');
