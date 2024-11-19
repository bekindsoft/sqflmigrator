CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
