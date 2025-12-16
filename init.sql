CREATE TABLE user_access (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    resource_id TEXT NOT NULL
);

CREATE TABLE resource (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    data TEXT
);

INSERT INTO resource (id, name, data)
SELECT 
    'resource-' || i,
    'Resource #' || i,
    'Data payload for resource ' || i
FROM generate_series(1, 600) AS i;

INSERT INTO user_access (user_id, resource_id)
SELECT 'test-user-1', 'resource-' || generate_series(1, 600);

CREATE PUBLICATION powersync FOR ALL TABLES;

