declare bs cursor 
for select name from sys.databases where database_id  > 4 
declare @curbase as sysname
declare @stm as nvarchar(max)
open bs

fetch next from bs into @curbase
while @@fetch_status = 0 begin
	
	set @stm = '
		USE ['+@curbase+']
		GO
		CREATE USER [jobs_runner] FOR LOGIN [jobs_runner]
		GO
		grant BACKUP DATABASE TO [jobs_runner] AS [dbo]
		GO
		grant BACKUP LOG TO [jobs_runner] AS [dbo]
		GO'
	print  @stm
	fetch next from bs into @curbase
end

close bs
deallocate bs

