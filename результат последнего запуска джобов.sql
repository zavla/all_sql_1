--exec msdb.dbo.sysmail_help_account_sp
--exec msdb.dbo.sysmail_help_profile_sp
--EXEC msdb.dbo.sp_send_dbmail  
--    @profile_name = 'zakhar',  
--    @recipients = 'z.malinovskiy@beer-co.com',  
--    @body = 'The stored procedure finished successfully.', 
--	@query = 'exec master.dbo.za_JobsLastResult',
--	@query_result_width = 3000,
--    @subject = 'jobs last results',
--	@attach_query_result_as_file = 1 ;  

alter procedure dbo.za_JobsLastResult
as begin
--declare @res nvarchar(max);
--set @res = (
SELECT cast(Job.name as nvarchar(40)), JobsLastResult.run_date,
		JobsLastResult.job_id,
		sql_message_id,
		sql_severity,
		JobsLastResult.message 
FROM msdb.dbo.sysjobhistory as JobsLastResult
INNER JOIN (select job_id,
				max(cast(run_date as varchar(8))+right('0'+convert(varchar(6),run_time),6)) as maxidate 
			from msdb.dbo.sysjobhistory
			where cast(run_date as varchar(8))  > dateadd(d,-8,getdate())
			group by job_id
			) as maxi
ON maxi.job_id = JobsLastResult.job_id and maxi.maxidate = (cast(JobsLastResult.run_date as varchar(8))+right('0'+convert(varchar(6),JobsLastResult.run_time),6))

INNER JOIN msdb.dbo.sysjobs as Job
ON Job.job_id = JobsLastResult.job_id

where cast(run_date as varchar(8))  > dateadd(d,-8,getdate()) 
and step_id = 1
order by sql_severity, Job.name
--for xml auto
--)
--set @text = @res;
end
