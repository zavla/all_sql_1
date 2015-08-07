

--select * from dbo.params where filename = 'users.usr'
select * from v8users
0xBEA930C958E6A45E4898604EFE88D006
'fe88d006-604e-4898-bea9-30c958e6a45e.pfl$'
--writetext in pubs
--USE pubs;
--GO
--ALTER DATABASE pubs SET RECOVERY SIMPLE;
--GO
--DECLARE @ptrval binary(16)
--SELECT @ptrval = TEXTPTR(pr_info) 
--FROM pub_info pr, publishers p
--WHERE p.pub_id = pr.pub_id 
--   AND p.pub_name = 'New Moon Books'
--WRITETEXT pub_info.pr_info @ptrval 'New Moon Books (NMB) has just released another top ten publication. With the latest publication this makes NMB the hottest new publisher of the year!'
--GO
--ALTER DATABASE pubs SET RECOVERY SIMPLE;
--GO
