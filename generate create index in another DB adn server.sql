
CREATE PROCEDURE sp_util_GenerateIndexesScript(@FrmStr varchar(316), @ToStr varchar(316) = NULL, @Exe BIT = NULL,

    @IncludeFileGroup	bit = 1,
    @IncludeDrop	bit = 1,
    @IncludeFillFactor	bit = 0,
    @IncludeCheck	bit = 1,
    @IncludeTryCatch	bit = 0
)
AS
/*
This Sp will allow you to script the indices from a table for recreation

@FromTbl	= Can be a fully qualified extended name as you can run into a different DB on a differing server
@ToTbl	= Can be left blank or you can pass a partially or fully qualified name 
@Exe		= Can be left blank or marked as 1. This will mean that the script executes rather than just outputs a script

Examples:
EXEC sp_util_GenerateIndexesScript 'Db1.dbo.TblData_Emails', 'LinkedServ1.Db2.dbo.TblData_Emails' - This will create the index from the first local table on the remote server

*/
DECLARE 
@CurTbl		varchar(max),
@RunSql		varchar(max),
@ICSql		nvarchar(max),
@UseServ	        varchar(200),
@UseServCls       varchar(2),
@FrmServ	        varchar(30),
@FrmDb		varchar(128),
@FrmSch		varchar(30),
@FrmTbl		varchar(128),
@ToServ		varchar(30),
@ToDb		varchar(128),
@ToSch		varchar(30),
@ToTbl		varchar(128)
/*	
--Test settings
	,@FrmStr		varchar(316),
	@ToStr		varchar(316),
	@Exe			bit = 1,
    @IncludeFileGroup	bit = 1,
    @IncludeDrop		bit = 1,
    @IncludeFillFactor	bit = 0,
    @IncludeCheck	bit = 1,
    @IncludeTryCatch	bit = 0
Set @FrmStr = 'DB1.dbo.TblData_Emails'
Set @ToStr = --'Server01.DB2.dbo.TblData_Emails'
'DB3.dbo.TblData_Emails'
*/
	
Set @FrmServ	= CASE WHEN PARSENAME(@FrmStr,4)IS NULL THEN ''		ELSE PARSENAME(@FrmStr,4)+'.' END
Set @FrmDB	= CASE WHEN PARSENAME(@FrmStr,3)IS NULL THEN ''		ELSE PARSENAME(@FrmStr,3)+'.' END
Set @FrmSch	= CASE WHEN PARSENAME(@FrmStr,2)IS NULL THEN ''		ELSE PARSENAME(@FrmStr,2)+'.' END
Set @FrmTbl	= PARSENAME(@FrmStr,1)

Set @ToServ	= CASE WHEN PARSENAME(@ToStr,4)IS NULL THEN @FrmServ	ELSE PARSENAME(@ToStr,4)+'.' END
Set @ToDB		= CASE WHEN PARSENAME(@ToStr,3)IS NULL THEN @FrmDb		ELSE PARSENAME(@ToStr,3)+'.' END
Set @ToSch	= CASE WHEN PARSENAME(@ToStr,2)IS NULL THEN @FrmSch		ELSE PARSENAME(@ToStr,2)+'.' END
Set @ToTbl		= CASE WHEN PARSENAME(@ToStr,1)IS NULL THEN @FrmTbl		ELSE PARSENAME(@ToStr,1)	 END

Set @Exe		= CASE WHEN @Exe <> 1					THEN 0 ELSE 1 END
Set @RunSql	= ''
Set @UseServ	= 'EXECUTE ' +  @ToServ + REPLACE(@ToDb, '.','')+'.[dbo].[sp_executesql] N'''

BEGIN
-- Get all existing indexes, but NOT the primary keys
 Set @CurTbl = 
				' 
				  DECLARE Indexes_cursor cursor
					FOR
						SELECT  SC.Name          AS SchemaName,
								SO.Name          AS TableName,
								SI.OBJECT_ID     AS TableId,
								SI.[Name]        AS IndexName,
								SI.Index_ID      AS IndexId,
								FG.[Name]        AS FileGroupName,
								CASE WHEN SI.Fill_Factor = 0 THEN 100 ELSE SI.Fill_Factor END as Fill_Factor
								FROM '		+ @FrmServ + @FrmDb + 'sys.indexes AS SI
								LEFT JOIN ' + @FrmServ + @FrmDb + 'sys.filegroups AS FG
						ON SI.data_space_id = FG.data_space_id
						INNER JOIN ' + @FrmServ + @FrmDb + 'sys.objects	AS SO
						ON SI.OBJECT_ID = SO.OBJECT_ID
						INNER JOIN ' + @FrmServ + @FrmDb + 'sys.schemas	AS SC
						ON SC.schema_id = SO.schema_id
						WHERE SO.Type = ''U''
						  AND SI.[Name] IS NOT NULL
						  AND SI.is_primary_key = 0
						  AND SI.is_unique_constraint = 0
						  AND SI.is_disabled = 0
						  --AND INDEXPROPERTY(SI.OBJECT_ID, SI.[Name], ''IsStatistics'') = 0
						  AND SO.Name =''' + @FrmTbl + '''
						  ORDER BY OBJECT_NAME(SI.OBJECT_ID), SI.Index_ID
				'
