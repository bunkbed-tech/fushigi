CREATE TABLE grammar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    language_id INT NOT NULL REFERENCES languages(id),
    usage TEXT NOT NULL,
    meaning TEXT NOT NULL,
    context TEXT,
    tags TEXT[],
    notes TEXT,
    nuance TEXT,
    examples JSONB NOT NULL,
    created_by UUID NULL REFERENCES users(id), -- NULL for official points
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
