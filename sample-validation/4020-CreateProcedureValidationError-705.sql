-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [validation].[ValidationError_705]
(
      @StateOrganizationId  nvarchar(11)= 'all',
       @Datayear nvarchar(9)
)
AS
BEGIN
/**
Student Has Over 100 Percent Total FTE Within District

Student has over 100 percent FTE reported across all School Enrollment records in your district. Please verify FTE and enrollment records for the student.
**/

DECLARE @maydate date
SET @maydate = right(@datayear,4)+ '-05-01'  --work around for schools that add end of year date prevous to end of year

DECLARE @ERROR_CODE INT = 705
DECLARE @ERROR_MESSAGE  nvarchar(100) = 'Student Has Over 100 Percent Total FTE Within District'
DROP TABLE IF EXISTS #fte

--determine FTE
SELECT DISTINCT
 ssa.StudentUSI
 , school.LocalEducationAgencyId
 , SUM(ssa.FullTimeEquivalency) *100 AS fte
 into #fte
FROM edfi.StudentSchoolAssociation AS ssa
    INNER JOIN edfi.School AS school
		ON ssa.SchoolId = school.SchoolId
WHERE (ssa.ExitWithdrawDate is null OR ssa.ExitWithdrawDate > @maydate)		--check for full year enrollments
	AND ssa.EntryDate < @maydate											--skip summer school
GROUP BY ssa.StudentUSI, school.LocalEducationAgencyId
ORDER BY fte


--set error

INSERT INTO [validation].[DistrictErrorStaging]
(	[ErrorCode],
    [ErrorMessage],
	[Datayears],
	[DistrictCode],
    [StudentUSI],
	[DateAdded]
	)
select distinct
 ErrorCode = @ERROR_CODE
,[ErrorMessage]=@ERROR_MESSAGE
, Datayears = @Datayear
, DistrictCode = eoic.IdentificationCode
, [StudentUSI] = #fte.StudentUSI
, DateAdded = GETDATE()
FROM  #fte
	INNER JOIN edfi.EducationOrganizationIdentificationCode eoic
			 ON #fte.LocalEducationAgencyId = eoic.EducationOrganizationId
WHERE #fte.fte > 100
	AND (eoic.IdentificationCode = @StateOrganizationId or @StateOrganizationId='all')

DROP TABLE #fte

END;
GO
