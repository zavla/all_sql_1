SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

----------------------------------------------------------------------------------------------------
-- OBJECT NAME	        : isp_DBCC_DBREINDEX
--
-- AUTHOR               : Tara Duggan
-- DATE					: May 11, 2004
--
-- INPUTS				: @dbName - name of the database
-- OUTPUTS				: None
-- DEPENDENCIES	        : None
--
-- DESCRIPTION	        : This stored procedure runs DBCC DBREINDEX for each of the indexes in the database.
--
-- EXAMPLES (optional)  : EXEC isp_DBCC_DBREINDEX @dbName = 'GT'
--
-- MODIFICATION HISTORY :
----------------------------------------------------------------------------------------------------
-- 12/22/2004 - Tara Duggan
-- If table has a clustered index, just rebuild that index; otherwise rebuild all.
--
-- 12/30/2004 - Tara Duggan
-- If table has a non-unique clustered index, just rebuild that index; otherwise rebuild all.
----------------------------------------------------------------------------------------------------
CREATE            PROC isp_DBCC_DBREINDEX
(@dbName SYSNAME)
AS
SET NOCOUNT ON

DECLARE @objName SYSNAME
DECLARE @idxName SYSNAME
DECLARE @SQL NVARCHAR(4000)
DECLARE @ID INT
DECLARE @RowCnt INT

CREATE TABLE ##Indexes
(
	Indexes_ID INT IDENTITY(1, 1) NOT NULL, 
	IndexName SYSNAME NOT NULL, 
	ObjectName SYSNAME NOT NULL
)

-- non-unique clustered indexes
SET @SQL = ''
SET @SQL = @SQL + 'INSERT INTO ##Indexes (IndexName, ObjectName) '
SET @SQL = @SQL + 'SELECT i.[name], o1.[name] '
SET @SQL = @SQL + 'FROM ' + @dbName + '.dbo.sysindexes i ' 
SET @SQL = @SQL + 'INNER JOIN ' + @dbName + '.dbo.sysobjects o1 '
SET @SQL = @SQL + 'ON i.[id] = o1.[id] '
SET @SQL = @SQL + 'INNER JOIN ' + @dbName + '.dbo.sysobjects o2 '
SET @SQL = @SQL + 'ON i.[name] = o2.[name] '
SET @SQL = @SQL + 'WHERE i.indid = 1 AND '
SET @SQL = @SQL + 'o1.type = ''U'' AND '
SET @SQL = @SQL + 'OBJECTPROPERTY(o2.[id], ''IsUniqueCnst'') = 0 '

EXEC sp_executesql @statement = @SQL

-- nonclustered indexes but only tables that do not have non-unique clustered indexes; unique clustered indexes
SET @SQL = ''
SET @SQL = @SQL + 'INSERT INTO ##Indexes (IndexName, ObjectName) '
SET @SQL = @SQL + 'SELECT i.[name], o.[name] '
SET @SQL = @SQL + 'FROM ' + @dbName + '.dbo.sysindexes i ' 
SET @SQL = @SQL + 'INNER JOIN ' + @dbName + '.dbo.sysobjects o '
SET @SQL = @SQL + 'ON i.[id] = o.[id] '
SET @SQL = @SQL + 'WHERE i.indid > 1 AND i.indid < 255 AND '
SET @SQL = @SQL + 'o.type = ''U'' AND '
SET @SQL = @SQL + '(i.status & (64 | 8388608)) <= 0 AND '
SET @SQL = @SQL + 'o.[name] NOT IN (SELECT ObjectName FROM ##Indexes)'

EXEC sp_executesql @statement = @SQL

SELECT TOP 1 @ID = Indexes_ID, @idxName = IndexName, @objName = ObjectName
FROM ##Indexes
ORDER BY Indexes_ID

SET @RowCnt = @@ROWCOUNT

WHILE @RowCnt <> 0
BEGIN

	SET @SQL = 'DBCC DBREINDEX(''' + @dbName + '.dbo.' + @objName + ''', ' + @idxName + ', 0) WITH NO_INFOMSGS'

	EXEC sp_executesql @statement = @SQL

	SELECT TOP 1 @ID = Indexes_ID, @idxName = IndexName, @objName = ObjectName
	FROM ##Indexes
	WHERE Indexes_ID > @ID
	ORDER BY Indexes_ID
	
	SET @RowCnt = @@ROWCOUNT

END

DROP TABLE ##Indexes

RETURN 0


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO