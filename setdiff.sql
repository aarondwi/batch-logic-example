CREATE OR REPLACE FUNCTION orderedsetdiff(
  IN source INTEGER[],
  IN del INTEGER[]
) RETURNS INTEGER[]
AS $$
DECLARE
  -- array index in postgres is 1-based
  current_source_pos INTEGER = 1;
  current_del_pos INTEGER = 1;
  source_len INTEGER = ARRAY_LENGTH(source, 1);
  del_len INTEGER = ARRAY_LENGTH(del, 1);
  results INTEGER[] = ARRAY[]::INTEGER[];
BEGIN
  WHILE current_source_pos <= source_len AND current_del_pos <= del_len LOOP
    IF source[current_source_pos] = del[current_del_pos] THEN
      current_source_pos = current_source_pos + 1;
    ELSIF source[current_source_pos] < del[current_del_pos] THEN
      results = ARRAY_APPEND(results, source[current_source_pos]);
      current_source_pos = current_source_pos + 1;
    ELSE
      current_del_pos = current_del_pos + 1;
    END IF;
  END LOOP;

  IF current_source_pos <= source_len THEN
    results = ARRAY_CAT(results, source[current_source_pos:]);
  END IF;

  RETURN results;
END $$
LANGUAGE plpgsql
IMMUTABLE;
