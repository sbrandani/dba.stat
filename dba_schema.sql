--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

-- Started on 2017-11-29 12:05:32 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 27 (class 2615 OID 192698747)
-- Name: dba; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dba;


ALTER SCHEMA dba OWNER TO postgres;

SET search_path = dba, pg_catalog;

SET default_tablespace = '';

--
-- TOC entry 2020 (class 1259 OID 207538173)
-- Name: stat_database_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE stat_database_hist (
    now timestamp with time zone,
    datid oid,
    datname name,
    numbackends integer,
    xact_commit bigint,
    xact_rollback bigint,
    blks_read bigint,
    blks_hit bigint,
    tup_returned bigint,
    tup_fetched bigint,
    tup_inserted bigint,
    tup_updated bigint,
    tup_deleted bigint,
    conflicts bigint,
    temp_files bigint,
    temp_bytes bigint,
    deadlocks bigint,
    blk_read_time double precision,
    blk_write_time double precision,
    stats_reset timestamp with time zone
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_database_hist OWNER TO statusr;

--
-- TOC entry 2058 (class 1259 OID 210950006)
-- Name: cache_blks_read_hit_delta_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW cache_blks_read_hit_delta_hh AS
 SELECT stat_database_hist.now,
    sum(stat_database_hist.blks_read) AS blks_read,
    sum(stat_database_hist.blks_hit) AS blks_hit,
    (lag(sum(stat_database_hist.blks_read)) OVER (ORDER BY stat_database_hist.now DESC) - lead(sum(stat_database_hist.blks_read)) OVER (ORDER BY stat_database_hist.now DESC)) AS blks_read_delta,
    (lag(sum(stat_database_hist.blks_hit)) OVER (ORDER BY stat_database_hist.now DESC) - lead(sum(stat_database_hist.blks_hit)) OVER (ORDER BY stat_database_hist.now DESC)) AS blks_hit_delta
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = 'webtng'::name)
  GROUP BY stat_database_hist.now
  ORDER BY stat_database_hist.now;


ALTER TABLE cache_blks_read_hit_delta_hh OWNER TO statusr;

--
-- TOC entry 2059 (class 1259 OID 210951727)
-- Name: cache_hit_ratio_delta_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW cache_hit_ratio_delta_by_hh AS
 SELECT stat_database_hist.now,
    (sum(stat_database_hist.blks_hit) / (sum(stat_database_hist.blks_read) + sum(stat_database_hist.blks_hit))) AS cache_hit_ratio,
    sum(stat_database_hist.blks_hit) AS blks_hit,
    sum(stat_database_hist.blks_read) AS blks_read,
    (lag(sum(stat_database_hist.blks_hit)) OVER (ORDER BY stat_database_hist.now DESC) - lead(sum(stat_database_hist.blks_hit)) OVER (ORDER BY stat_database_hist.now DESC)) AS blks_hit_delta,
    (lag(sum(stat_database_hist.blks_read)) OVER (ORDER BY stat_database_hist.now DESC) - lead(sum(stat_database_hist.blks_read)) OVER (ORDER BY stat_database_hist.now DESC)) AS blks_read_delta
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = 'webtng'::name)
  GROUP BY stat_database_hist.now
  ORDER BY stat_database_hist.now;


ALTER TABLE cache_hit_ratio_delta_by_hh OWNER TO statusr;

--
-- TOC entry 2056 (class 1259 OID 210948742)
-- Name: cache_hit_ratio_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW cache_hit_ratio_hh AS
 SELECT stat_database_hist.now,
    ((stat_database_hist.blks_hit)::double precision / ((stat_database_hist.blks_read + stat_database_hist.blks_hit))::double precision) AS cache_hit_ratio
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = 'webtng'::name)
  ORDER BY stat_database_hist.now;


ALTER TABLE cache_hit_ratio_hh OWNER TO statusr;

--
-- TOC entry 2004 (class 1259 OID 206864481)
-- Name: database_size; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW database_size AS
 SELECT d.datname AS name,
    pg_get_userbyid(d.datdba) AS owner,
        CASE
            WHEN has_database_privilege((d.datname)::text, 'CONNECT'::text) THEN pg_size_pretty(pg_database_size(d.datname))
            ELSE 'No Access'::text
        END AS size
   FROM pg_database d
  ORDER BY
        CASE
            WHEN has_database_privilege((d.datname)::text, 'CONNECT'::text) THEN pg_database_size(d.datname)
            ELSE NULL::bigint
        END DESC
 LIMIT 20;


ALTER TABLE database_size OWNER TO statusr;

