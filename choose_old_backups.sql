create procedure choose_old_backups as begin
declare @t table (subdirectory nvarchar(200),depth int, isfile int);
--получить список файлов
insert into @t exec master.sys.xp_dirtree N'h:\za\',1,1;
if not object_id('tempdb..#prom1') is null drop table #prom1;
--подобрать к файлу имя базы, возможно не одно
select  distinct files.subdirectory, bases.name, bases.lenname 
	into #prom1
	from @t as files
	left JOIN (select name, len(name) as lenname from master.sys.databases) as lenOfnames
	on 1=1
	left JOIN (select name, len(name) as lenname from master.sys.databases) as bases
	on substring(files.subdirectory,1, lenOfnames.lenname) = bases.name
where isfile = 1
and  not bases.name is null;

if not OBJECT_id('tempdb..#files_') is null drop table #files_;

--если к файлу подходит две базы по имени ты выбрать ту название которой длиннее
select p1.subdirectory, p1.name, p1.lenname, p2.maxlen, 
	convert(datetime, 
		substring(p1.subdirectory,p1.lenname+2,10)+'T'+replace(SUBSTRING(p1.subdirectory,p1.lenname+13,8),'-',':')
		, 127) as date1
	into #files_
	from #prom1 as p1 
	inner join (
		select subdirectory, max(lenname) as maxlen 
		from #prom1 
		group by subdirectory) as p2 
	on p1.subdirectory = p2.subdirectory and  p1.lenname = p2.maxlen 

--выдает те файлы у которых есть хотябы 1 full
--до вызова процедуры надо сделать create table #files(subdirectory nvarchar(200), name nvarchar(100), date1 datetime, maxdate datetime);
insert #files select fa.subdirectory, fa.name, fa.date1, maxi.maxdate 
from #files_ as fa
inner join (
	select f.name, max(f.date1) as maxdate
	from #files_ as f
	where f.subdirectory like '%FULL%'
	group by f.name) as maxi
	on maxi.name = fa.name and fa.date1 < dateadd(dd,-2,maxi.maxdate)
---выдает те файлы у которых нет full
union all
select fa.subdirectory, fa.name, fa.date1, maxi.maxdate 
from #files_ as fa
inner join (
	select f.name, max(f.date1) as maxdate
	from #files_ as f
	group by f.name) as maxi
	on maxi.name = fa.name and fa.date1 < dateadd(dd,-2,maxi.maxdate)
where not (fa.name) in (select distinct f1.name from #files_ as f1 where f1.subdirectory like '%FULL%')
end
go
create procedure delete_choosed_old_backups as begin
if not OBJECT_id('tempdb..#files') is null drop table #files;
create table #files(subdirectory nvarchar(200), name nvarchar(100), date1 datetime, maxdate datetime);
exec master..choose_old_backups;
declare c cursor for select subdirectory from #files
	--where subdirectory like '%Armat%'; --debug
open c
declare @curfile nvarchar(200) = '';
declare @sql nvarchar(max) = '';
fetch next from c into @curfile
while @@FETCH_STATUS = 0 begin
	
	set @sql = 'exec master.sys.xp_delete_file 0,N''h:\za\'+@curfile+'''';
	--print @sql
	exec sp_executesql @sql;
	fetch next from c into @curfile

end
close c
deallocate c
end
go