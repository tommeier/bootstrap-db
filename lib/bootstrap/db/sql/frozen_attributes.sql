-- Ensure a clean icebox on every data dump
DROP TABLE IF EXISTS bootstrap_icebox;

-- Maintain list of frozen attributes
CREATE TABLE bootstrap_icebox (
    id integer NOT NULL,
    table_name character varying(200) NOT NULL,
    column_name character varying(200) NOT NULL,
    frozen_id integer NOT NULL
);

-- Handle primary key auto sequence
CREATE SEQUENCE bootstrap_icebox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE bootstrap_icebox_id_seq OWNED BY bootstrap_icebox.id;
ALTER TABLE ONLY bootstrap_icebox ALTER COLUMN id SET DEFAULT nextval('bootstrap_icebox_id_seq'::regclass);

-- Primary lookup index for all fields
CREATE INDEX index_bootstrap_icebox_on_frozen ON bootstrap_icebox USING btree (table_name, column_name, frozen_id);
