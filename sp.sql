CREATE OR REPLACE PROCEDURE sp_batch_flash_sale (
  IN param_item_id INTEGER, -- should be checked > 0, clients must enforce this
  INOUT user_can_buy INTEGER[],
  INOUT user_cannot_buy INTEGER[],
  INOUT not_eligible_users INTEGER[],
  INOUT cheating_users INTEGER[],
  VARIADIC param_user_ids INTEGER[]) -- asc ordered + unique
AS $$
DECLARE
  free_users INTEGER[];
  eligible_users INTEGER[];
  num_eligible_users INTEGER;

  num_item_on_hold INTEGER = 0;
  num_item_returned INTEGER = 0;
  undo_id INTEGER;
BEGIN
  -- PHASE 1
  -- just record that we want to take some of the stocks
  -- use business-level UNDO log, inspired by SEATA's Autonomous Transaction
  ------------------------------------------------------------------
  BEGIN

  SELECT LEAST(ARRAY_LENGTH(param_user_ids, 1), stock) INTO num_item_on_hold 
  FROM items
  WHERE id = param_item_id FOR UPDATE;

  IF num_item_on_hold <> 0 THEN
    UPDATE items SET stock = stock - num_item_on_hold WHERE id = param_item_id;
    INSERT INTO undo_on_hold (item_id, user_ids) 
      VALUES (param_item_id, param_user_ids) RETURNING ID INTO undo_id;
  END IF;

  END;
  COMMIT;

  -- also need to handle if already 0, just fast return?

  -- PHASE 2
  -- check all user, and grant to those who is eligible (and not more than on_hold)
  ------------------------------------------------------------------
  BEGIN

  -- get and lock every user requested
  -- we `skip locked`, cause probably some user trying to cheat
  -- and not via apps/web only, but via bot (cause they can do more than 1 at once)
  --
  -- it may block our solution, so we skipped it, and returns error for them
  free_users := ARRAY(
    SELECT id FROM users
    WHERE id = ANY(param_user_ids)
    ORDER BY id ASC
    FOR UPDATE SKIP LOCKED);
  
  -- can be removed, and just let clients do it
  -- if not the same, someone is cheating
  IF ARRAY_LENGTH(free_users, 1) <> ARRAY_LENGTH(param_user_ids, 1) THEN
    cheating_users = orderedsetdiff(param_user_ids, free_users);
  END IF;

  -- each user can only buy this item once
  -- we need to check manually to prevent it from crashing the others
  --
  -- we can actually just check the number returned by update
  -- but by then we need to check again who actually gets the item
  -- 
  -- no need to lock this call
  -- cause everything goes here should lock the user first
  not_eligible_users := ARRAY(
    SELECT user_id FROM orders o
    WHERE o.item_id = param_item_id
    AND o.user_id = ANY(free_users)
    ORDER BY user_id ASC
  ); 
    
  -- can also be removed, like cheating_users
  IF ARRAY_LENGTH(not_eligible_users, 1) = 0 THEN
    eligible_users = free_users;
  ELSE
    eligible_users := orderedsetdiff(free_users, not_eligible_users);
  END IF;
  num_eligible_users := ARRAY_LENGTH(eligible_users, 1);

  -- check how many can actually buy the item
  IF num_item_on_hold >= num_eligible_users THEN
    -- all user can take 1
    DELETE FROM undo_on_hold WHERE id = undo_id;
    INSERT INTO orders SELECT param_item_id, unnest(eligible_users);

    -- we implement this after inserting eligible_users
    -- to reduce lock wait times
    num_item_returned := num_item_on_hold - num_eligible_users;
    IF num_item_returned <> 0 THEN
      UPDATE items SET stock = stock + num_item_returned 
      WHERE id = param_item_id;
    END IF;

    user_can_buy := eligible_users;
    user_cannot_buy := ARRAY[]::INT[];
  ELSE
    -- only the first n can buy, the rest fails
    user_can_buy := eligible_users[:num_item_on_hold];
    user_cannot_buy := eligible_users[num_item_on_hold+1:];

    DELETE FROM undo_on_hold WHERE id = undo_id;
    INSERT INTO orders (item_id, user_id) SELECT param_item_id, unnest(user_can_buy);
  END IF;
  END;
  COMMIT;
END $$
LANGUAGE plpgsql;
