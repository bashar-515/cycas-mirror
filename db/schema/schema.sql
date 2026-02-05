CREATE TABLE users (
    id TEXT PRIMARY KEY,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE categories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL
        CHECK(
            length(name) BETWEEN 4 and 24
            AND name ~ '^[a-z]{4,24}$'
        ),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX categories_user_id_idx ON categories(user_id);
CREATE UNIQUE INDEX categories_user_id_name_key ON categories(user_id, name);
