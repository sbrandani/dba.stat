# dba.stat
a set of views and foreign tables to collect statistics from a running PostgreSQL server

The statistics collected from a postgres production database are transferred to external tables on a staging database so as not to weigh down the production db.

From here they can be  decanted on greenplum or other BI databases to have the possibility of use analytics on the data.

#
# Installation and Usage
#


#
##### Requirements
#

Following adjustments must be set on the postgres configuration file

#
################ QUERY ANALISYS
#
shared_preload_libraries = 'pg_stat_statements'

pg_stat_statements.max = 10000

pg_stat_statements.track = all


#
### How to Install
#
proddb=# CREATE EXTENSION postgres_fdw;
CREATE EXTENSION

proddb=# CREATE SERVER pgstatsrv FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'pgstage01ng', dbname 'statdb', port '5432');
CREATE SERVER

proddb=#create role statusr login inherit superuser password 'statpwd';
CREATE ROLE

proddb=# CREATE USER MAPPING FOR statusr SERVER pgstatsrv OPTIONS (user 'statusr', password 'statpwd');
CREATE USER MAPPING

psql proddb < dba_schema.sql

#
### List dba tables
#
\det dba.
 Schema |          Table           |  Server
--------+--------------------------+-----------
 dba    | db_size_hist             | pgstatsrv
 dba    | relation_size_hist       | pgstatsrv
 dba    | stat_all_indexes_hist    | pgstatsrv
 dba    | stat_all_tables_hist     | pgstatsrv
 dba    | stat_database_hist       | pgstatsrv
 dba    | stat_statements_hist     | pgstatsrv
 dba    | statio_all_indexes_hist  | pgstatsrv
 dba    | statio_all_tables_hist   | pgstatsrv
 dba    | unusedindexes_store_hist | pgstatsrv

#
### List dba views 
#
webtng=# \dv dba.
 Schema |                     Name                     | Type |  Owner
--------+----------------------------------------------+------+----------
 dba    | cache_blks_read_hit_delta_hh                 | view | statusr
 dba    | cache_hit_ratio_delta_by_hh                  | view | statusr
 dba    | cache_hit_ratio_hh                           | view | statusr
 dba    | database_size                                | view | statusr
 dba    | db_size                                      | view | statusr
 dba    | db_size_by_hh                                | view | statusr
 dba    | db_statistiche_hh                            | view | statusr
 dba    | heap_blks_hit_by_table                       | view | statusr
 dba    | idx_blks_hit_by_table                        | view | statusr
 dba    | idx_blks_hit_read_delta_by_table_by_hh       | view | statusr
 dba    | idx_scan_by_schema                           | view | statusr
 dba    | idx_scan_by_schema_by_day                    | view | statusr
 dba    | idx_scan_by_table                            | view | postgres
 dba    | idx_scan_by_table_by_day                     | view | postgres
 dba    | idx_scan_by_table_by_hh                      | view | statusr
 dba    | idx_seq_scand_delta_by_table_by_hh           | view | statusr
 dba    | idx_seq_scand_delta_by_table_by_mm           | view | statusr
 dba    | lista_schemi                                 | view | statusr
 dba    | mean_time_by_day_table                       | view | statusr
 dba    | mean_time_by_queryid_by_statement            | view | statusr
 dba    | missing_idx_already_in_unused_store          | view | postgres
 dba    | missing_idx_not_in_unused_store              | view | postgres
 dba    | missingfkindexes                             | view | statusr
 dba    | relation_pretty_size                         | view | statusr
 dba    | relation_size                                | view | statusr
 dba    | seq_scan_by_table                            | view | statusr
 dba    | statement_mean_time_by_queryid_by_mm         | view | statusr
 dba    | statements_calls_by_hh                       | view | statusr
 dba    | statements_query_calls_time_delta_by_by_hh   | view | statusr
 dba    | statements_query_calls_time_delta_by_by_mm   | view | statusr
 dba    | table_idx_blks_hit_read_delta_by_table_by_hh | view | statusr
 dba    | table_size_by_hh                             | view | postgres
 dba    | times_by_hours                               | view | statusr
 dba    | tnx_by_hour                                  | view | statusr
 dba    | tnx_by_ora                                   | view | statusr
 dba    | unusedindexes                                | view | statusr
 dba    | unusedindexes_not_in_unused_store            | view | postgres
 dba    | xact_by_hour                                 | view | statusr
 dba    | xact_ratio                                   | view | statusr

#
# Example of Use
#



