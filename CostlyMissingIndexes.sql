select ROUND((avg_total_user_cost * avg_user_impact)*user_seeks, 0) as total, * from sys.dm_db_missing_index_groups g
inner join sys.dm_db_missing_index_group_stats s
on s.group_handle = g.index_group_handle
inner join sys.dm_db_missing_index_details d
on d.index_handle = g.index_handle
--select * from sys.dm_db_missing_index_groups order by index_group_handle
--select * from sys.dm_db_missing_index_details
order by total desc