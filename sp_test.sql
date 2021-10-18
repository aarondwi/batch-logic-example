-- TEST 1
DELETE FROM orders;
UPDATE items SET stock=2 WHERE id=1;
CALL sp_batch_flash_sale (
  1, 
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  VARIADIC ARRAY[2,3]);
-- should only be 2 people getting the item

-- TEST 2
UPDATE items SET stock=2 WHERE id=1;
CALL sp_batch_flash_sale (
  1, 
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  VARIADIC ARRAY[2,3,4,5,6,7]);
-- should only be 2 people getting the item, and not 2 or 3

-- TEST 3
-- conn 1
BEGIN;
SELECT * FROM users WHERE id=99 FOR UPDATE;
-- conn 2
UPDATE items SET stock=2 WHERE id=1;
CALL sp_batch_flash_sale (
  1, 
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  VARIADIC ARRAY[11,12,13,99,100,101]);
-- conn 1
ROLLBACK;

-- TEST 4
-- assume id 11 already ordered
UPDATE items SET stock=2 WHERE id=1;
CALL sp_batch_flash_sale (
  1, 
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  ARRAY[]::INT[],
  VARIADIC ARRAY[11,105,106,107]);
