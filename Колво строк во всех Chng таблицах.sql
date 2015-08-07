declare @tn varchar(100)
declare cur1 cursor for select name from sys.objects where type = 'U' --and name like '%Chng%'
declare @t1 as table (c int,n varchar(100))
open cur1

fetch next from cur1 into @tn 
while @@fetch_status <> -1
begin
	insert into @t1(c,n) exec ('select count(*), '''+@tn+ ''' from '+@tn)
	fetch next from cur1 into @tn
end
select * from @t1 where c > 0 order by c desc
close cur1
deallocate cur1