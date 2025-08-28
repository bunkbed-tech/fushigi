CREATE TABLE sentence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    journal_entry_id UUID NOT NULL REFERENCES journal_entry(id) ON DELETE CASCADE,
    grammar_id UUID NOT NULL REFERENCES grammar(id),
    content TEXT NOT NULL
);

CREATE INDEX idx_sentence_by_user ON sentence(user_id);
CREATE INDEX idx_sentence_by_journal ON sentence(journal_entry_id);
CREATE INDEX idx_sentence_by_grammar ON sentence(grammar_id);
