SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE
table_schema = 'public'
AND data_type IN
('timestamp without time zone',
'timestamp with time zone',
'date')
ORDER BY table_name, data_type, column_name DESC
