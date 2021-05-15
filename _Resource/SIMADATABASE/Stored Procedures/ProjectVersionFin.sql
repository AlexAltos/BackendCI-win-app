IF NOT EXISTS (SELECT NULL
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_NAME = 'ProjectVersionFin'
            AND ROUTINE_TYPE = N'PROCEDURE')
BEGIN
    EXEC ('CREATE PROCEDURE [dbo].[ProjectVersionFin] AS BEGIN SELECT 1 END')
END
GO


ALTER PROCEDURE [dbo].ProjectVersionFin

AS
BEGIN

	DECLARE @SectionProject VARCHAR(MAX), @ProjectType VARCHAR(MAX), @Project VARCHAR(MAX)
	DECLARE @ProjectVersionOne table( Id INT, SectionProject VARCHAR(MAX), ProjectType VARCHAR(MAX), Project VARCHAR(MAX), GMajor VARCHAR(MAX), Major INT, Minor INT, Date DATETIME)
	DECLARE @ProjectVersionFin TABLE (Project  VARCHAR(MAX), [Test] VARCHAR(MAX), [PreProd] VARCHAR(MAX), [Prod] VARCHAR(MAX))

	DECLARE cur CURSOR FOR
	SELECT DISTINCT SectionProject, ProjectType,	Project  
	FROM ProjectVersion 

	 OPEN cur
	 FETCH NEXT FROM cur INTO   @SectionProject, @ProjectType, @Project 

	 WHILE @@FETCH_STATUS = 0
	 BEGIN

		 insert into @ProjectVersionOne (Id, SectionProject, ProjectType, Project, GMajor, Major, Minor, Date)
		 SELECT TOP 1      Id, SectionProject, ProjectType, Project, GMajor, Major, Minor, Date
		 FROM ProjectVersion  pv 
		 WHERE   SectionProject = @SectionProject AND ProjectType=@ProjectType AND Project = @Project
		 ORDER BY  pv.Date desc 

	  FETCH NEXT FROM cur INTO @SectionProject, @ProjectType, @Project 
	 END

	 CLOSE cur
	 DEALLOCATE cur

	/*

	SELECT 
		 SectionProject
		 ,ProjectType
		 ,Project 
		 ,GMajor +' '
			  + CASE WHEN Major=0 THEN '' ELSE  CAST(Major AS VARCHAR(MAX)) +'-' END 
			  + CAST(Minor AS VARCHAR(MAX)) + ' ' AS ProjectVersion
		 ,CONVERT(VARCHAR, Date, 104)  AS [DateUpdate] --+ ' ' + convert(varchar(20),CONVERT(VARCHAR, Date, 24) ,120)          
	FROM @ProjectVersionOne          
	ORDER BY SectionProject, Project ,
		 CASE WHEN ProjectType = 'Test' THEN 1     
			  WHEN ProjectType = 'PreProd' THEN 2 
			  WHEN ProjectType = 'Prod' THEN 3 END


	-- --------------------------------------

	SELECT Project , [Test], [PreProd], [Prod]    
	FROM  (SELECT 
			  SectionProject
			  ,ProjectType
			  ,Project 
			  ,CASE WHEN Major=0 THEN '' ELSE  CAST(Major AS VARCHAR(MAX)) +'-' END 
				   + CAST(Minor AS VARCHAR(MAX)) + ' ' AS ProjectVersion
		 FROM @ProjectVersionOne          
		 WHERE SectionProject = '223'
		 ) AS dd
					  
	PIVOT (max(ProjectVersion) for ProjectType in ([Test], [PreProd], [Prod])
	) AS test_pivot

	-- --------------------------------------
	*/

	DECLARE cur CURSOR FOR
	SELECT DISTINCT SectionProject  
	FROM ProjectVersion 

	 OPEN cur
	 FETCH NEXT FROM cur INTO   @SectionProject

	 WHILE @@FETCH_STATUS = 0
	 BEGIN

		 insert into @ProjectVersionFin (Project , [Test], [PreProd], [Prod])
		 VALUES (@SectionProject, '', '', '')

		 insert into @ProjectVersionFin (Project , [Test], [PreProd], [Prod])
		 SELECT Project , [Test], [PreProd], [Prod]    
		 FROM  (SELECT 
				   SectionProject
				   ,ProjectType
				   ,Project 
				   ,CASE WHEN Major=0 THEN '' ELSE  CAST(Major AS VARCHAR(MAX)) +'-' END 
						+ CAST(Minor AS VARCHAR(MAX)) +' --- '+  CONVERT(VARCHAR, Date, 104)  AS ProjectVersion
			  FROM @ProjectVersionOne          
			  WHERE SectionProject = @SectionProject
			  ) AS dd
					  
		 PIVOT (max(ProjectVersion) for ProjectType in ([Test], [PreProd], [Prod])
		 ) AS test_pivot

	  FETCH NEXT FROM cur INTO @SectionProject
	 END

	 CLOSE cur
	 DEALLOCATE cur


	SELECT * FROM @ProjectVersionFin

END
GO