--
-- TOC entry 2017 (class 1259 OID 207538164)
-- Name: db_size_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE db_size_hist (
    now timestamp with time zone,
    pg_size_pretty text
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE db_size_hist OWNER TO statusr;

--
-- TOC entry 1978 (class 1259 OID 200554498)
-- Name: db_size; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW db_size AS
 SELECT db_size_hist.now,
    db_size_hist.pg_size_pretty
   FROM db_size_hist
  ORDER BY db_size_hist.now;


ALTER TABLE db_size OWNER TO statusr;

--
-- TOC entry 2065 (class 1259 OID 211200636)
-- Name: db_size_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW db_size_by_hh AS
 SELECT db_size_hist.now,
    (substr(db_size_hist.pg_size_pretty, 1, 3))::integer AS substr
   FROM db_size_hist
  ORDER BY db_size_hist.now;


ALTER TABLE db_size_by_hh OWNER TO statusr;

--
-- TOC entry 2356 (class 1259 OID 259271615)
-- Name: db_size_hist2; Type: FOREIGN TABLE; Schema: dba; Owner: postgres
--

CREATE FOREIGN TABLE db_size_hist2 (
    now timestamp with time zone,
    pg_size_pretty text
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE db_size_hist2 OWNER TO postgres;

--
-- TOC entry 2061 (class 1259 OID 210963551)
-- Name: db_statistiche_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW db_statistiche_hh AS
 SELECT stat_database_hist.now,
    stat_database_hist.numbackends AS conn,
    stat_database_hist.xact_commit AS tx_comm,
    stat_database_hist.xact_rollback AS tx_rlbck,
    (stat_database_hist.blks_read + stat_database_hist.blks_hit) AS read_total,
    ((stat_database_hist.blks_hit * 100) / (stat_database_hist.blks_read + stat_database_hist.blks_hit)) AS blks_hit_ratio,
    stat_database_hist.tup_fetched,
    stat_database_hist.tup_inserted,
    stat_database_hist.tup_updated,
    stat_database_hist.tup_deleted
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = 'webtng'::name);


ALTER TABLE db_statistiche_hh OWNER TO statusr;

--
-- TOC entry 2023 (class 1259 OID 207538182)
-- Name: statio_all_tables_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE statio_all_tables_hist (
    now timestamp with time zone,
    relid oid,
    schemaname name,
    relname name,
    heap_blks_read bigint,
    heap_blks_hit bigint,
    idx_blks_read bigint,
    idx_blks_hit bigint,
    toast_blks_read bigint,
    toast_blks_hit bigint,
    tidx_blks_read bigint,
    tidx_blks_hit bigint
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE statio_all_tables_hist OWNER TO statusr;

--
-- TOC entry 1999 (class 1259 OID 206017713)
-- Name: heap_blks_hit_by_table; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW heap_blks_hit_by_table AS
 SELECT statio_all_tables_hist.schemaname,
    statio_all_tables_hist.relname,
    (sum(statio_all_tables_hist.heap_blks_hit) / (sum(statio_all_tables_hist.heap_blks_read) + sum(statio_all_tables_hist.heap_blks_hit))) AS heap_blks_hit_ratio,
    sum(statio_all_tables_hist.heap_blks_read) AS heap_blks_read,
    sum(statio_all_tables_hist.heap_blks_hit) AS heap_blks_hit
   FROM statio_all_tables_hist
  WHERE ((statio_all_tables_hist.heap_blks_read > 0) OR (statio_all_tables_hist.heap_blks_hit > 0))
  GROUP BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname
  ORDER BY (sum(statio_all_tables_hist.heap_blks_hit) / (sum(statio_all_tables_hist.heap_blks_read) + sum(statio_all_tables_hist.heap_blks_hit))) DESC;


ALTER TABLE heap_blks_hit_by_table OWNER TO statusr;

--
-- TOC entry 2022 (class 1259 OID 207538179)
-- Name: statio_all_indexes_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE statio_all_indexes_hist (
    now timestamp with time zone,
    relid oid,
    indexrelid oid,
    schemaname name,
    relname name,
    indexrelname name,
    idx_blks_read bigint,
    idx_blks_hit bigint
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE statio_all_indexes_hist OWNER TO statusr;

--
-- TOC entry 2000 (class 1259 OID 206018494)
-- Name: idx_blks_hit_by_table; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_blks_hit_by_table AS
 SELECT statio_all_indexes_hist.schemaname,
    statio_all_indexes_hist.relname,
    (sum(statio_all_indexes_hist.idx_blks_hit) / (sum(statio_all_indexes_hist.idx_blks_read) + sum(statio_all_indexes_hist.idx_blks_hit))) AS idx_blks_hit_ratio,
    sum(statio_all_indexes_hist.idx_blks_read) AS idx_blks_read,
    sum(statio_all_indexes_hist.idx_blks_hit) AS idx_blks_hit
   FROM statio_all_indexes_hist
  WHERE ((statio_all_indexes_hist.idx_blks_read > 0) OR (statio_all_indexes_hist.idx_blks_hit > 0))
  GROUP BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname
  ORDER BY (sum(statio_all_indexes_hist.idx_blks_hit) / (sum(statio_all_indexes_hist.idx_blks_read) + sum(statio_all_indexes_hist.idx_blks_hit))) DESC;


ALTER TABLE idx_blks_hit_by_table OWNER TO statusr;

--
-- TOC entry 2001 (class 1259 OID 206074280)
-- Name: idx_blks_hit_read_delta_by_table_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_blks_hit_read_delta_by_table_by_hh AS
 SELECT statio_all_indexes_hist.now,
    statio_all_indexes_hist.schemaname,
    statio_all_indexes_hist.relname,
    sum(statio_all_indexes_hist.idx_blks_hit) AS idx_blks_hit,
    sum(statio_all_indexes_hist.idx_blks_read) AS idx_blks_read,
    (lag(sum(statio_all_indexes_hist.idx_blks_hit)) OVER (ORDER BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname, statio_all_indexes_hist.now DESC) - lead(sum(statio_all_indexes_hist.idx_blks_hit)) OVER (ORDER BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname, statio_all_indexes_hist.now DESC)) AS idx_blks_hit_delta,
    (lag(sum(statio_all_indexes_hist.idx_blks_read)) OVER (ORDER BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname, statio_all_indexes_hist.now DESC) - lead(sum(statio_all_indexes_hist.idx_blks_read)) OVER (ORDER BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname, statio_all_indexes_hist.now DESC)) AS idx_blks_read_delta
   FROM statio_all_indexes_hist
  GROUP BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname, statio_all_indexes_hist.now
  ORDER BY statio_all_indexes_hist.schemaname, statio_all_indexes_hist.relname, statio_all_indexes_hist.now;


ALTER TABLE idx_blks_hit_read_delta_by_table_by_hh OWNER TO statusr;

--
-- TOC entry 2019 (class 1259 OID 207538170)
-- Name: stat_all_tables_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE stat_all_tables_hist (
    now timestamp with time zone,
    relid oid,
    schemaname name,
    relname name,
    seq_scan bigint,
    seq_tup_read bigint,
    idx_scan bigint,
    idx_tup_fetch bigint,
    n_tup_ins bigint,
    n_tup_upd bigint,
    n_tup_del bigint,
    n_tup_hot_upd bigint,
    n_live_tup bigint,
    n_dead_tup bigint,
    n_mod_since_analyze bigint,
    last_vacuum timestamp with time zone,
    last_autovacuum timestamp with time zone,
    last_analyze timestamp with time zone,
    last_autoanalyze timestamp with time zone,
    vacuum_count bigint,
    autovacuum_count bigint,
    analyze_count bigint,
    autoanalyze_count bigint
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_all_tables_hist OWNER TO statusr;

--
-- TOC entry 1984 (class 1259 OID 201375104)
-- Name: idx_scan_by_schema; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_scan_by_schema AS
 SELECT stat_all_tables_hist.schemaname,
    (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist.seq_scan))) AS idx_scan_ratio,
    sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan
   FROM stat_all_tables_hist
  GROUP BY stat_all_tables_hist.schemaname
  ORDER BY (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist.seq_scan))) DESC;


