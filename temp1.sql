create procedure za_check_dir_with_backups  (@dir nvarchar(100)) as
begin
if object_id('tempdb..#dirs') is not  null drop table #dirs;
if object_id('tempdb..#files') is not null drop table #files;
--GO;
--declare @dir nvarchar(100) = N'j:\b\';

create table #dirs (subdirectory nvarchar(100), depth int);
insert into #dirs(subdirectory, depth) execute master.dbo.xp_dirtree @dir,1;

create table #files (filename nvarchar(200), depth int, _3 int);
insert into #files (filename, depth, _3) execute master.dbo.xp_dirtree @dir,1,1 

delete #files from #dirs as d where #files.filename in (select subdirectory from #dirs);

declare @names nvarchar(max) = N'';
select @names = @names + @dir+filename + char(13)+char(10) from #files where filename like 'Ar%-FULL%' 
--select @names;
execute master.dbo.sp_checkBackupS @names
end