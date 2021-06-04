-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.


-- =========================================================================================
-- Query to generate SEA Starter Kit - Membership By Grade, Race and Gender = Student Count report
-- =========================================================================================
IF OBJECT_ID('tempdb..#GradeTotals') IS NOT NULL 
	DROP TABLE #GradeTotals
GO

DECLARE @Grades TABLE(GradeCode NVARCHAR(10), GradeName NVARCHAR(50), SortOrder INT)
 
INSERT INTO @Grades
VALUES 
('PK', 'Pre Kindergarten',1)
,('K', 'Kindergarten',2)
,('01', 'First grade',3)
,('02', 'Second grade',4)
,('03', 'Third grade',5)
,('04', 'Fourth grade',6)
,('05', 'Fifth grade',7)
,('06', 'Sixth grade',8)
,('07', 'Seventh grade',9)
,('08', 'Eighth grade',10)
,('09', 'Ninth grade',11)
,('10', 'Tenth grade',12)
,('11', 'Eleventh grade',13)
,('12', 'Twelfth grade',14)

SELECT [District]
	, [School Name]
	, [GradeName] AS [Grade]
	, [SortOrder] AS [GradeSortOrder]
	, [White - Female]
	, [White - Male]
	, [Black - African American - Female] AS [Black - Female]
	, [Black - African American - Male] AS [Black - Male]
	, [Hispanic - Female]
	, [Hispanic - Male]
	, [Asian - Female]
	, [Asian - Male]
	, [American Indian - Alaska Native - Female] AS [American Indian / Alaska Native - Female]
	, [American Indian - Alaska Native - Male] AS [American Indian / Alaska Native - Male]
	, [Native Hawaiian - Pacific Islander - Female] AS [Native Hawaiian / Pacific Islander - Female]
	, [Native Hawaiian - Pacific Islander - Male] AS [Native Hawaiian / Pacific Islander - Male]
	, [Multiple - Female] AS [Two or More Races - Female]
	, [Multiple - Male] AS [Two or More Races - Male]
	, [White - Female]
		+ [Black - African American - Female]
		+ [Hispanic - Female]
		+ [Asian - Female]
		+ [American Indian - Alaska Native - Female]
		+ [Native Hawaiian - Pacific Islander - Female]
		+ [Multiple - Female] AS [Total Female]
	, [White - Male]
		+ [Black - African American - Male]
		+ [Hispanic - Male]
		+ [Asian - Male]
		+ [American Indian - Alaska Native - Male]
		+ [Native Hawaiian - Pacific Islander - Male]
		+ [Multiple - Male] AS [Total Male]
	, [White - Female]
		+ [Black - African American - Female]
		+ [Hispanic - Female]
		+ [Asian - Female]
		+ [American Indian - Alaska Native - Female]
		+ [Native Hawaiian - Pacific Islander - Female]
		+ [Multiple - Female]
		+ [White - Male]
		+ [Black - African American - Male]
		+ [Hispanic - Male]
		+ [Asian - Male]
		+ [American Indian - Alaska Native - Male]
		+ [Native Hawaiian - Pacific Islander - Male]
		+ [Multiple - Male] AS [Total Students]
INTO #GradeTotals
FROM  
(
  SELECT DISTINCT d.NameOfInstitution AS [District]
	, s.NameOfInstitution AS [School Name]
	, g.GradeName
	, g.SortOrder
	, STUDENT_ID
	,CASE GENDER_CODE 
		WHEN 'M' THEN ETHNIC_CODE + ' - Male'
		WHEN 'F' THEN ETHNIC_CODE + ' - Female'
	END AS ETHNIC_GENDER
  FROM [EdFi_Ods_2022].[reporting].[StudentFallMembership] sfm
  INNER JOIN edfi.EducationOrganization s ON sfm.SCHOOL_CODE = s.EducationOrganizationId
  INNER JOIN edfi.EducationOrganization d ON sfm.DISTRICT_CODE_RESIDENCE = d.EducationOrganizationId
  INNER JOIN @Grades g ON sfm.GRADE_LEVEL = g.GradeName
) AS SourceTable  
PIVOT  
(  
  COUNT(STUDENT_ID)  
  FOR ETHNIC_GENDER IN ([White - Female]
						, [White - Male]
						, [Black - African American - Female]
						, [Black - African American - Male]
						, [Hispanic - Female]
						, [Hispanic - Male]
						, [Asian - Female]
						, [Asian - Male]
						, [American Indian - Alaska Native - Female]
						, [American Indian - Alaska Native - Male]
						, [Native Hawaiian - Pacific Islander - Female]
						, [Native Hawaiian - Pacific Islander - Male]
						, [Multiple - Female]
						, [Multiple - Male]
					)  
) AS PivotTable

