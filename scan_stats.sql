-- FUNCTION: dba.scan_stats()

-- DROP FUNCTION dba.scan_stats();

CREATE OR REPLACE FUNCTION dba.scan_stats(v_rowest integer, v_seqscan 	integer)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
    missing INTEGER;
my_query text;
adesso timestamp;
    my_list RECORD;
my_statements RECORD;
my_queryid RECORD;
BEGIN
set search_path='dba';
    -- 
FOR my_list IN (select schemaname,relname,idx_scan_ratio,idx_scan,seq_scan,row_estimate  FROM dba.idx_scan_ratiov2  where row_estimate > v_rowest and seq_scan> v_seqscan  order by v2  ) LOOP
RAISE NOTICE 'Schema.Table: %.%:idx_scan_ratio:% idx_scan:%seq_scan: % row_estimate:%', my_list.schemaname,my_list.relname , my_list.idx_scan_ratio , my_list.idx_scan ,my_list.seq_scan, my_list.row_estimate  ;
RAISE NOTICE 'Top 5 Query on %.% by TotalTime',my_list.schemaname,my_list.relname ;
FOR my_queryid IN (    SELECT                                                                                                                           
stat_statements_hist.queryid,                                                                                                                                                               
sum(stat_statements_hist.calls) AS calls,                                                                                                                                                   
sum(stat_statements_hist.total_time) AS tottime,                                                                                                                                            
sum(stat_statements_hist.total_time) / sum(stat_statements_hist.calls)::double precision AS meantime                                                                                                                                                                                                                
FROM stat_statements_hist                                                                                                                                                                 
WHERE stat_statements_hist.query like  '% '||my_list.schemaname||'.'||my_list.relname||'%'  
AND stat_statements_hist.now = (select max(now) from stat_statements_hist)
GROUP BY  stat_statements_hist.queryid                                                                                                   
ORDER BY tottime desc  limit 5
 ) LOOP 
  RAISE NOTICE ' QueryID:% - TotalTime:% - Calls:% - MeanTime:% ' , my_queryid.queryid , my_queryid.tottime, my_queryid.calls, my_queryid.meantime;
 select query into my_query from stat_statements_hist where queryid=my_queryid.queryid and now=(select max(now) from stat_statements_hist) limit 1;
 --RAISE NOTICE ' Query : %', my_query;
 select into adesso now() ;
 insert into dba.scan_stats_query_list (data_rilevazione , schemaname ,relname ,  queryid , totaltime  , calls , meantime  ,  query )
 values (adesso,my_list.schemaname,my_list.relname, my_queryid.queryid , my_queryid.tottime, my_queryid.calls, my_queryid.meantime, my_query);
END LOOP;
RAISE NOTICE 'Top 5 Query on %.% by MeanTime',my_list.schemaname,my_list.relname ;
 FOR my_queryid IN (    SELECT                                                                                                                           
stat_statements_hist.queryid,                                                                                                                                                               
sum(stat_statements_hist.calls) AS calls,                                                                                                                                                   
sum(stat_statements_hist.total_time) AS tottime,                                                                                                                                            
sum(stat_statements_hist.total_time) / sum(stat_statements_hist.calls)::double precision AS meantime                                                                                                                                                                                                                
FROM stat_statements_hist                                                                                                                                                                 
WHERE stat_statements_hist.query like  '% '||my_list.schemaname||'.'||my_list.relname||'%'  
AND stat_statements_hist.now = (select max(now) from stat_statements_hist)
GROUP BY  stat_statements_hist.queryid                                                                                                   
ORDER BY meantime desc  limit 5
 ) LOOP 
  RAISE NOTICE ' QueryID:% - TotalTime:% - Calls:% - MeanTime:% ' , my_queryid.queryid , my_queryid.tottime, my_queryid.calls, my_queryid.meantime;
select query into my_query from stat_statements_hist where queryid=my_queryid.queryid and now=(select max(now) from stat_statements_hist) limit 1;
--RAISE NOTICE ' Query : %', my_query;
select into adesso now() ;
insert into dba.scan_stats_query_list (data_rilevazione , schemaname ,relname ,  queryid , totaltime  , calls , meantime  ,  query )
 values (adesso,my_list.schemaname,my_list.relname, my_queryid.queryid , my_queryid.tottime, my_queryid.calls, my_queryid.meantime, my_query);
END LOOP;
END LOOP;
END;
$BODY$;

ALTER FUNCTION dba.scan_stats()
    OWNER TO postgres;
