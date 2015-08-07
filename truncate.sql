declare @name sysname
declare @exstr nvarchar(500)
declare @pardef nvarchar(100)
set @pardef = N'@name sysname'
declare cur cursor for 
select name from sysobjects where name like 'DT%' or name like 'DH%'
--
open cur
fetch next from cur into @name
while @@fetch_status = 0
begin
	print @name
	
	select @exstr = N'truncate table '+@name
	execute sp_executesql @exstr
	fetch next from cur into @name;
end
close cur
deallocate cur