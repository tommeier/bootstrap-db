-- Original generation time : 2013-07-24 12:26:50.598673
-- 2013-07-24 12:27:08.592838
-- 2013-07-24 12:27:14.327218
-- Setup functions

-- Rebase time values to a fixed point
CREATE OR REPLACE FUNCTION rebase_time(
    fixed_point timestamp without time zone,
    original_time timestamp without time zone)
  RETURNS timestamp without time zone AS
$$
DECLARE
  result timestamp without time zone := localtimestamp;
BEGIN
  IF (original_time = fixed_point) THEN
    result := localtimestamp;
  ELSIF (original_time < fixed_point) THEN
    -- Original time was set in the past
    result :=  (localtimestamp - (fixed_point - original_time));
  ELSIF (original_time > fixed_point) THEN
    -- Original time was set in the future
    result :=  (localtimestamp + (original_time - fixed_point));
  END IF;
  --RAISE NOTICE 'Original: %, New: %', original_time, result;
  RETURN result;
END;
$$
LANGUAGE 'plpgsql' STABLE;

--Rebase date values to a fixed point
CREATE OR REPLACE FUNCTION rebase_date(fixed_point date, original date)
  RETURNS date AS
$$
DECLARE
  result date := current_date;
BEGIN
IF (original = fixed_point) THEN
  result := current_date;
ELSIF (original < fixed_point) THEN
  -- Original was set in the past
  result :=  (current_date - (fixed_point - original));
ELSE
  -- Original was set in the future
  result :=  (current_date + (original - fixed_point));
END IF;
RETURN result;
END;
$$
LANGUAGE 'plpgsql' STABLE;

--Rebase all date/timestamp values in db to a fixed point
--Returns the number of rows affected
CREATE OR REPLACE FUNCTION rebase_db_time(fixed_point timestamp without time zone)
  RETURNS integer AS
$$
DECLARE
  column_data record;
  update_command varchar := '';
  function_name varchar := '';
  fixed_point_type varchar := '';
  update_result integer := 0;
  result integer := 0;
BEGIN
  FOR column_data IN (
    SELECT table_name, column_name, data_type
    FROM information_schema.columns
    WHERE
    table_schema = 'public'
    AND data_type IN
    ('timestamp without time zone',
    'timestamp with time zone', 'date')
    ORDER BY table_name DESC ) LOOP
  --'date'
    IF column_data.data_type = 'date' THEN
      function_name := 'rebase_date';
    ELSE
      function_name := 'rebase_time';
    END IF;

    update_command := format('UPDATE %s SET %I = %s(%L::%s, %s.%s);',
        column_data.table_name,
        column_data.column_name,
        function_name,
        fixed_point,
        column_data.data_type,
        column_data.table_name,
        column_data.column_name);

    --RAISE EXCEPTION '%', update_command;
    EXECUTE update_command;

    GET DIAGNOSTICS update_result := ROW_COUNT;
    result := result + update_result;
  END LOOP;
  --RAISE EXCEPTION '%', result;
  RETURN result;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

SELECT rebase_db_time('2013-07-24 12:26:50.598673'::timestamp without time zone);
--SELECT rebase_db_time('2013-07-14'::date);
