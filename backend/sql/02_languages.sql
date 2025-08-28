CREATE TABLE languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL
);

INSERT INTO languages (name) VALUES
    ('Japanese'),
    ('German'),
    ('Portuguese');
