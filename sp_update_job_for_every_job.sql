declare js cursor for 
select job_id from msdb.dbo.sysjobs where name <> 'syspolicy_purge_history'

declare @jid nvarchar(max)
declare @stm nvarchar(max)
open js
fetch next from js into @jid
while @@fetch_status = 0 begin
	set @stm = '
	USE [msdb]
	GO
	EXEC msdb.dbo.sp_update_job @job_id=N'''+@jid+''', 
		@owner_login_name=N''jobs_runner''
	GO'
	print @stm
	fetch next from js into @jid
end
close js
deallocate js


--select * from msdb.dbo.sysjobs