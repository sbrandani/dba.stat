# dba.stat
a set of views and foreign tables to collect statistics from a running PostgreSQL server

The statistics collected from a postgres production database are transferred to external tables on a staging database so as not to weigh down the production db.

From here they can be  decanted on greenplum or other BI databases to have the possibility of use analytics on the data.

#
## Installation and Usage
#


#
# Requirements
#

Following adjustments must be set on the postgres configuration file

#
QUERY ANALISYS
#
shared_preload_libraries = 'pg_stat_statements'

pg_stat_statements.max = 10000

pg_stat_statements.track = all


#
# How to Install
#
proddb=# CREATE EXTENSION postgres_fdw;
CREATE EXTENSION

proddb=# CREATE SERVER pgstatsrv FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'pgstage01ng', dbname 'statdb', port '5432');
CREATE SERVER

proddb=#create role statusr login inherit superuser password 'statpwd';
CREATE ROLE

proddb=# CREATE USER MAPPING FOR statusr SERVER pgstatsrv OPTIONS (user 'statusr', password 'statpwd');
CREATE USER MAPPING


#
# Example of Use
#

