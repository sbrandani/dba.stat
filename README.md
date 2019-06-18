# dba.stat
a set of views and foreign tables to collect statistics from a running PostgreSQL :elephant: server

The statistics collected from a postgres production database are transferred to external tables on a staging database so as not to weigh down the production db.

From here they can be  decanted on greenplum or other BI databases to have the possibility of use analytics on the data.

#
## Installation and Usage
#


#
#### Requirements
#

Following adjustments must be set on the postgres configuration file

```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
```

#
#### How to Install
#
```
proddb=# CREATE EXTENSION postgres_fdw;
CREATE EXTENSION

proddb=# CREATE SERVER pgstatsrv FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'hoststage', dbname 'statdb', port '5432');
CREATE SERVER

proddb=#create role statusr login inherit superuser password 'statpwd';
CREATE ROLE

proddb=# CREATE USER MAPPING FOR statusr SERVER pgstatsrv OPTIONS (user 'statusr', password 'statpwd');
CREATE USER MAPPING
```
##### create dba schema structure
```
psql proddb < dba_schema.sql
```
##### create dba scan_stat procedure 
Created a procedure to facilitate the identification of the most impactful queries on production database tables
```
psql statdb < scan_stats.sql
```

##### schedule the populate script 
(see populate file)


#
#### Example of Use
#
the statistics collected from  postgres are transferred to external tabless on a staging database so as not to weigh down the production db. From here they can be investigated with pre build views 


the collecting tables are:
 ```
 dba.db_size_hist
 dba.stat_database_hist
 dba.stat_all_tables_hist
 dba.stat_all_indexes_hist
 dba.statio_all_tables_hist
 dba.statio_all_indexes_hist
 dba.stat_statements_hist
 dba.relation_size_hist
 ```
 
contain the history of the statistics collected.

on these you can make queries to see:

 space trend of the db
-
```select * from dba.db_size_by_hh;```
   
 space trand of tables 
-
```select * from dba.table_size_by_hh where table_name='table_name'; ```
  
 number of transactions by hour
-
 ``` select * from xact_by_hour;```
  
 transactions percents (commit vs rollback)
-
```select * from xact_ratio```
  
 cahce hit ratio
-
```select * from dba.cache_hit_ratio_hh;```

 cache blocks read, hit e delta per ora
-
```select * from cache_blks_read_hit_delta_hh```
 
 # statement by hour
-
```select * from dba.statements_calls_by_hh;  ```
 
 heap blocks read /hit per table
-
```select * from  heap_blks_hit_by_table```
  
  index blocks read /hit per table
-
```select * from   idx_blks_hit_by_table```
 
  index blocks read /hit per table /hour
-
   ```select * from idx_blks_hit_read_delta_by_table_by_hh where relname='table_name'; ```
 
 idx scan vs seq scan per schema
-
```select * from idx_scan_by_schema```

 idx scan vs seq scan per schema/day
-
   ```select * from idx_scan_by_schema_by_day where schemaname='crm' ;```
 
 idx scan vs seq scan per table in schema
 -
 ```select * from idx_scan_by_table where schemaname='crm';```
 
  idx scan vs seq scan per table/day
  -
  ```select * from idx_scan_by_table_by_day  where schemaname='crm' and relname ='mde_accounts_info' order by idx_scan_ratio;```
  
 mean time , total , num calls  per statements per table/day
  -
  ```SELECT date_trunc('day'::text, stat_statements_hist.now) AS "Day", 
sum(stat_statements_hist.calls) AS calls, sum(stat_statements_hist.total_time) AS tottime, 
 sum(stat_statements_hist.total_time) / sum(stat_statements_hist.calls)::double precision AS meantime
   FROM stat_statements_hist
  WHERE stat_statements_hist.query ~~ '%accounts_info%'::text
  GROUP BY date_trunc('day'::text, stat_statements_hist.now) 
  ORDER BY date_trunc('day'::text, stat_statements_hist.now) ;
  ```
 mean time , total , num calls  per statements per table/day/ queryid 
  -
   ```SELECT date_trunc('day'::text, stat_statements_hist.now) AS "Day",
    stat_statements_hist.queryid,
    sum(stat_statements_hist.calls) AS calls,
    sum(stat_statements_hist.total_time) AS tottime,
    sum(stat_statements_hist.total_time) / sum(stat_statements_hist.calls)::double precision AS meantime 
	into temporary table mean_time_by_queryid_by_statementtt
   FROM stat_statements_hist
  WHERE stat_statements_hist.query ~~ '%accounts_info%'::text  
  GROUP BY date_trunc('day'::text, stat_statements_hist.now) , stat_statements_hist.queryid
  ORDER BY date_trunc('day'::text, stat_statements_hist.now) ;
  ```