ALTER TABLE idx_scan_by_schema OWNER TO statusr;

--
-- TOC entry 2357 (class 1259 OID 259304127)
-- Name: stat_all_tables_hist2; Type: FOREIGN TABLE; Schema: dba; Owner: postgres
--

CREATE FOREIGN TABLE stat_all_tables_hist2 (
    now timestamp with time zone,
    relid oid,
    schemaname name,
    relname name,
    seq_scan bigint,
    seq_tup_read bigint,
    idx_scan bigint,
    idx_tup_fetch bigint,
    n_tup_ins bigint,
    n_tup_upd bigint,
    n_tup_del bigint,
    n_tup_hot_upd bigint,
    n_live_tup bigint,
    n_dead_tup bigint,
    n_mod_since_analyze bigint,
    last_vacuum timestamp with time zone,
    last_autovacuum timestamp with time zone,
    last_analyze timestamp with time zone,
    last_autoanalyze timestamp with time zone,
    vacuum_count bigint,
    autovacuum_count bigint,
    analyze_count bigint,
    autoanalyze_count bigint
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_all_tables_hist2 OWNER TO postgres;

--
-- TOC entry 2358 (class 1259 OID 259342803)
-- Name: idx_scan_by_schema2; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_scan_by_schema2 AS
 SELECT stat_all_tables_hist2.schemaname,
    (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist2.seq_scan))) AS idx_scan_ratio,
    sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (0)::bigint
        END) AS idx_scan,
    sum(stat_all_tables_hist2.seq_scan) AS seq_scan
   FROM stat_all_tables_hist2
  GROUP BY stat_all_tables_hist2.schemaname
  ORDER BY (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist2.seq_scan))) DESC;


ALTER TABLE idx_scan_by_schema2 OWNER TO statusr;

--
-- TOC entry 2064 (class 1259 OID 211195360)
-- Name: idx_scan_by_schema_by_day; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_scan_by_schema_by_day AS
 SELECT date_trunc('day'::text, stat_all_tables_hist.now) AS "Day",
    stat_all_tables_hist.schemaname,
    (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist.seq_scan))) AS idx_scan_ratio,
    sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan
   FROM stat_all_tables_hist
  GROUP BY (date_trunc('day'::text, stat_all_tables_hist.now)), stat_all_tables_hist.schemaname
  ORDER BY (date_trunc('day'::text, stat_all_tables_hist.now));


ALTER TABLE idx_scan_by_schema_by_day OWNER TO statusr;

--
-- TOC entry 2045 (class 1259 OID 209867791)
-- Name: idx_scan_by_table; Type: VIEW; Schema: dba; Owner: postgres
--

CREATE VIEW idx_scan_by_table AS
 SELECT stat_all_tables_hist.schemaname,
    stat_all_tables_hist.relname,
    (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist.seq_scan))) AS idx_scan_ratio,
    sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan
   FROM stat_all_tables_hist
  WHERE ((stat_all_tables_hist.idx_scan > 0) OR (stat_all_tables_hist.seq_scan > 0))
  GROUP BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname
  ORDER BY (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist.idx_scan > 0) THEN stat_all_tables_hist.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist.seq_scan))) DESC;


ALTER TABLE idx_scan_by_table OWNER TO postgres;

--
-- TOC entry 2359 (class 1259 OID 259343667)
-- Name: idx_scan_by_table2; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_scan_by_table2 AS
 SELECT stat_all_tables_hist2.schemaname,
    stat_all_tables_hist2.relname,
    (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist2.seq_scan))) AS idx_scan_ratio,
    sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (0)::bigint
        END) AS idx_scan,
    sum(stat_all_tables_hist2.seq_scan) AS seq_scan
   FROM stat_all_tables_hist2
  WHERE ((stat_all_tables_hist2.idx_scan > 0) OR (stat_all_tables_hist2.seq_scan > 0))
  GROUP BY stat_all_tables_hist2.schemaname, stat_all_tables_hist2.relname
  ORDER BY (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (0)::bigint
        END) / (sum(
        CASE
            WHEN (stat_all_tables_hist2.idx_scan > 0) THEN stat_all_tables_hist2.idx_scan
            ELSE (1)::bigint
        END) + sum(stat_all_tables_hist2.seq_scan))) DESC;


ALTER TABLE idx_scan_by_table2 OWNER TO statusr;

--
-- TOC entry 2046 (class 1259 OID 209874530)
-- Name: idx_scan_by_table_by_day; Type: VIEW; Schema: dba; Owner: postgres
--

CREATE VIEW idx_scan_by_table_by_day AS
 SELECT date_trunc('day'::text, stat_all_tables_hist.now) AS "Day",
    stat_all_tables_hist.schemaname,
    stat_all_tables_hist.relname,
    (sum(stat_all_tables_hist.idx_scan) / (sum(stat_all_tables_hist.idx_scan) + sum(stat_all_tables_hist.seq_scan))) AS idx_scan_ratio,
    sum(stat_all_tables_hist.idx_scan) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan
   FROM stat_all_tables_hist
  WHERE ((stat_all_tables_hist.idx_scan > 0) OR (stat_all_tables_hist.seq_scan > 0))
  GROUP BY (date_trunc('day'::text, stat_all_tables_hist.now)), stat_all_tables_hist.schemaname, stat_all_tables_hist.relname
  ORDER BY (date_trunc('day'::text, stat_all_tables_hist.now)) DESC;


ALTER TABLE idx_scan_by_table_by_day OWNER TO postgres;

--
-- TOC entry 2015 (class 1259 OID 207487042)
-- Name: idx_scan_by_table_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_scan_by_table_by_hh AS
 SELECT stat_all_tables_hist.now,
    stat_all_tables_hist.schemaname,
    stat_all_tables_hist.relname,
    (sum(stat_all_tables_hist.idx_scan) / (sum(stat_all_tables_hist.idx_scan) + sum(stat_all_tables_hist.seq_scan))) AS idx_scan_ratio,
    sum(stat_all_tables_hist.idx_scan) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan
   FROM stat_all_tables_hist
  WHERE ((stat_all_tables_hist.idx_scan > 0) OR (stat_all_tables_hist.seq_scan > 0))
  GROUP BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now
  ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now;


