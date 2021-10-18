-- clean all tables
DELETE FROM orders;
DELETE FROM items;
DELETE FROM users;

-- insert for master data table
INSERT INTO items (name, stock)
SELECT md5(random()::text), 1000000;

INSERT INTO users (name)
SELECT md5(random()::text)
FROM generate_series(1, 2500000);