SELECT [District]
	, [School Name]
	, [Grade]
	, [White - Female]
	, [White - Male]
	, [Black - Female]
	, [Black - Male]
	, [Hispanic - Female]
	, [Hispanic - Male]
	, [Asian - Female]
	, [Asian - Male]
	, [American Indian / Alaska Native - Female]
	, [American Indian / Alaska Native - Male]
	, [Native Hawaiian / Pacific Islander - Female]
	, [Native Hawaiian / Pacific Islander - Male]
	, [Two or More Races - Female]
	, [Two or More Races - Male]
	, [Total Female]
	, [Total Male]
	, [Total Students]
FROM (
	SELECT [District]
		, [School Name]
		, [Grade]
		, [GradeSortOrder]
		, [White - Female]
		, [White - Male]
		, [Black - Female]
		, [Black - Male]
		, [Hispanic - Female]
		, [Hispanic - Male]
		, [Asian - Female]
		, [Asian - Male]
		, [American Indian / Alaska Native - Female]
		, [American Indian / Alaska Native - Male]
		, [Native Hawaiian / Pacific Islander - Female]
		, [Native Hawaiian / Pacific Islander - Male]
		, [Two or More Races - Female]
		, [Two or More Races - Male]
		, [Total Female]
		, [Total Male]
		, [Total Students]
	FROM #GradeTotals

	UNION ALL

	SELECT [District]
		, [School Name] + ' - TOTAL'
		, NULL AS [Grade]
		, 100 AS [GradeSortOrder]
		, SUM([White - Female])
		, SUM([White - Male])
		, SUM([Black - Female])
		, SUM([Black - Male])
		, SUM([Hispanic - Female])
		, SUM([Hispanic - Male])
		, SUM([Asian - Female])
		, SUM([Asian - Male])
		, SUM([American Indian / Alaska Native - Female])
		, SUM([American Indian / Alaska Native - Male])
		, SUM([Native Hawaiian / Pacific Islander - Female])
		, SUM([Native Hawaiian / Pacific Islander - Male])
		, SUM([Two or More Races - Female])
		, SUM([Two or More Races - Male])
		, SUM([Total Female])
		, SUM([Total Male])
		, SUM([Total Students])
	FROM #GradeTotals
	GROUP BY [District]
		, [School Name]

	UNION ALL

	SELECT [District] + ' - TOTAL'
		, NULL AS [School Name]
		, NULL AS [Grade]
		, 1000 AS [GradeSortOrder]
		, SUM([White - Female])
		, SUM([White - Male])
		, SUM([Black - Female])
		, SUM([Black - Male])
		, SUM([Hispanic - Female])
		, SUM([Hispanic - Male])
		, SUM([Asian - Female])
		, SUM([Asian - Male])
		, SUM([American Indian / Alaska Native - Female])
		, SUM([American Indian / Alaska Native - Male])
		, SUM([Native Hawaiian / Pacific Islander - Female])
		, SUM([Native Hawaiian / Pacific Islander - Male])
		, SUM([Two or More Races - Female])
		, SUM([Two or More Races - Male])
		, SUM([Total Female])
		, SUM([Total Male])
		, SUM([Total Students])
	FROM #GradeTotals
	GROUP BY [District]
) t
ORDER BY t.[District]
	, t.[School Name]
	, t.[GradeSortOrder];