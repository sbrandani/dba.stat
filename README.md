# dba.stat
a set of views and foreign tables to collect statistics from a running PostgreSQL server

The statistics collected from a postgres production database are transferred to external tables on a staging database so as not to weigh down the production db.

From here they can be  decanted on greenplum or other BI databases to have the possibility of use analytics on the data.

#
# Installation and Usage
#


#
### Requirements
#

Following adjustments must be set on the postgres configuration file

#
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

#### create dba schema structure

psql proddb < dba_schema.sql

#### schedule the populate script (see populate file)



#
# Example of Use
#
the statistics collected from  postgres are transferred to external tabless on a staging database so as not to weigh down the production db. From here they can be investigated with pre build views 


the collecting tables are:
 
 dba.db_size_hist
 dba.stat_database_hist
 dba.stat_all_tables_hist
 dba.stat_all_indexes_hist
 dba.statio_all_tables_hist
 dba.statio_all_indexes_hist
 dba.stat_statements_hist
 dba.relation_size_hist
 
 
are the photograph of the statistics at the time of the survey.

on these you can make queries to see:

-- space trend of the db
-
select * from dba.db_size_by_hh;
   
-- space trand of tables 
-
select * from dba.table_size_by_hh where table_name='table_name'; 
  
-- number of transactions by hour
-
  select * from xact_by_hour;
  
-- transactions percents (commit vs rollback)
-
select * from xact_ratio
  
-- cahce hit ratio
-
select * from dba.cache_hit_ratio_hh;

-- cache blocks read, hit e delta per ora
-
select * from cache_blks_read_hit_delta_hh
 
-- # statement by hour
-
select * from dba.statements_calls_by_hh;  
 
-- heap blocks read /hit per table
-
select * from  heap_blks_hit_by_table
  
--  index blocks read /hit per table
-
select * from   idx_blks_hit_by_table
 
--  index blocks read /hit per table /hour
-
   select * from idx_blks_hit_read_delta_by_table_by_hh where relname='mobile_logger'; 
 
-- idx scan vs seq scan per schema
-
select * from idx_scan_by_schema

-- idx scan vs seq scan per schema/day
-
   select * from idx_scan_by_schema_by_day where schemaname='crm' ;
 
 -- idx scan vs seq scan per table in schema
 -
 select * from idx_scan_by_table where schemaname='crm';
 
 --  idx scan vs seq scan per table/day
  -
  select * from idx_scan_by_table_by_day  where schemaname='crm' and relname ='mde_accounts_info' order by idx_scan_ratio;
  
 -- mean time , total , num calls  per statements per table/day
  -
  SELECT date_trunc('day'::text, stat_statements_hist.now) AS "Day", 
sum(stat_statements_hist.calls) AS calls, sum(stat_statements_hist.total_time) AS tottime, 
 sum(stat_statements_hist.total_time) / sum(stat_statements_hist.calls)::double precision AS meantime
   FROM stat_statements_hist
  WHERE stat_statements_hist.query ~~ '%mde_accounts_info%'::text
  GROUP BY date_trunc('day'::text, stat_statements_hist.now) 
  ORDER BY date_trunc('day'::text, stat_statements_hist.now) ;
  
 -- mean time , total , num calls  per statements per table/day/ queryid 
  -
   SELECT date_trunc('day'::text, stat_statements_hist.now) AS "Day",
    stat_statements_hist.queryid,
    sum(stat_statements_hist.calls) AS calls,
    sum(stat_statements_hist.total_time) AS tottime,
    sum(stat_statements_hist.total_time) / sum(stat_statements_hist.calls)::double precision AS meantime 
	into temporary table mean_time_by_queryid_by_statementtt
   FROM stat_statements_hist
  WHERE stat_statements_hist.query ~~ '%mde_accounts_info%'::text  
  GROUP BY date_trunc('day'::text, stat_statements_hist.now) , stat_statements_hist.queryid
  ORDER BY date_trunc('day'::text, stat_statements_hist.now) ;
  
  -- queryid  with bigger total time per day on a specified table 
  -
   select * from mean_time_by_queryid_by_statementtt order by "Day",tottime desc;
   
  -- trend of a queryid
  -
  select * from mean_time_by_queryid_by_statementtt where queryid=1014408401;
  select * from mean_time_by_queryid_by_statementtt where queryid=3682175003;

 --  query associated to queryid
 -
 select distinct(query) from stat_statements_hist where queryid=1014408401;
    (select accountsin0_.md_entry_id as md_entry1_28_0_, accountsin0_.account as account2_29_0_, accountsin0_.currency as currency3_29_0_, accountsin0_.type as type4_29_
0_ from crm.mde_accounts_info accountsin0_ where accountsin0_.md_entry_id=$1)
  
  queryid=3682175003


