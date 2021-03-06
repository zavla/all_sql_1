USE [master]
GO
/****** Object:  View [dbo].[s2sprocesses]    Script Date: 03/11/2015 10:12:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[s2sprocesses]
AS
SELECT     spid, kpid, blocked, waittype, waittime, lastwaittype, waitresource, dbid, uid, cpu, physical_io, memusage, login_time, last_batch, ecid, open_tran, 
                      status, sid, hostname, program_name, hostprocess, cmd, nt_domain, nt_username, net_address, net_library, loginame, context_info, sql_handle, 
                      stmt_start, stmt_end, request_id
FROM         sys.sysprocesses
WHERE  status <> 'background'
--   (cmd <> 'checkpoint')

GO
