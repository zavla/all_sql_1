select object_name(s.object_id) as table_name ,name, database_id, s.object_id, s.index_id, user_seeks, user_scans, user_lookups, user_updates  from sys.dm_db_index_usage_stats s
inner join sys.indexes i on s.object_id = i.object_id and s.index_id = i.index_id
where user_seeks = 0 and user_scans = 0 and user_lookups = 0
order by user_updates desc