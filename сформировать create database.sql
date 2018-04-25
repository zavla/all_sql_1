--select name, suser_sname(dd.owner_sid) from sys.databases as dd
exec sys.sp_MSforeachDB 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') BEGIN
select ''USE [master]
GO
CREATE DATABASE [?] ON ''
use ?
select ''( FILENAME = N'''''' + physical_name + ''''''),'' from sys.database_files 
select ''FOR ATTACH''
select ''Go''

declare @sidd varbinary(60)
declare @uname nvarchar(50)
select @sidd = owner_sid from sys.databases where name = ''?''
select @uname = suser_sname(@sidd)
select ''if exists (select name from master.sys.databases sd where name = N''''?'''') EXEC [?].dbo.sp_changedbowner @loginame=N'''''' + @uname+'''''', @map=false''
select ''Go''
END'
--go

--exec sys.sp_MSforeachDB '

--IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') BEGIN
--USE ?
--declare @sidd varbinary(60)
--declare @uname nvarchar(50)
--select @sidd = owner_sid from sys.databases where name = ''?''
--select @uname = suser_sname(@sidd)
--select ''if exists (select name from master.sys.databases sd where name = N''''?'''') EXEC [?].dbo.sp_changedbowner @loginame=N'''''' + @uname+'''''', @map=false''
--END'

