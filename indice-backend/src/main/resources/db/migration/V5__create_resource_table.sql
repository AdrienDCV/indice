CREATE TABLE IF NOT EXISTS resource (
    id               UUID          PRIMARY KEY,
    title            VARCHAR(255)  NOT NULL,
    description      VARCHAR(500)  NOT NULL,
    content          TEXT          NOT NULL,
    type             VARCHAR(20)   NOT NULL,
    duration_minutes INTEGER       NOT NULL CHECK (duration_minutes > 0),
    level            VARCHAR(20)   NOT NULL,
    media_url        VARCHAR(2048)
);
