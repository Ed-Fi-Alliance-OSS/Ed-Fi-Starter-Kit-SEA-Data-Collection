-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.


-- =========================================================================================
-- Query to generate SEA Starter Kit - Membership = Student Count report
-- =========================================================================================
SELECT NameOfInstitution AS [School Name]
	, GRADE_LEVEL
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
FROM  
(
  SELECT DISTINCT eo.NameOfInstitution, GRADE_LEVEL, STUDENT_ID,
	CASE GENDER_CODE 
		WHEN 'M' THEN ETHNIC_DESC + ' - Male'
		WHEN 'F' THEN ETHNIC_DESC + ' - Female'
	END AS ETHNIC_GENDER
  FROM [EdFi_Ods_2022].[reporting].[StudentFallMembership] sfm
  INNER JOIN edfi.EducationOrganization eo ON sfm.LOCATION_KEY = eo.EducationOrganizationId
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
					)  
) AS PivotTable
ORDER BY NameOfInstitution
	, GRADE_LEVEL;