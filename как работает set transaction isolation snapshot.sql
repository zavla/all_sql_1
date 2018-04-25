-------------1 tran
begin transaction
update Person.Contact set Contact.FirstName = 'Jo4' where ContactID = 1068
go
waitfor delay '00:00:01'
go
commit tran


--------------2 tran

set transaction isolation level read committed;
go
begin transaction
go;

select EmployeeID, FirstName from HumanResources.Employee
inner join Person.Contact
on Employee.ContactID = Contact.ContactID
where Contact.FirstName = 'Jo';
go
waitfor delay '00:00:10';
go
select EmployeeID, FirstName from HumanResources.Employee
inner join Person.Contact
on Employee.ContactID = Contact.ContactID
where Contact.FirstName = 'Jo';
go
commit transaction
go