ALTER TABLE idx_scan_by_table_by_hh OWNER TO statusr;

--
-- TOC entry 2363 (class 1259 OID 259814541)
-- Name: idx_scan_by_table_by_hh2; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_scan_by_table_by_hh2 AS
 SELECT stat_all_tables_hist2.now,
    stat_all_tables_hist2.schemaname,
    stat_all_tables_hist2.relname,
    (sum(stat_all_tables_hist2.idx_scan) / (sum(stat_all_tables_hist2.idx_scan) + sum(stat_all_tables_hist2.seq_scan))) AS idx_scan_ratio,
    sum(stat_all_tables_hist2.idx_scan) AS idx_scan,
    sum(stat_all_tables_hist2.seq_scan) AS seq_scan
   FROM stat_all_tables_hist2
  WHERE ((stat_all_tables_hist2.idx_scan > 0) OR (stat_all_tables_hist2.seq_scan > 0))
  GROUP BY stat_all_tables_hist2.schemaname, stat_all_tables_hist2.relname, stat_all_tables_hist2.now
  ORDER BY stat_all_tables_hist2.schemaname, stat_all_tables_hist2.relname, stat_all_tables_hist2.now;


ALTER TABLE idx_scan_by_table_by_hh2 OWNER TO statusr;

--
-- TOC entry 1989 (class 1259 OID 202339681)
-- Name: idx_seq_scand_delta_by_table_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_seq_scand_delta_by_table_by_hh AS
 SELECT stat_all_tables_hist.now,
    stat_all_tables_hist.schemaname,
    stat_all_tables_hist.relname,
    sum(stat_all_tables_hist.idx_scan) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan,
    (lag(sum(stat_all_tables_hist.idx_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now DESC) - lead(sum(stat_all_tables_hist.idx_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now DESC)) AS idx_scan_delta,
    (lag(sum(stat_all_tables_hist.seq_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now DESC) - lead(sum(stat_all_tables_hist.seq_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now DESC)) AS seq_scan_delta
   FROM stat_all_tables_hist
  GROUP BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now
  ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, stat_all_tables_hist.now;


ALTER TABLE idx_seq_scand_delta_by_table_by_hh OWNER TO statusr;

--
-- TOC entry 1990 (class 1259 OID 202357215)
-- Name: idx_seq_scand_delta_by_table_by_mm; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW idx_seq_scand_delta_by_table_by_mm AS
 SELECT date_part('month'::text, stat_all_tables_hist.now) AS mese,
    date_part('day'::text, stat_all_tables_hist.now) AS ora,
    stat_all_tables_hist.schemaname,
    stat_all_tables_hist.relname,
    sum(stat_all_tables_hist.idx_scan) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan,
    (lag(sum(stat_all_tables_hist.idx_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, (date_part('month'::text, stat_all_tables_hist.now)), (date_part('day'::text, stat_all_tables_hist.now)) DESC) - lead(sum(stat_all_tables_hist.idx_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, (date_part('month'::text, stat_all_tables_hist.now)), (date_part('day'::text, stat_all_tables_hist.now)) DESC)) AS idx_scan_delta,
    (lag(sum(stat_all_tables_hist.seq_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, (date_part('month'::text, stat_all_tables_hist.now)), (date_part('day'::text, stat_all_tables_hist.now)) DESC) - lead(sum(stat_all_tables_hist.seq_scan)) OVER (ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, (date_part('month'::text, stat_all_tables_hist.now)), (date_part('day'::text, stat_all_tables_hist.now)) DESC)) AS seq_scan_delta
   FROM stat_all_tables_hist
  GROUP BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, (date_part('month'::text, stat_all_tables_hist.now)), (date_part('day'::text, stat_all_tables_hist.now))
  ORDER BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname, (date_part('month'::text, stat_all_tables_hist.now)) DESC, (date_part('day'::text, stat_all_tables_hist.now));


ALTER TABLE idx_seq_scand_delta_by_table_by_mm OWNER TO statusr;

--
-- TOC entry 2010 (class 1259 OID 207192088)
-- Name: lista_schemi; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW lista_schemi AS
 SELECT pg_namespace.nspname
   FROM pg_namespace
  WHERE ((pg_namespace.nspname !~ '^pg_'::text) AND (pg_namespace.nspname <> 'information_schema'::name))
  ORDER BY pg_namespace.nspname;


ALTER TABLE lista_schemi OWNER TO statusr;

--
-- TOC entry 2021 (class 1259 OID 207538176)
-- Name: stat_statements_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE stat_statements_hist (
    now timestamp with time zone,
    userid oid,
    dbid oid,
    queryid bigint,
    query text,
    calls bigint,
    total_time double precision,
    min_time double precision,
    max_time double precision,
    mean_time double precision,
    stddev_time double precision,
    rows bigint,
    shared_blks_hit bigint,
    shared_blks_read bigint,
    shared_blks_dirtied bigint,
    shared_blks_written bigint,
    local_blks_hit bigint,
    local_blks_read bigint,
    local_blks_dirtied bigint,
    local_blks_written bigint,
    temp_blks_read bigint,
    temp_blks_written bigint,
    blk_read_time double precision,
    blk_write_time double precision
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_statements_hist OWNER TO statusr;

--
-- TOC entry 2062 (class 1259 OID 210992121)
-- Name: mean_time_by_day_table; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW mean_time_by_day_table AS
 SELECT date_trunc('day'::text, stat_statements_hist.now) AS "Day",
    sum(stat_statements_hist.calls) AS calls,
    sum(stat_statements_hist.total_time) AS tottime,
    sum(stat_statements_hist.mean_time) AS meantime,
    (sum(stat_statements_hist.total_time) / (sum(stat_statements_hist.calls))::double precision) AS metime
   FROM stat_statements_hist
  WHERE (stat_statements_hist.query ~~ '%mde_accounts_info%'::text)
  GROUP BY (date_trunc('day'::text, stat_statements_hist.now))
  ORDER BY (date_trunc('day'::text, stat_statements_hist.now));


ALTER TABLE mean_time_by_day_table OWNER TO statusr;

--
-- TOC entry 2063 (class 1259 OID 210994431)
-- Name: mean_time_by_queryid_by_statement; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW mean_time_by_queryid_by_statement AS
 SELECT date_trunc('day'::text, stat_statements_hist.now) AS "Day",
    stat_statements_hist.queryid,
    sum(stat_statements_hist.calls) AS calls,
    sum(stat_statements_hist.total_time) AS tottime,
    sum(stat_statements_hist.mean_time) AS meantime,
    (sum(stat_statements_hist.total_time) / (sum(stat_statements_hist.calls))::double precision) AS metime
   FROM stat_statements_hist
  WHERE (stat_statements_hist.query ~~ '%mde_accounts_info%'::text)
  GROUP BY (date_trunc('day'::text, stat_statements_hist.now)), stat_statements_hist.queryid
  ORDER BY (date_trunc('day'::text, stat_statements_hist.now));


ALTER TABLE mean_time_by_queryid_by_statement OWNER TO statusr;

--
-- TOC entry 2008 (class 1259 OID 207181807)
-- Name: missingfkindexes; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW missingfkindexes AS
 SELECT date_trunc('seconds'::text, now()) AS date_trunc,
    current_database() AS current_database,
    pg_class.relname,
    (((((((('CREATE or REPLACE INDEX idx_'::text || (pg_class.relname)::text) || '_'::text) || array_to_string(candidate_index.column_name_list, '_'::text)) || ' ON '::text) || candidate_index.conrelid) || ' ('::text) || array_to_string(candidate_index.column_name_list, ','::text)) || ')'::text) AS ddl
   FROM ((( SELECT DISTINCT fkey.conrelid,
            array_agg(pg_attribute.attname) AS column_name_list,
            array_agg(pg_attribute.attnum) AS column_list
           FROM (pg_attribute
             JOIN ( SELECT (fkey_1.conrelid)::regclass AS conrelid,
                    fkey_1.conname,
                    unnest(fkey_1.conkey) AS column_index
                   FROM ( SELECT DISTINCT pg_constraint.conrelid,
                            pg_constraint.conname,
                            pg_constraint.conkey
                           FROM ((pg_constraint
                             JOIN pg_class pg_class_1 ON ((pg_class_1.oid = pg_constraint.conrelid)))
                             JOIN pg_namespace ON ((pg_namespace.oid = pg_class_1.relnamespace)))
                          WHERE ((pg_namespace.nspname !~ '^pg_'::text) AND (pg_namespace.nspname <> 'information_schema'::name) AND (pg_constraint.contype = 'f'::"char"))) fkey_1) fkey ON ((((fkey.conrelid)::oid = pg_attribute.attrelid) AND (fkey.column_index = pg_attribute.attnum))))
          GROUP BY fkey.conrelid, fkey.conname) candidate_index
     JOIN pg_class ON ((pg_class.oid = (candidate_index.conrelid)::oid)))
     LEFT JOIN pg_index ON (((pg_index.indrelid = (candidate_index.conrelid)::oid) AND ((pg_index.indkey)::text = array_to_string(candidate_index.column_list, ' '::text)))))
  WHERE (pg_index.indrelid IS NULL);


ALTER TABLE missingfkindexes OWNER TO statusr;

SET default_with_oids = false;

--
-- TOC entry 2097 (class 1259 OID 218779155)
-- Name: unusedindexes_store; Type: TABLE; Schema: dba; Owner: postgres
--

CREATE TABLE unusedindexes_store (
    date_trunc timestamp with time zone,
    current_database name,
    schemaname name,
    relname name,
    indexrelname name,
    pg_get_indexdef text
)
WITH (autovacuum_enabled='false');


ALTER TABLE unusedindexes_store OWNER TO postgres;

--
-- TOC entry 2099 (class 1259 OID 218806412)
-- Name: missing_idx_already_in_unused_store; Type: VIEW; Schema: dba; Owner: postgres
--

CREATE VIEW missing_idx_already_in_unused_store AS
 SELECT u.schemaname,
    u.relname,
    u.indexrelname
   FROM unusedindexes_store u,
    missingfkindexes m
  WHERE ((u.relname = m.relname) AND (u.current_database = m.current_database) AND (rtrim("substring"(m.ddl, 25, "position"("substring"(m.ddl, 25, 300), ' '::text)), ' '::text) = (u.indexrelname)::text));


ALTER TABLE missing_idx_already_in_unused_store OWNER TO postgres;

--
-- TOC entry 2098 (class 1259 OID 218806289)
-- Name: missing_idx_not_in_unused_store; Type: VIEW; Schema: dba; Owner: postgres
--

CREATE VIEW missing_idx_not_in_unused_store AS
 SELECT m.date_trunc,
    m.current_database,
    m.relname,
    m.ddl
   FROM missingfkindexes m
  WHERE (NOT (EXISTS ( SELECT u.date_trunc,
            u.current_database,
            u.schemaname,
            u.relname,
            u.indexrelname,
            u.pg_get_indexdef
           FROM unusedindexes_store u
          WHERE ((u.relname = m.relname) AND (u.current_database = m.current_database) AND (rtrim("substring"(m.ddl, 25, "position"("substring"(m.ddl, 25, 300), ' '::text)), ' '::text) = (u.indexrelname)::text)))));


ALTER TABLE missing_idx_not_in_unused_store OWNER TO postgres;

--
-- TOC entry 2005 (class 1259 OID 206864877)
-- Name: relation_pretty_size; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW relation_pretty_size AS
 SELECT a.oid,
    a.table_schema,
    a.table_name,
    a.row_estimate,
    a.total_bytes,
    a.index_bytes,
    a.toast_bytes,
    a.table_bytes,
    pg_size_pretty(a.total_bytes) AS total,
    pg_size_pretty(a.index_bytes) AS index,
    pg_size_pretty(a.toast_bytes) AS toast,
    pg_size_pretty(a.table_bytes) AS "table"
   FROM ( SELECT a_1.oid,
            a_1.table_schema,
            a_1.table_name,
            a_1.row_estimate,
            a_1.total_bytes,
            a_1.index_bytes,
            a_1.toast_bytes,
            ((a_1.total_bytes - a_1.index_bytes) - COALESCE(a_1.toast_bytes, (0)::bigint)) AS table_bytes
           FROM ( SELECT c.oid,
                    n.nspname AS table_schema,
                    c.relname AS table_name,
                    c.reltuples AS row_estimate,
                    pg_total_relation_size((c.oid)::regclass) AS total_bytes,
                    pg_indexes_size((c.oid)::regclass) AS index_bytes,
                    pg_total_relation_size((c.reltoastrelid)::regclass) AS toast_bytes
                   FROM (pg_class c
                     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
                  WHERE (c.relkind = 'r'::"char")) a_1) a
  ORDER BY a.total_bytes;


ALTER TABLE relation_pretty_size OWNER TO statusr;

--
-- TOC entry 2006 (class 1259 OID 206865068)
-- Name: relation_size; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW relation_size AS
 SELECT (((n.nspname)::text || '.'::text) || (c.relname)::text) AS relation,
    pg_size_pretty(pg_relation_size((c.oid)::regclass)) AS size
   FROM (pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name]))
  ORDER BY (pg_relation_size((c.oid)::regclass)) DESC;


ALTER TABLE relation_size OWNER TO statusr;

--
-- TOC entry 2024 (class 1259 OID 207576033)
-- Name: relation_size_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE relation_size_hist (
    now timestamp with time zone,
    oid oid,
    table_schema name,
    table_name name,
    row_estimate real,
    total_bytes bigint,
    index_bytes bigint,
    toast_bytes bigint,
    table_bytes bigint,
    total text,
    index text,
    toast text,
    "table" text
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE relation_size_hist OWNER TO statusr;

--
-- TOC entry 1985 (class 1259 OID 201381423)
-- Name: seq_scan_by_table; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW seq_scan_by_table AS
 SELECT stat_all_tables_hist.schemaname,
    stat_all_tables_hist.relname,
    (sum(stat_all_tables_hist.idx_scan) / (sum(stat_all_tables_hist.idx_scan) + sum(stat_all_tables_hist.seq_scan))) AS idx_scan_ratio,
    sum(stat_all_tables_hist.idx_scan) AS idx_scan,
    sum(stat_all_tables_hist.seq_scan) AS seq_scan
   FROM stat_all_tables_hist
  WHERE ((stat_all_tables_hist.idx_scan > 0) OR (stat_all_tables_hist.seq_scan > 0))
  GROUP BY stat_all_tables_hist.schemaname, stat_all_tables_hist.relname
  ORDER BY (sum(stat_all_tables_hist.seq_scan)) DESC;


ALTER TABLE seq_scan_by_table OWNER TO statusr;

--
-- TOC entry 2018 (class 1259 OID 207538167)
-- Name: stat_all_indexes_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE stat_all_indexes_hist (
    now timestamp with time zone,
    relid oid,
    indexrelid oid,
    schemaname name,
    relname name,
    indexrelname name,
    idx_scan bigint,
    idx_tup_read bigint,
    idx_tup_fetch bigint
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_all_indexes_hist OWNER TO statusr;

--
-- TOC entry 2361 (class 1259 OID 259375375)
-- Name: stat_database_hist2; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE stat_database_hist2 (
    now timestamp with time zone,
    datid oid,
    datname name,
    numbackends integer,
    xact_commit bigint,
    xact_rollback bigint,
    blks_read bigint,
    blks_hit bigint,
    tup_returned bigint,
    tup_fetched bigint,
    tup_inserted bigint,
    tup_updated bigint,
    tup_deleted bigint,
    conflicts bigint,
    temp_files bigint,
    temp_bytes bigint,
    deadlocks bigint,
    blk_read_time double precision,
    blk_write_time double precision,
    stats_reset timestamp with time zone
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_database_hist2 OWNER TO statusr;

--
-- TOC entry 2034 (class 1259 OID 208670252)
-- Name: stat_database_hist_gp; Type: FOREIGN TABLE; Schema: dba; Owner: postgres
--

CREATE FOREIGN TABLE stat_database_hist_gp (
    now timestamp with time zone,
    datid oid,
    datname name,
    numbackends integer,
    xact_commit bigint,
    xact_rollback bigint,
    blks_read bigint,
    blks_hit bigint,
    tup_returned bigint,
    tup_fetched bigint,
    tup_inserted bigint,
    tup_updated bigint,
    tup_deleted bigint,
    conflicts bigint,
    temp_files bigint,
    temp_bytes bigint,
    deadlocks bigint,
    blk_read_time double precision,
    blk_write_time double precision,
    stats_reset timestamp with time zone
)
SERVER gpstatsrv;


ALTER FOREIGN TABLE stat_database_hist_gp OWNER TO postgres;

--
-- TOC entry 2360 (class 1259 OID 259358568)
-- Name: stat_statements_hist2; Type: FOREIGN TABLE; Schema: dba; Owner: postgres
--

CREATE FOREIGN TABLE stat_statements_hist2 (
    now timestamp with time zone,
    userid oid,
    dbid oid,
    queryid bigint,
    query text,
    calls bigint,
    total_time double precision,
    min_time double precision,
    max_time double precision,
    mean_time double precision,
    stddev_time double precision,
    rows bigint,
    shared_blks_hit bigint,
    shared_blks_read bigint,
    shared_blks_dirtied bigint,
    shared_blks_written bigint,
    local_blks_hit bigint,
    local_blks_read bigint,
    local_blks_dirtied bigint,
    local_blks_written bigint,
    temp_blks_read bigint,
    temp_blks_written bigint,
    blk_read_time double precision,
    blk_write_time double precision
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE stat_statements_hist2 OWNER TO postgres;

--
-- TOC entry 1991 (class 1259 OID 202371649)
-- Name: statement_mean_time_by_queryid_by_mm; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW statement_mean_time_by_queryid_by_mm AS
 SELECT date_part('month'::text, stat_statements_hist.now) AS mese,
    date_part('day'::text, stat_statements_hist.now) AS ora,
    stat_statements_hist.queryid,
    sum(stat_statements_hist.calls) AS calls,
    (sum(stat_statements_hist.total_time) / (sum(stat_statements_hist.calls))::double precision) AS meantime
   FROM stat_statements_hist
  GROUP BY (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)), stat_statements_hist.queryid
  ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)) DESC, (date_part('day'::text, stat_statements_hist.now));


ALTER TABLE statement_mean_time_by_queryid_by_mm OWNER TO statusr;

--
-- TOC entry 2060 (class 1259 OID 210953595)
-- Name: statements_calls_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW statements_calls_by_hh AS
 SELECT stat_statements_hist.now,
    sum(stat_statements_hist.calls) AS sum,
    lead(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.now DESC) AS prev_calls,
    lag(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.now DESC) AS next_calls,
    (lag(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.now DESC) - lead(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.now DESC)) AS diff_calls
   FROM stat_statements_hist
  GROUP BY stat_statements_hist.now
  ORDER BY stat_statements_hist.now;


ALTER TABLE statements_calls_by_hh OWNER TO statusr;

--
-- TOC entry 1994 (class 1259 OID 204700201)
-- Name: statements_query_calls_time_delta_by_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW statements_query_calls_time_delta_by_by_hh AS
 SELECT stat_statements_hist.now,
    stat_statements_hist.queryid,
    sum(stat_statements_hist.calls) AS calls,
    (lag(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.queryid, stat_statements_hist.now DESC) - lead(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.queryid, stat_statements_hist.now DESC)) AS calls_delta,
    sum(stat_statements_hist.total_time) AS total_time,
    (lag(sum(stat_statements_hist.total_time)) OVER (ORDER BY stat_statements_hist.queryid, stat_statements_hist.now DESC) - lead(sum(stat_statements_hist.total_time)) OVER (ORDER BY stat_statements_hist.queryid, stat_statements_hist.now DESC)) AS total_time_delta,
    sum(stat_statements_hist.mean_time) AS mean_time,
    (lag(sum(stat_statements_hist.mean_time)) OVER (ORDER BY stat_statements_hist.queryid, stat_statements_hist.now DESC) - lead(sum(stat_statements_hist.mean_time)) OVER (ORDER BY stat_statements_hist.queryid, stat_statements_hist.now DESC)) AS mean_time_delta
   FROM stat_statements_hist
  GROUP BY stat_statements_hist.queryid, stat_statements_hist.now
  ORDER BY stat_statements_hist.queryid, stat_statements_hist.now;


ALTER TABLE statements_query_calls_time_delta_by_by_hh OWNER TO statusr;

--
-- TOC entry 1995 (class 1259 OID 204736488)
-- Name: statements_query_calls_time_delta_by_by_mm; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW statements_query_calls_time_delta_by_by_mm AS
 SELECT date_part('month'::text, stat_statements_hist.now) AS mese,
    date_part('day'::text, stat_statements_hist.now) AS giorno,
    stat_statements_hist.queryid,
    sum(stat_statements_hist.calls) AS calls,
    (lag(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)) DESC) - lead(sum(stat_statements_hist.calls)) OVER (ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)) DESC)) AS calls_delta,
    sum(stat_statements_hist.total_time) AS total_time,
    (lag(sum(stat_statements_hist.total_time)) OVER (ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)) DESC) - lead(sum(stat_statements_hist.total_time)) OVER (ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)) DESC)) AS total_time_delta,
    sum(stat_statements_hist.mean_time) AS mean_time,
    (lag(sum(stat_statements_hist.mean_time)) OVER (ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)) DESC) - lead(sum(stat_statements_hist.mean_time)) OVER (ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now)) DESC)) AS mean_time_delta
   FROM stat_statements_hist
  GROUP BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)), (date_part('day'::text, stat_statements_hist.now))
  ORDER BY stat_statements_hist.queryid, (date_part('month'::text, stat_statements_hist.now)) DESC, (date_part('day'::text, stat_statements_hist.now));


ALTER TABLE statements_query_calls_time_delta_by_by_mm OWNER TO statusr;

--
-- TOC entry 2002 (class 1259 OID 206075690)
-- Name: table_idx_blks_hit_read_delta_by_table_by_hh; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW table_idx_blks_hit_read_delta_by_table_by_hh AS
 SELECT statio_all_tables_hist.now,
    statio_all_tables_hist.schemaname,
    statio_all_tables_hist.relname,
    sum(statio_all_tables_hist.idx_blks_hit) AS idx_blks_hit,
    sum(statio_all_tables_hist.idx_blks_read) AS idx_blks_read,
    (lag(sum(statio_all_tables_hist.idx_blks_hit)) OVER (ORDER BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname, statio_all_tables_hist.now DESC) - lead(sum(statio_all_tables_hist.idx_blks_hit)) OVER (ORDER BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname, statio_all_tables_hist.now DESC)) AS idx_blks_hit_delta,
    (lag(sum(statio_all_tables_hist.idx_blks_read)) OVER (ORDER BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname, statio_all_tables_hist.now DESC) - lead(sum(statio_all_tables_hist.idx_blks_read)) OVER (ORDER BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname, statio_all_tables_hist.now DESC)) AS idx_blks_read_delta
   FROM statio_all_tables_hist
  GROUP BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname, statio_all_tables_hist.now
  ORDER BY statio_all_tables_hist.schemaname, statio_all_tables_hist.relname, statio_all_tables_hist.now;


