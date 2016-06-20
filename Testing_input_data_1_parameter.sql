/*

** Author: Tomaz Kastrun
** Created: 17.06.2016; Ljubljana
** Testing @input_data parameter for sp_execute_external_script 
** R and T-SQL

*/

use sandbox;
go


-- deriving from simple procedure
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet'
	  ,@input_data_1 = N'SELECT 1 as cifra'
WITH RESULT SETS (( cifra VARCHAR(10)));


-- UNION - works
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet'
	  ,@input_data_1 = N'SELECT 1 as cifra UNION SELECT 5 as cifra'
WITH RESULT SETS (( cifra VARCHAR(10)));



-- add one more column to SELECT list! 
-- If I specify result sets as undefinded, it works
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet'
	  ,@input_data_1 = N'SELECT 1 as num1, 2 AS num2'
WITH RESULT SETS UNDEFINED; --without writing this statement is same as running the whole execute sp.... statement without "with result..." statement



-- add one more column to SELECT list! 
-- If I specify result sets as data type VARCHAR - it works
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet'
	  ,@input_data_1 = N'SELECT 1 as num1, 2 AS num2'
WITH RESULT SETS (
					 (num1 VARCHAR(10)
					,num2 VARCHAR(10))
					);

-- store this into table
-- and rerun select statement
CREATE TABLE nums (num1 varchar(10), num2 varchar(10))
INSERT INTO nums
select 1,2

EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet'
	  ,@input_data_1 = N'SELECT * FROM nums'
	 --,@input_data_1_name = N'nums'
WITH RESULT SETS (
					 (num1 VARCHAR(10)
					,num2 VARCHAR(10))
					);


-- change R script
-- by defining input name
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet <- nums'
	  ,@input_data_1 = N'SELECT * FROM nums'
	  ,@input_data_1_name = N'nums'
WITH RESULT SETS (
					 (num1 VARCHAR(10)
					,num2 VARCHAR(10))
					);


--works fine!
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet'
	  ,@input_data_1 = N'SELECT
								 name
								,number
								,[type]
							FROM master..spt_values
							WHERE
								[type] = ''EOD'''
WITH RESULT SETS (
					 (name VARCHAR(50)
					,number INT
					,[type] CHAR(3))
					);



-- with input name and script changed
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'mydata <- spt_values
				OutputDataSet<-mydata'
	  ,@input_data_1 = N'SELECT name ,number ,[type] FROM master..spt_values WHERE [type] = ''EOD'''
	 ,@input_data_1_name = N'spt_values'
WITH RESULT SETS (
					 (name VARCHAR(50)
					,number INT
					,[type] CHAR(3))
					);



---run procedure with sp_execute_external_Script

CREATE PROCEDURE sample_data
AS
SELECT
	 name
	,number
	,[type]
FROM master..spt_values
WHERE
	[type] = 'EOD'


EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<- InputDataset'
	  ,@input_data_1 = N'EXECUTE sample_data'
WITH RESULT SETS (
					 (name VARCHAR(50))
					,(number INT)
					,([type] CHAR(3))
					);


DECLARE @sql NVARCHAR(MAX)
SET @sql =  N'EXECUTE sample_data'
--EXECUTE SP_EXECUTESQL @sql

EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<- InputDataset'
	  ,@input_data_1 = @sql
WITH RESULT SETS (
					 (name VARCHAR(50))
					,(number INT)
					,([type] CHAR(3))
					);



-- COMMON TABLE EXPRESSION
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'WITH CTE
								AS ( SELECT name,number,[type]
								FROM master..spt_values
								WHERE [type] = ''EOD'')
								SELECT * FROM CTE'
WITH RESULT SETS (
					 (name VARCHAR(50)
					,number INT
					,[type] CHAR(3))
					);


-- SIMPLE SELECT with more than one column in select list
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'SELECT 2 AS Name
							  ,1 AS number
							  ,2 AS type;'
WITH RESULT SETS (
					 (name VARCHAR(50)
					,number INT
					,[type] CHAR(3))
					);



-- EXCEPT | INTERSECT
EXECUTE sp_execute_external_script    
	   @language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'SELECT 2 AS Name EXCEPT SELECT 1 As name'
WITH RESULT SETS (
					 (name VARCHAR(50))
					);

-- VARIABLE TABLES
-- yes

--BACTH GO or Semicolons
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N' SELECT 1; 
							GO 10'
WITH RESULT SETS UNDEFINED;



-- Logical statements (IF)
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'IF RAND() <= 0.5
							SELECT 1 AS ResultIF
							ELSE SELECT 2 AS ResultIF;' 
WITH RESULT SETS UNDEFINED;



-- Testing if we put IF Statement into outer variable within 
-- stored procedure
CREATE PROCEDURE IFY_IF
AS

DECLARE @IF NVARCHAR(MAX)
SET @IF = 'IF RAND() <= 0.5
			SELECT 1 AS ResultIF
			ELSE SELECT 2 AS ResultIF;'

EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = @IF
WITH RESULT SETS UNDEFINED;

-- execute; will return error
EXECUTE IFY_IF


-- Testing while statement
CREATE PROCEDURE IFY_WHILE
AS

DECLARE @while NVARCHAR(MAX)
SET @while = 'DECLARE @i INT = 0
					WHILE @i < 1
					BEGIN
						SELECT @i
						SET @i = @i+1
					END'

EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = @while
WITH RESULT SETS UNDEFINED;


-- execute; will return error
EXECUTE IFY_WHILE


-- Declaring a variable in @input_data parameter; will return error
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'DECLARE @i INT = 1
						 SELECT @i;' 
WITH RESULT SETS UNDEFINED;



-- Declaring a variable in @input_data parameter; will return error
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'SELECT 1 
						 DECLARE @i INT = 1;' 
WITH RESULT SETS UNDEFINED;


-- Declaring a variable outside @input_data parameter
-- will return error; variable @i is not recognized by sp_execute_external_script
DECLARE @i INT = 1
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = N'SELECT @i;' 
WITH RESULT SETS UNDEFINED;


-- Parameter as passed from Procedure
-- will not work. @input_data_1 parameter must be passed as variable in order
-- to recognize stored procedure input parameter
CREATE PROCEDURE pp_tt 
	(@i INT)
AS
EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = 'SELECT '+CAST(@i AS CHAR(10))+';'
WITH RESULT SETS UNDEFINED



-- Parameter for @input_data_1 is passed through inner variable within stored procedure
CREATE PROCEDURE pp_tt 
	(@i INT)
AS

DECLARE @SQL NVARCHAR(MAX)
SET @SQL = 'SELECT '+CAST(@i AS CHAR(10))+';'

EXECUTE sp_execute_external_script    
		@language = N'R'    
	  ,@script=N'OutputDataSet<-InputDataSet;'
	  ,@input_data_1 = @sql
WITH RESULT SETS UNDEFINED


EXECUTE pp_tt @i=23


-- MERGE StATEMENT?




