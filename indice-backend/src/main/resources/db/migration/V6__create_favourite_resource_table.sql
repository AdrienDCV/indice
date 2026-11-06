CREATE TABLE IF NOT EXISTS favourite_resource (
    resource_id UUID PRIMARY KEY REFERENCES resource (id) ON DELETE CASCADE
);
