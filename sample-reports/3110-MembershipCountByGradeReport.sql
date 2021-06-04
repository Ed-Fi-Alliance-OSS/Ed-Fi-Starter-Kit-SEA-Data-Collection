-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.


-- =========================================================================================
-- Query to generate SEA Starter Kit - Membership by Grade = Student Count report
-- =========================================================================================
IF OBJECT_ID('tempdb..#GradeTotals') IS NOT NULL 
	DROP TABLE #GradeTotals
GO

DECLARE @Grades TABLE(GradeCode NVARCHAR(10), GradeName NVARCHAR(50), SortOrder INT)
 
INSERT INTO @Grades
VALUES 
('PK', 'Pre Kindergarten',1)
,('Kdg', 'Kindergarten',2)
,('Gr1', 'First grade',3)
,('Gr2', 'Second grade',4)
,('Gr3', 'Third grade',5)
,('Gr4', 'Fourth grade',6)
,('Gr5', 'Fifth grade',7)
,('Gr6', 'Sixth grade',8)
,('Gr7', 'Seventh grade',9)
,('Gr8', 'Eighth grade',10)
,('Gr9', 'Ninth grade',11)
,('Gr10', 'Tenth grade',12)
,('Gr11', 'Eleventh grade',13)
,('Gr12', 'Twelfth grade',14)

SELECT [District]
	, [School Name]
	, [PK]
	, [Kdg]
	, [Gr1]
	, [Gr2]
	, [Gr3]
	, [Gr4]
	, [Gr5]
	, [Gr6]
	, [Gr7]
	, [Gr8]
	, [Gr9]
	, [Gr10]
	, [Gr11]
	, [Gr12]
	, [PK]
		+ [Kdg]
		+ [Gr1]
		+ [Gr2]
		+ [Gr3]
		+ [Gr4]
		+ [Gr5]
		+ [Gr6]
		+ [Gr7]
		+ [Gr8]
		+ [Gr9]
		+ [Gr10]
		+ [Gr11]
		+ [Gr12] AS [TOTAL]
INTO #GradeTotals
FROM  
(
  SELECT DISTINCT d.NameOfInstitution AS [District]
	, s.NameOfInstitution AS [School Name]
	, g.GradeCode
	, STUDENT_ID
  FROM [EdFi_Ods_2022].[reporting].[StudentFallMembership] sfm
  INNER JOIN edfi.EducationOrganization s ON sfm.SCHOOL_CODE = s.EducationOrganizationId
  INNER JOIN edfi.EducationOrganization d ON sfm.DISTRICT_CODE_RESIDENCE = d.EducationOrganizationId
  INNER JOIN @Grades g ON sfm.GRADE_LEVEL = g.GradeName
) AS SourceTable  
PIVOT  
(  
  COUNT(STUDENT_ID)  
  FOR GradeCode IN ([PK]
				, [Kdg]
				, [Gr1]
				, [Gr2]
				, [Gr3]
				, [Gr4]
				, [Gr5]
				, [Gr6]
				, [Gr7]
				, [Gr8]
				, [Gr9]
				, [Gr10]
				, [Gr11]
				, [Gr12]
					)  
) AS PivotTable

SELECT [District]
	, [School Name]
	, [PK]
	, [Kdg]
	, [Gr1]
	, [Gr2]
	, [Gr3]
	, [Gr4]
	, [Gr5]
	, [Gr6]
	, [Gr7]
	, [Gr8]
	, [Gr9]
	, [Gr10]
	, [Gr11]
	, [Gr12]
	, [TOTAL]
FROM (
	SELECT [District]
		, [School Name]
		, [PK]
		, [Kdg]
		, [Gr1]
		, [Gr2]
		, [Gr3]
		, [Gr4]
		, [Gr5]
		, [Gr6]
		, [Gr7]
		, [Gr8]
		, [Gr9]
		, [Gr10]
		, [Gr11]
		, [Gr12]
		, [TOTAL]
	FROM #GradeTotals

	UNION ALL

	SELECT [District]
		, [School Name] + ' - TOTAL'
		, SUM([PK])
		, SUM([Kdg])
		, SUM([Gr1])
		, SUM([Gr2])
		, SUM([Gr3])
		, SUM([Gr4])
		, SUM([Gr5])
		, SUM([Gr6])
		, SUM([Gr7])
		, SUM([Gr8])
		, SUM([Gr9])
		, SUM([Gr10])
		, SUM([Gr11])
		, SUM([Gr12])
		, SUM([TOTAL])
	FROM #GradeTotals
	GROUP BY [District]
		, [School Name]

	UNION ALL

	SELECT [District] + ' - TOTAL'
		, NULL AS [School Name]
		, SUM([PK])
		, SUM([Kdg])
		, SUM([Gr1])
		, SUM([Gr2])
		, SUM([Gr3])
		, SUM([Gr4])
		, SUM([Gr5])
		, SUM([Gr6])
		, SUM([Gr7])
		, SUM([Gr8])
		, SUM([Gr9])
		, SUM([Gr10])
		, SUM([Gr11])
		, SUM([Gr12])
		, SUM([TOTAL])
	FROM #GradeTotals
	GROUP BY [District]
) t
ORDER BY t.[District]
	, t.[School Name];