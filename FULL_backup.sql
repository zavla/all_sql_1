USE [msdb]
GO
/****** Object:  Job [×ÀÎ_ÏÐÎÌÎ_FULL]    Script Date: 12/15/2016 10:46:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 12/15/2016 10:46:42 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'×ÀÎ_ÏÐÎÌÎ_FULL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'UBC\z.malinovskiy', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [_1]    Script Date: 12/15/2016 10:46:42 ******/
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
		@command=N'declare @ibdir varchar(100)
set @ibdir = ''E:\Base\Îôèñ\×ÀÎ_Ïðîìî\''
declare @basename sysname
set @basename = ''×ÀÎ_ÏÐÎÌÎ''
declare @dir_to varchar(20)
set @dir_to = ''e:\za\''
declare @copy_to varchar(100)
set @copy_to = ''\\sbyt-1c\b\backups\''
declare @filename varchar(100)
set @filename =  replace(replace( @basename +''_''+ convert(varchar, getdate(), 120  ),'':'',''-''),'' '',''_'')+ ''-FULL''
declare @shortfilename varchar(100)
set @shortfilename = @filename
set @filename = @dir_to + @filename 

print @filename
BACKUP DATABASE @basename TO  DISK = @filename
--WITH  DIFFERENTIAL
if  @@error = 0 begin
	declare @command varchar(400)
	set @command = ''"c:\Program Files\Winrar\winrar.exe" m -iloge:\za\log.txt ''+@filename+''.rar ''+@filename
	exec master..xp_cmdshell @command
	if  @@error = 0 begin
		set @command = ''"c:\Program Files\Winrar\winrar.exe" a -iloge:\za\log.txt -dh -r -iloge:\za\log.txt -x@''+@ibdir+''Except.txt ''+@filename+''.MD ''+@ibdir
		print @command
		exec master..xp_cmdshell @command

 
		set @command = ''copy ''+@filename+''.* ''+@copy_to+''''
		print @command
		exec master..xp_cmdshell @command
	end
end
--WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N''UBCD_Sklad_2010-Differential Database Backup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
', 
		@database_name=N'msdb', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'in_the_morning', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110421, 
		@active_end_date=99991231, 
		@active_start_time=173700, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
