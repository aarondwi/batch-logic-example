CREATE TABLE items (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  stock INTEGER NOT NULL CHECK (stock >= 0)
);

CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL
);

CREATE TABLE orders (
  item_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (item_id, user_id),
  FOREIGN KEY (item_id) references items(id),
  FOREIGN KEY (user_id) references users(id)
);

CREATE TABLE undo_on_hold (
  id BIGSERIAL PRIMARY KEY,
  item_id BIGINT NOT NULL,
  user_ids INTEGER[],
  FOREIGN KEY (item_id) references items(id)
);
