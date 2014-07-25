-- Rebase all date/timestamp values in db to a relative point in future/past
-- Returns the number of rows affected
CREATE OR REPLACE FUNCTION rebase_db_time(
    fixed_point timestamp with time zone,
    new_point timestamp with time zone
  )
  RETURNS integer AS
$$
DECLARE
  column_data record;
  update_command varchar := '';
  update_result integer := 0;
  result integer := 0;
  epoch_diff double precision;
  operator varchar := '+';
BEGIN
  IF (new_point = fixed_point) THEN
    epoch_diff := NULL;
  ELSIF (new_point < fixed_point) THEN
    epoch_diff := (SELECT EXTRACT(EPOCH FROM (fixed_point - new_point)));
    operator := '-';
  ELSE
    epoch_diff := (SELECT EXTRACT(EPOCH FROM (new_point - fixed_point)));
    operator := '+';
  END IF;

  IF ((epoch_diff > 0) AND (new_point <> fixed_point)) THEN
    FOR column_data IN (
      SELECT table_name, column_name, data_type
      FROM information_schema.columns
      WHERE
      table_schema = 'public'
      AND data_type IN
      ('timestamp without time zone',
      'timestamp with time zone',
      'date')
      ORDER BY table_name DESC ) LOOP

      IF column_data.data_type = 'date' THEN
        update_command := format('UPDATE %s SET %I = (((%I::date + %L::time)::timestamp with time zone %s %L::time)::timestamp %s interval ''%s seconds'')::date;',
            column_data.table_name,     --UPDATE table_name
            column_data.column_name,    --SET column_name =
            column_data.column_name,    --column_name (current value)
            fixed_point,                -- append time original date was generated
            operator,                   -- append/deduct (only) time difference to rebased time
            new_point,                  -- append/deduct (only) time difference to rebased time
            operator,                   -- append/deduct the total difference to the new rebased time
            epoch_diff
        );
      ELSE
        update_command := format('UPDATE %s SET %I = (%I %s interval ''%s seconds'');',
            column_data.table_name,     -- UPDATE table_name
            column_data.column_name,    -- SET column_name =
            column_data.column_name,    -- column_name (current value)
            operator,                   -- append/deduct
            epoch_diff                  -- epoch difference
        );
      END IF;
      EXECUTE update_command;
      --RAISE EXCEPTION '%', update_command;

      GET DIAGNOSTICS update_result := ROW_COUNT;
      result := result + update_result;
    END LOOP;
    --RAISE EXCEPTION '%', result;
    RETURN result;
  ELSE
    -- Points are the same or no epoch diff and should skip updating
    RETURN NULL;
  END IF;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;