ALTER TABLE table_idx_blks_hit_read_delta_by_table_by_hh OWNER TO statusr;

--
-- TOC entry 2055 (class 1259 OID 210945674)
-- Name: table_size_by_hh; Type: VIEW; Schema: dba; Owner: postgres
--

CREATE VIEW table_size_by_hh AS
 SELECT relation_size_hist.now,
    relation_size_hist.table_schema,
    relation_size_hist.table_name,
    relation_size_hist.total,
    relation_size_hist.index,
    relation_size_hist.toast,
    relation_size_hist."table"
   FROM relation_size_hist
  ORDER BY relation_size_hist.now;


ALTER TABLE table_size_by_hh OWNER TO postgres;

--
-- TOC entry 1980 (class 1259 OID 200564847)
-- Name: times_by_hours; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW times_by_hours AS
 SELECT stat_statements_hist.now,
    count(*) AS numerooperazioni,
    sum(stat_statements_hist.total_time) AS totaltime,
    sum(stat_statements_hist.min_time) AS mintime,
    sum(stat_statements_hist.mean_time) AS meantime,
    sum(stat_statements_hist.max_time) AS asmaxtime
   FROM stat_statements_hist
  GROUP BY stat_statements_hist.now
  ORDER BY stat_statements_hist.now;


