# dba.stat
a set of views and foreign tables to collect statistics from a running PostgreSQL server

The statistics collected from a postgres production database are transferred to external tables on a staging database so as not to weigh down the production db.

From here they can be  decanted on greenplum or other BI databases to have the possibility of use analytics on the data.

