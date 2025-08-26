CREATE TABLE sentence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    journal_entry_id UUID NOT NULL REFERENCES journal_entry(id),
    grammar_id UUID NOT NULL REFERENCES grammar(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sentence_by_user ON journal_entry(user_id);
CREATE INDEX idx_sentence_by_journal ON sentence(journal_entry_id);
CREATE INDEX idx_sentence_by_grammar ON tagged_sentence(grammar_id);