ALTER TABLE times_by_hours OWNER TO statusr;

--
-- TOC entry 1988 (class 1259 OID 202319094)
-- Name: tnx_by_hour; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW tnx_by_hour AS
 SELECT stat_database_hist.now,
    sum(stat_database_hist.xact_commit) AS tx_comm,
    (lag(sum(stat_database_hist.xact_commit)) OVER (ORDER BY stat_database_hist.now DESC) - lead(sum(stat_database_hist.xact_commit)) OVER (ORDER BY stat_database_hist.now DESC)) AS tx_comm_delta
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = 'webtng'::name)
  GROUP BY stat_database_hist.now
  ORDER BY stat_database_hist.now;


ALTER TABLE tnx_by_hour OWNER TO statusr;

--
-- TOC entry 2027 (class 1259 OID 207739760)
-- Name: tnx_by_ora; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW tnx_by_ora AS
 SELECT to_char(stat_database_hist.now, 'YYYY-MM-DD HH:00:00'::text) AS ora,
    sum(stat_database_hist.xact_commit) AS tx_comm,
    (lag(sum(stat_database_hist.xact_commit)) OVER (ORDER BY (to_char(stat_database_hist.now, 'YYYY-MM-DD HH:00:00'::text)) DESC) - lead(sum(stat_database_hist.xact_commit)) OVER (ORDER BY (to_char(stat_database_hist.now, 'YYYY-MM-DD HH:00:00'::text)) DESC)) AS tx_comm_delta
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = current_database())
  GROUP BY (to_char(stat_database_hist.now, 'YYYY-MM-DD HH:00:00'::text))
  ORDER BY (to_char(stat_database_hist.now, 'YYYY-MM-DD HH:00:00'::text));


