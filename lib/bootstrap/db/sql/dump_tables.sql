-- Ensure a clean settings table
DROP TABLE IF EXISTS bootstrap_db;
-- Ensure a clean icebox on every data dump
DROP TABLE IF EXISTS bootstrap_icebox;

-- Create tables

-- Capture general settings
CREATE TABLE bootstrap_db (
    id integer NOT NULL,
    file_path character varying(255) NOT NULL,
    generated_at timestamp without time zone NOT NULL
);

-- Maintain list of frozen attributes
CREATE TABLE bootstrap_icebox (
    id integer NOT NULL,
    table_name character varying(200) NOT NULL,
    column_name character varying(200) NOT NULL,
    frozen_id integer NOT NULL
);

-- Primary keys

-- Handle primary key auto sequence
CREATE SEQUENCE bootstrap_db_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE bootstrap_db_id_seq OWNED BY bootstrap_db.id;
ALTER TABLE ONLY bootstrap_db ALTER COLUMN id SET DEFAULT nextval('bootstrap_db_id_seq'::regclass);

-- Handle primary key auto sequence
CREATE SEQUENCE bootstrap_icebox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bootstrap_icebox_id_seq OWNED BY bootstrap_icebox.id;
ALTER TABLE ONLY bootstrap_icebox ALTER COLUMN id SET DEFAULT nextval('bootstrap_icebox_id_seq'::regclass);

-- Indices

-- Primary lookup index for all fields (only query)
CREATE INDEX index_bootstrap_db_on_generated_at ON bootstrap_db USING btree (generated_at);
CREATE INDEX index_bootstrap_icebox_on_frozen ON bootstrap_icebox USING btree (table_name, column_name, frozen_id);
