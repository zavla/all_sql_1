sp_msforeachdb 'if not(CHARINDEX(''?'',''tempdb,master,msdb,model'')>0) 
begin 
print ''?'';
use ?; 
backup log ? with truncate_only; 
declare @logname nvarchar(300);
declare @Params nvarchar(300);
set @params = ''@lognameOUT nvarchar(100) OUTPUT'';
execute sp_executesql N''select @lognameOUT = name from sysfiles where groupid = 0''
		, @Params, @lognameOUT = @logname OUTPUT;
set @logname = rtrim(@logname);
DBCC SHRINKFILE (@logname , 0, TRUNCATEONLY);

end'