ALTER TABLE tnx_by_ora OWNER TO statusr;

--
-- TOC entry 2009 (class 1259 OID 207191664)
-- Name: unusedindexes; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW unusedindexes AS
 SELECT date_trunc('seconds'::text, now()) AS date_trunc,
    current_database() AS current_database,
    pg_stat_user_indexes.schemaname,
    pg_stat_user_indexes.relname,
    pg_stat_user_indexes.indexrelname,
    pg_get_indexdef(pg_stat_user_indexes.indexrelid) AS pg_get_indexdef
   FROM (pg_stat_user_indexes
     JOIN pg_index ON ((pg_index.indexrelid = pg_stat_user_indexes.indexrelid)))
  WHERE ((NOT (pg_stat_user_indexes.indexrelname ~~* 'fki%'::text)) AND (NOT pg_index.indisprimary) AND (NOT pg_index.indisunique) AND (pg_stat_user_indexes.idx_scan = 0) AND (NOT pg_index.indisexclusion))
  ORDER BY pg_stat_user_indexes.schemaname, pg_stat_user_indexes.relname, pg_stat_user_indexes.indexrelname;


ALTER TABLE unusedindexes OWNER TO statusr;

--
-- TOC entry 2116 (class 1259 OID 222298066)
-- Name: unusedindexes_not_in_unused_store; Type: VIEW; Schema: dba; Owner: postgres
--

CREATE VIEW unusedindexes_not_in_unused_store AS
 SELECT u.date_trunc,
    u.current_database,
    u.schemaname,
    u.relname,
    u.indexrelname,
    u.pg_get_indexdef
   FROM unusedindexes u
  WHERE (NOT (u.indexrelname IN ( SELECT s.indexrelname
           FROM unusedindexes_store s
          WHERE ((u.indexrelname = s.indexrelname) AND (u.relname = s.relname)))));


ALTER TABLE unusedindexes_not_in_unused_store OWNER TO postgres;

--
-- TOC entry 2117 (class 1259 OID 222303731)
-- Name: unusedindexes_store_hist; Type: FOREIGN TABLE; Schema: dba; Owner: statusr
--

CREATE FOREIGN TABLE unusedindexes_store_hist (
    date_trunc timestamp with time zone,
    current_database name,
    schemaname name,
    relname name,
    indexrelname name,
    pg_get_indexdef text
)
SERVER pgstatsrv;


ALTER FOREIGN TABLE unusedindexes_store_hist OWNER TO statusr;

--
-- TOC entry 2057 (class 1259 OID 210948954)
-- Name: xact_by_hour; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW xact_by_hour AS
 SELECT "Window".now,
    "Window".tx_comm,
    (lag("Window".tx_comm) OVER (ORDER BY "Window".now DESC) - lead("Window".tx_comm) OVER (ORDER BY "Window".now DESC)) AS tx_comm_delta
   FROM ( SELECT stat_database_hist.now,
            sum(stat_database_hist.xact_commit) AS tx_comm
           FROM stat_database_hist
          WHERE (stat_database_hist.datname = 'webtng'::name)
          GROUP BY stat_database_hist.now) "Window"(now, tx_comm)
  ORDER BY "Window".now;


ALTER TABLE xact_by_hour OWNER TO statusr;

--
-- TOC entry 1979 (class 1259 OID 200554978)
-- Name: xact_ratio; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW xact_ratio AS
 SELECT stat_database_hist.now,
    ((stat_database_hist.xact_commit)::double precision / ((stat_database_hist.xact_commit + stat_database_hist.xact_rollback))::double precision) AS successful_xact_ratio
   FROM stat_database_hist
  WHERE (stat_database_hist.datname = current_database())
  ORDER BY stat_database_hist.now;


ALTER TABLE xact_ratio OWNER TO statusr;

--
-- TOC entry 2362 (class 1259 OID 259809611)
-- Name: xact_ratio2; Type: VIEW; Schema: dba; Owner: statusr
--

CREATE VIEW xact_ratio2 AS
 SELECT stat_database_hist2.now,
    ((stat_database_hist2.xact_commit)::double precision / ((stat_database_hist2.xact_commit + stat_database_hist2.xact_rollback))::double precision) AS successful_xact_ratio
   FROM stat_database_hist2
  WHERE (stat_database_hist2.datname = current_database())
  ORDER BY stat_database_hist2.now;


ALTER TABLE xact_ratio2 OWNER TO statusr;

-- Completed on 2017-11-29 12:05:32 CET

--
-- PostgreSQL database dump complete
--

