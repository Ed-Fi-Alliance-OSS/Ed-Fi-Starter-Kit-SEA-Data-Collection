-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [validation].[ValidationError_743] 
( 
       @StateOrganizationId  nvarchar(11)= 'all',  
       @Datayear nvarchar(9)
) 
AS
BEGIN
/**
No Race Reported for Student

No race codes were submitted in a student’s demographic record. Please submit at least one race.
**/
DECLARE @ERROR_CODE INT = 743
DECLARE @ERROR_MESSAGE  nvarchar(100) = 'No Race Reported for Student'

--set error

INSERT INTO [validation].[DistrictErrorStaging]
(  [ErrorCode],
    [ErrorMessage],
	[Datayears],
	[DistrictCode],
    [StudentUSI],
	[DateAdded]
	)
SELECT DISTINCT
 ErrorCode = @ERROR_CODE
, [ErrorMessage] = @ERROR_MESSAGE
, Datayears = @Datayear
, DistrictCode = school.LocalEducationAgencyId 
, ErrorKey1 = s.StudentUSI
, DateAdded = GETDATE()
FROM  edfi.Student AS s
INNER JOIN edfi.StudentSchoolAssociation AS ssa
	ON s.StudentUSI = ssa.StudentUSI
INNER JOIN edfi.school AS school
	ON ssa.SchoolId = school.SchoolId
INNER JOIN edfi.StudentEducationOrganizationAssociation AS seoa
	ON ssa.studentusi = seoa.StudentUSI
	AND school.LocalEducationAgencyId = seoa.EducationOrganizationId
LEFT JOIN edfi.StudentEducationOrganizationAssociationRace AS seoar
	ON ssa.StudentUSI = seoar.StudentUSI
	AND school.LocalEducationAgencyId = seoar.EducationOrganizationId
INNER JOIN edfi.EducationOrganizationIdentificationCode eoic
	ON ssa.SchoolId = eoic.EducationOrganizationId
WHERE  seoar.StudentUSI is null
	AND  (LEFT(CAST(eoic.IdentificationCode AS varchar),6) = LEFT(@StateOrganizationId,6) OR @StateOrganizationId='all')


END;
GO