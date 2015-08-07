declare @reindexQuery nvarchar(max)
declare @minRows integer
set @minRows = 1000

set @reindexQuery =
REPLACE(REPLACE(
cast(
(

select
'ALTER INDEX '+idx.name+' ON '+ sc.name+'.'+ t.name+
CASE
WHEN st.avg_fragmentation_in_percent > 30 THEN ' REBUILD WITH (ONLINE=ON)'
ELSE ' REORGANIZE'
END as query

from sys.dm_db_index_physical_stats( DB_ID(),NULL,NULL,NULL,NULL) st
join sys.tables t on (st.object_id=t.object_id)
join sys.schemas sc on (sc.schema_id=t.schema_id)
join sys.indexes idx on (t.object_id=idx.object_id and st.index_id=idx.index_id)
join sys.partitions p on (p.index_id=idx.index_id and p.object_id=idx.object_id)
where p.rows > @minRows and st.avg_fragmentation_in_percent > 6
and t.name <> 'Config'
order by st.avg_fragmentation_in_percent desc
FOR XML PATH(''), TYPE
) as nvarchar(max))
,'</query>',';
'),'<query>','')

print @reindexQuery

exec (@reindexQuery)