Exec  (@CurTbl)

    DECLARE @SchemaName     sysname
    DECLARE @TableName      sysname
    DECLARE @TableId        int
    DECLARE @IndexName      sysname
    DECLARE @FileGroupName  sysname
    DECLARE @IndexId        int
    DECLARE @FillFactor     int
    DECLARE @NewLine		nvarchar(4000)
    DECLARE @Tab			nvarchar(4000)
    
    SET @NewLine = char(13) + char(10)
    SET @Tab = SPACE(4)

-- Loop through all indexes
    OPEN Indexes_cursor

    FETCH NEXT
     FROM Indexes_cursor
     INTO @SchemaName, @TableName, @TableId, @IndexName, @IndexId, @FileGroupName, @FillFactor

    WHILE (@@FETCH_STATUS = 0)
        BEGIN

            DECLARE @sIndexDesc nvarchar(4000)
            DECLARE @sCreateSql nvarchar(4000)
            DECLARE @sDropSql   nvarchar(4000)

            SET @sIndexDesc = '-- Create Index ' + @IndexName + ' on table ' + @ToServ + @ToDb + '[' + @SchemaName + '].[' + @TableName + ']'
            SET @sDropSql = 
							'IF EXISTS(SELECT 1'	+ @NewLine
                          + '          FROM '		+ @ToDb + '.sysindexes si' + @NewLine
                          + '          INNER JOIN ' + @ToDb + '.sysobjects so' + @NewLine
                          + '          ON so.id = si.id' + @NewLine
                          + '          WHERE si.[Name] = N''' + @IndexName + '''   -- Index Name' + @NewLine
                          + '            AND so.[Name] = N''' + @TableName + ''')  -- Table Name' + @NewLine
                          + 'BEGIN' + @NewLine
                          + '    DROP INDEX [' + @IndexName + '] ON ' + @ToDb + '[' + @SchemaName + '].[' + @TableName + ']' + @NewLine
                          + 'END' 
			
			SET @RunSql		= ''
            SET @sCreateSql = 'CREATE '

-- Check if the index is unique
            IF (IndexProperty(@TableId, @IndexName, 'IsUnique') = 1)
                BEGIN
                    SET @sCreateSql = @sCreateSql + 'UNIQUE '
                END
                
            -- Check if the index is clustered
            IF (IndexProperty(@TableId, @IndexName, 'IsClustered') = 1)
                BEGIN
                    SET @sCreateSql = @sCreateSql + 'CLUSTERED '
                END

            SET @sCreateSql = @sCreateSql + 'INDEX [' + @IndexName + '] ON ' + @ToDB + '[' + @SchemaName + '].[' + @TableName + ']' + @NewLine + '(' + @NewLine

-- Get all columns of the index
 Set @ICSql = 
 '
            DECLARE IndexColumns_cursor CURSOR
                FOR SELECT SC.[Name],
                           IC.[is_included_column],
                           IC.is_descending_key
                      FROM '	 + @FrmServ + @FrmDb + 'sys.index_columns as IC
                     INNER JOIN '+ @FrmServ + @FrmDb + 'sys.columns as SC
                             ON IC.OBJECT_ID = SC.OBJECT_ID
                            AND IC.Column_ID = SC.Column_ID
                     WHERE IC.OBJECT_ID = @TId
                       AND Index_ID = @IId
                     ORDER BY IC.[is_included_column],
                              IC.key_ordinal
'
Exec Sp_ExecuteSQL @ICSql, N'@TId as integer, @IId as integer', @TId = @TableId, @IId = @IndexId

            DECLARE @IxColumn		sysname
            DECLARE @IxIncl			bit
            DECLARE @Desc			bit
            DECLARE @IxIsIncl		bit
            DECLARE @IxFirstColumn  bit
            
            SET @IxIsIncl = 0
            SET @IxFirstColumn = 1

-- Loop through all columns of the index and append them to the CREATE statement
            OPEN IndexColumns_cursor
            FETCH NEXT
             FROM IndexColumns_cursor
             INTO @IxColumn, @IxIncl, @Desc

            WHILE (@@FETCH_STATUS = 0)
                BEGIN
                    IF (@IxFirstColumn = 1)
                        BEGIN
                            SET @IxFirstColumn = 0
                        END
                    ELSE
                        BEGIN
--check to see if it's an included column
                            IF (@IxIsIncl = 0) AND (@IxIncl = 1)
                                BEGIN
                                    SET @IxIsIncl = 1
                                    SET @sCreateSql = @sCreateSql + @NewLine + ')' + @NewLine + 'INCLUDE' + @NewLine + '(' + @NewLine
                                END
                            ELSE
                                BEGIN
                                    SET @sCreateSql = @sCreateSql + ',' + @NewLine
                                END

                        END

                    SET @sCreateSql = @sCreateSql + @Tab + '[' + @IxColumn + ']'
-- check if ASC or DESC
                    IF @IxIsIncl = 0
                        BEGIN
                            IF @Desc = 1
                                BEGIN
                                    SET @sCreateSql = @sCreateSql + ' DESC'
                                END
                            ELSE
                                BEGIN
                                    SET @sCreateSql = @sCreateSql + ' ASC'
                                END
                        END

                    FETCH NEXT
                     FROM IndexColumns_cursor
                     INTO @IxColumn, @IxIncl, @Desc
                END

            CLOSE IndexColumns_cursor
            DEALLOCATE IndexColumns_cursor

            SET @sCreateSql = @sCreateSql + @NewLine + ') '

            IF @IncludeFillFactor = 1
                BEGIN
                    SET @sCreateSql = @sCreateSql + @NewLine + 'WITH (FillFactor = ' + CAST(@FillFactor AS varchar(13)) + ')' + @NewLine
                END
            --END IF

            IF @IncludeFileGroup = 1
                BEGIN
                    SET @sCreateSql = @sCreateSql + 'ON ['+ @FileGroupName + ']' + @NewLine
                END
            ELSE
                BEGIN
                    SET @sCreateSql = @sCreateSql + @NewLine
                END
            --END IF

            PRINT '-- **********************************************************************'
            PRINT @sIndexDesc
            PRINT '-- **********************************************************************'

            IF @IncludeDrop <> 1
              	BEGIN
					Set     @sDropSql = ''
				END

			If @IncludeDrop=0 and @IncludeCheck=1
				Begin
					Set @RunSQL = 'IF NOT EXISTS(SELECT * FROM ' + @FrmServ + @FrmDb + 'sys.indexes WHERE name = ''' +@IndexName+''' AND object_id = OBJECT_ID('''+@TableName+'''))'
								  + @NewLine +
								  'Begin'
				End
			if @IncludeTryCatch=1
				Begin
					Set @RunSQL = @RunSQL  + @NewLine + 
						'Begin Try'
				end
--Main Statement
Set @RunSQL = @RunSQL  + @NewLine + @sCreateSql

			if @IncludeTryCatch=1
			Begin
					Set	@RunSQL = @RunSQL	+ @NewLine + 
							'End Try'		+ @NewLine +
							'Begin Catch'	+ @NewLine +
							'	RAISERROR (''The Index ' + @IndexName + ' on Table ' + @ToServ + @ToDb + @ToSch +@TableName+' could not be created'', 11,1)' + @NewLine +
							'End Catch'
			End
			If @IncludeDrop=0 and @IncludeCheck=1
				Begin
					Set	@RunSQL = @RunSQL  
								+ @NewLine +
								  'End'
				End

-- Update the strings if they are to go to another server
IF @ToServ <> @FrmServ  
Begin
	Set  @sDropSql = @UseServ + REPLACE(@sDropSql, '''','''''') + '''' + @NewLine
	Set  @RunSQL   = @UseServ + REPLACE(@RunSQL, '''','''''')   + '''' + @NewLine
End  
        
--Print the statements
PRINT @sDropSql
PRINT @RunSQL

--See if you want to Execute the scripts
IF @Exe = 1 
Begin
	Exec (@sDropSql)
	Exec (@RunSql)
end

--Move to the next record
		FETCH NEXT
             FROM Indexes_cursor
             INTO @SchemaName, @TableName, @TableId, @IndexName, @IndexId, @FileGroupName, @FillFactor
        END
        
--At the end Clean up
    CLOSE Indexes_cursor
    DEALLOCATE Indexes_cursor

END
GO
