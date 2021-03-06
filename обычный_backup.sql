/*
declare @basename sysname
set @basename = 'ubcd_sklad_2010'
declare @dir_to varchar(20)
set @dir_to = 'h:\za\'
declare @copy_to varchar(100)
set @copy_to = '\\logistika-1c\b\'
declare @filename varchar(100)
set @filename =  replace(replace( @basename +'_'+ convert(varchar, getdate(), 127  ),':','-'),'.','-') + '-differ'
declare @shortfilename varchar(100)
set @shortfilename = @filename
set @filename = @dir_to + @filename

print @filename
BACKUP DATABASE @basename TO  DISK = @filename with differential
if  @@error = 0 begin
	declare @command varchar(200)
	set @command = '"c:\Program Files\Winrar\winrar.exe" m -m1 '+@filename+'.rar '+@filename+' '
	exec msdb..xp_cmdshell @command
	if  @@error = 0 begin
		set @command = 'copy '+@filename+'.rar '+@copy_to+@shortfilename+'.rar '
		print @command
		exec msdb..xp_cmdshell @command
	end
else
 	begin
		raiserror('BACKUP failed',17,1)
	end
end
--WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'UBCD_Sklad_2010-Differential Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

*/
USE [msdb]
GO
/****** Object:  Job [ubcd_sklad_2010-diff]    Script Date: 08/07/2015 15:36:30 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 08/07/2015 15:36:30 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ubcd_sklad_2010-diff', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'UBC\z.malinovskiy', 
		@notify_email_operator_name=N'Za', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [_1]    Script Date: 08/07/2015 15:36:30 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'_1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @basename sysname
set @basename = ''ubcd_sklad_2010''
declare @dir_to varchar(20)
set @dir_to = ''h:\za\''
declare @copy_to varchar(100)
set @copy_to = ''\\logistika-1c\b\''
declare @filename varchar(100)
set @filename =  replace(replace( @basename +''_''+ convert(varchar, getdate(), 127  ),'':'',''-''),''.'',''-'') + ''-differ''
declare @shortfilename varchar(100)
set @shortfilename = @filename
set @filename = @dir_to + @filename

print @filename
BACKUP DATABASE @basename TO  DISK = @filename with differential
if  @@error = 0 begin
	declare @command varchar(200)
	set @command = ''"c:\Program Files\Winrar\winrar.exe" m -m1 ''+@filename+''.rar ''+@filename+'' ''
	exec msdb..xp_cmdshell @command
	if  @@error = 0 begin
		set @command = ''copy ''+@filename+''.rar ''+@copy_to+@shortfilename+''.rar ''
		print @command
		exec msdb..xp_cmdshell @command
	end
else
 	begin
		raiserror(''BACKUP failed'',17,1)
	end
end
--WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N''UBCD_Sklad_2010-Differential Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'every2h', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=3, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110421, 
		@active_end_date=99991231, 
		@active_start_time=84000, 
		@active_end_time=185059
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
