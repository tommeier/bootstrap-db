-- Setup functions for being able to rebase time + date values
-- from a point the db data was generated to a new point.

-- Rebase time values to a fixed point
CREATE OR REPLACE FUNCTION rebase_time(
    fixed_point timestamp,
    new_point timestamp,
    original_time timestamp)
  RETURNS timestamp AS
$$
DECLARE
  result timestamp := new_point;
BEGIN
  IF (original_time = fixed_point) THEN
    result := new_point;
  ELSIF (original_time < fixed_point) THEN
    -- Original time was set in the past
    result :=  (new_point - (fixed_point - original_time));
  ELSIF (original_time > fixed_point) THEN
    -- Original time was set in the future
    result :=  (new_point + (original_time - fixed_point));
  END IF;
  --RAISE NOTICE 'Original: %, New: %', original_time, result;
  RETURN result;
END;
$$
LANGUAGE 'plpgsql' STABLE;

--Rebase date values to a fixed point
CREATE OR REPLACE FUNCTION rebase_date(
    fixed_point date,
    new_point date,
    original date)
  RETURNS date AS
$$
DECLARE
  result date := new_point;
BEGIN
IF (original = fixed_point) THEN
  result := new_point;
ELSIF (original < fixed_point) THEN
  -- Original was set in the past
  result :=  (new_point - (fixed_point - original));
ELSE
  -- Original was set in the future
  result :=  (new_point + (original - fixed_point));
END IF;
RETURN result;
END;
$$
LANGUAGE 'plpgsql' STABLE;

--Rebase all date/timestamp values in db to a fixed point
--Returns the number of rows affected
CREATE OR REPLACE FUNCTION rebase_db_time(
    fixed_point timestamp,
    new_point timestamp
  )
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
    (
    'timestamp without time zone',
    'timestamp with time zone',
    'date'
    )
    ORDER BY table_name DESC ) LOOP
    IF column_data.data_type = 'date' THEN
      function_name := 'rebase_date';
    ELSE
      function_name := 'rebase_time';
    END IF;

    update_command := format('UPDATE %s SET %I = %s(%L::%s, %L::%s, %s.%s::%s);',
        column_data.table_name,
        column_data.column_name,
        function_name,
        fixed_point,
        column_data.data_type,
        new_point,
        column_data.data_type,
        column_data.table_name,
        column_data.column_name,
        column_data.data_type);

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
