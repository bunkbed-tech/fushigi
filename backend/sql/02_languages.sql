CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO languages (name) VALUES
    ('Japanese'),
    ('German'),
    ('Portuguese');
