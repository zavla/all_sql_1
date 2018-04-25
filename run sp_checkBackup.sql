--restore database tempoDb from disk = 'j:\b\ubcd_sklad_2010_2018-04-04T22-18-16-530-FULL' with  MOVE 'UBCD_sklad_2010_Data' TO 'd:\temp\tempo.df1', MOVE 'UBCD_sklad_2010_Log' TO 'd:\temp\tempo.df2'

create proc sp_GelLogicalFileNames @path nvarchar(300) as
begin
--procedure to get logical file names from backups
restore filelistonly from disk = @path
end

go

create proc sp_checkBackupS(@bb nvarchar(max)) as
begin
	--input is a string with a list of full file names splited by newlines
	if OBJECT_ID('#res') IS NOT NULL  drop table #res;
	create table #res(filename nvarchar(400),res int);

	declare @total int = 0;
	declare @curfile nvarchar(200) = '';
	declare cur cursor for select value from string_split(@bb,NCHAR(10));
	open cur;
	while 1=1 begin

		fetch next from cur into @curfile;
		if @@FETCH_STATUS != 0 break;

		set @curfile = REPLACE(@curfile,nchar(13),'');
		if @curfile = '' break;
		print @curfile + ' ==testing' ;
		declare @gres int = -2;
		if exists(select name from sys.databases where name = 'tempodb') drop database tempodb;
		exec master.dbo.sp_checkBackup @backupFile = @curfile, @res = @gres OUTPUT
		print @gres
		if @gres != 0 BEGIN 
			set @total = -1;
			print @curfile + ' ==BAD' ;
			insert #res(filename, res) values (@curfile, @gres);
			--break;
		end
		else 
		begin 
			print @curfile + ' ==OK' ;
			insert #res(filename, res) values (@curfile,0);
		end
		set @curfile = '';
	
	end
	close cur
	deallocate cur
	select filename, res from #res;
end

go

create proc sp_checkBackup (@backupFile nvarchar(200), @res int OUTPUT )

as
begin
--checks-restore current backup
select @res = -3;

create table #ff (LogicalName nvarchar(100)
,_1 nvarchar(100)
,_2 nvarchar(100)
,_3 nvarchar(100)
,_4 nvarchar(100)
,_5 nvarchar(100)
,_6 nvarchar(100)
,_7 nvarchar(100)
,_8 nvarchar(100)
,_9 nvarchar(100)
,_10 nvarchar(100)
,_11 nvarchar(100)
,_12 nvarchar(100)
,_13 nvarchar(100)
,_14 nvarchar(100)
,_15 nvarchar(100)
,_16 nvarchar(100)
,_17 nvarchar(100)
,_18 nvarchar(100)
,_19 nvarchar(100)
,_20 nvarchar(100)
,_21 nvarchar(100)
);


insert #ff (LogicalName
,_1
,_2
,_3
,_4
,_5
,_6
,_7
,_8
,_9
,_10
,_11
,_12
,_13
,_14
,_15
,_16
,_17
,_18
,_19
,_20
,_21
)  exec master.dbo.sp_GelLogicalFileNames @backupFile;

--select LogicalName from #ff;


declare @tempfold nvarchar(200) = N'd:\temp\tempo.df';
declare @tempoDB sysname = '';

declare	@NumOfFiles int = 0;
select	@NumOfFiles = count(*) from #ff; 

declare @i int = 1;
declare @movesql nvarchar(max) = '';
declare @restoresql nvarchar(max) = '';
declare @fname nvarchar(200) = '';

while @i <= @NumOfFiles begin
	exec sp_executesql N'select @fnameinner = LogicalName from (select  LogicalName , row_number() over (order by LogicalName ) as Linenumber from #ff) as line where Linenumber = @iinner'
				,N'@iinner int, @fnameinner nvarchar(200) OUTPUT'
				, @iinner = @i 
				, @fnameinner = @fname OUTPUT;
	set @movesql = @movesql +', MOVE ''' + @fname+''' TO '''+ @tempfold+cast(@i as nvarchar(2))+'''';
	set @i = @i + 1;
end
set @tempoDB = 'tempoDb';
set @restoresql = 'restore database '+@tempoDB+' from disk = '''+@backupFile+''' with '+SUBSTRING(@movesql,2, len(@movesql));

drop table #ff
--select @restoresql


BEGIN TRY  
	print @restoresql;
	exec sp_executesql @restoresql;
	if @@ERROR = 0 begin
		set @res = 0;
	end
	else
	begin
		set @res = -1;
	end
    -- RAISERROR with severity 11-19 will cause execution to   
    -- jump to the CATCH block.  
    --RAISERROR ('Error raised in TRY block.', -- Message text.  
    --           16, -- Severity.  
    --           1 -- State.  
    --           );  
END TRY  
BEGIN CATCH  
    DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  

    SELECT   
        @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE();  
	print @ErrorMessage
	print @ErrorSeverity
	print @ErrorState
    -- Use RAISERROR inside the CATCH block to return error  
    -- information about the original error that caused  
    -- execution to jump to the CATCH block.  
    --RAISERROR (@ErrorMessage, -- Message text.  
    --           @ErrorSeverity, -- Severity.  
    --           @ErrorState -- State.  
    --           );  
	set @res = -33;
END CATCH;

end
go

/*
checks whole dir
*/
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
select @names = @names + @dir+filename + char(13)+char(10) from #files where filename like '%-FULL%' 
--select @names;
execute master.dbo.sp_checkBackupS @names
end