queryid  with bigger total time per day on a specified table 
  -
   ```select * from mean_time_by_queryid_by_statementtt order by "Day",tottime desc;```
   
trend of a queryid
  -
  ```select * from mean_time_by_queryid_by_statementtt where queryid=1014408401;
  select * from mean_time_by_queryid_by_statementtt where queryid=3682175003;
  ```


 run function dba.scan_stats() 
 -
run procedure to facilitate the identification of the most impactful queries 
-
 ```
proddb=#            select * from dba.scan_stats();

Schema.Table: wms.master_bl:idx_scan_ratio:0.99988456758939211935 idx_scan:14657154496seq_scan: 1692106 row_estimate:1.98541e+06
 
 Top 5 Query on aaa.aaa1 by TotalTime
   QueryID:1272194133 - TotalTime:103074.732277 - Calls:112195 - MeanTime:0.918710568893443
   QueryID:2057377605 - TotalTime:41660.2824969991 - Calls:1343442 - MeanTime:0.0310101087333871
   QueryID:160020267 - TotalTime:38765.5858490002 - Calls:53748 - MeanTime:0.721247038940988
   QueryID:3779693044 - TotalTime:18283.942529 - Calls:134849 - MeanTime:0.13558826931605
   QueryID:236275832 - TotalTime:15175.1269129997 - Calls:719121 - MeanTime:0.0211023275818669

  Top 5 Query on aaa.aaa1 by MeanTime
   QueryID:1815477615 - TotalTime:30.348434 - Calls:1 - MeanTime:30.348434
   QueryID:1582277696 - TotalTime:24.594455 - Calls:1 - MeanTime:24.594455
   QueryID:4138201970 - TotalTime:3773.01548 - Calls:3207 - MeanTime:1.17649375740568
   QueryID:3129877883 - TotalTime:38.287207 - Calls:40 - MeanTime:0.957180175
   QueryID:1272194133 - TotalTime:103074.732277 - Calls:112195 - MeanTime:0.918710568893443

Schema.Table: trac.orders:idx_scan_ratio:0.99991852985867954610 idx_scan:27664225573seq_scan: 2253992 row_estimate:1.78453e+06
 
 Top 5 Query on trac.orders by TotalTime
   QueryID:2369621365 - TotalTime:1320495.28835999 - Calls:182570 - MeanTime:7.23281639020644
   QueryID:1396774779 - TotalTime:267007.232035008 - Calls:645367 - MeanTime:0.413729292069485
   QueryID:1662757844 - TotalTime:206530.258677 - Calls:1847841 - MeanTime:0.111768414423644
   QueryID:286582148 - TotalTime:190337.523555 - Calls:1314360 - MeanTime:0.144813843661554
   QueryID:2677075312 - TotalTime:125141.145007 - Calls:119551 - MeanTime:1.04675950018821
 
 Top 5 Query on trac.ordersby MeanTime
   QueryID:553618274 - TotalTime:320.867872 - Calls:1 - MeanTime:320.867872
   QueryID:1534924332 - TotalTime:283.958997 - Calls:1 - MeanTime:283.958997
   QueryID:2464265748 - TotalTime:260.023164 - Calls:1 - MeanTime:260.023164
   QueryID:100829061 - TotalTime:222.916521 - Calls:1 - MeanTime:222.916521
   QueryID:2369621365 - TotalTime:1320495.28835999 - Calls:182570 - MeanTime:7.23281639020644

 ```
