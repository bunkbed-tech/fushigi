CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    open_ai_hash VARCHAR(255),
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

INSERT INTO users (id, username, password_hash) VALUES
    ('431a6bca-0e1b-4820-96cc-8f63b32fdcaf', 'tester', 'test123');
