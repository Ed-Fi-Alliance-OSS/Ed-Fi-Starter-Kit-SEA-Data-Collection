-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

CREATE OR ALTER FUNCTION validation.GetFullTimeEquivalency
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    LocalEducationAgencyId INT,
    StudentUSI INT,
    Total_FTE DECIMAL(3,2),
    INDEX idx_fte CLUSTERED(LocalEducationAgencyId, StudentUSI)
)
AS
BEGIN
    INSERT INTO @ResultTable (LocalEducationAgencyId, StudentUSI, Total_FTE)
    SELECT
        s.LocalEducationAgencyId,
        ssa.StudentUSI,
        total_fte = SUM(ssa.FullTimeEquivalency)
    FROM edfi.StudentSchoolAssociation ssa
    INNER JOIN sk.StudentSchoolAssociationExtension ssae ON
        ssa.StudentUsi = ssae.StudentUSI
        AND ssa.EntryDate = ssae.EntryDate
        AND ssa.SchoolId = ssae.SchoolId
    INNER JOIN edfi.school s ON
        ssae.ReportingSchoolId = s.SchoolId
    WHERE
        (ssa.ExitWithdrawDate IS NULL OR ssa.ExitWithdrawDate >= @searchDate)
        AND ssa.EntryDate <= @searchDate
    GROUP BY
        s.LocalEducationAgencyId,
        ssa.StudentUSI;

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION validation.GetValidationError_705
(
       @StateOrganizationId  nvarchar(11)= 'all',
       @Datayear nvarchar(9)
)
RETURNS @ResultTable TABLE
(
    [ErrorCode] [nvarchar](255) NOT NULL,
    [ErrorMessage] [nvarchar](255) NOT NULL,
	[Datayears] [nvarchar](255) NOT NULL,
	[DistrictCode] [nvarchar](255) NOT NULL,
	[StudentUSI] [nvarchar](255) NOT NULL,
    [DateAdded] [datetime] NOT NULL
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


--set error

INSERT INTO  @ResultTable (ErrorCode, ErrorMessage, Datayears, DistrictCode, StudentUSI, DateAdded)

SELECT DISTINCT
 ErrorCode = @ERROR_CODE
,ErrorMessage = @ERROR_MESSAGE
,Datayears = @Datayear
,DistrictCode = eoic.IdentificationCode
,StudentUSI = fte.StudentUSI
,DateAdded = GETDATE()
FROM  validation.GetFullTimeEquivalency(@maydate) fte 
	INNER JOIN edfi.EducationOrganizationIdentificationCode eoic
			 ON fte.LocalEducationAgencyId = eoic.EducationOrganizationId
WHERE fte.total_fte * 100 > 100
	AND (eoic.IdentificationCode = @StateOrganizationId or @StateOrganizationId='all')


    RETURN;
END;
GO

CREATE OR ALTER FUNCTION validation.GetValidationError_743
(
       @StateOrganizationId  nvarchar(11)= 'all',
       @Datayear nvarchar(9)
)
RETURNS @ResultTable TABLE
(
    [ErrorCode] [nvarchar](255) NOT NULL,
	[ErrorMessage] [nvarchar](255) NOT NULL,
	[Datayears] [nvarchar](255) NOT NULL,
	[DistrictCode] [nvarchar](255) NOT NULL,
	[StudentUSI] [nvarchar](255) NOT NULL,
    [DateAdded] [datetime] NOT NULL
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

INSERT INTO  @ResultTable (ErrorCode, ErrorMessage, Datayears, DistrictCode, StudentUSI, DateAdded)

SELECT DISTINCT
 ErrorCode = @ERROR_CODE
,ErrorMessage = @ERROR_MESSAGE
,Datayears = @Datayear
,DistrictCode = school.LocalEducationAgencyId 
,StudentUSI = s.StudentUSI
,DateAdded = GETDATE()
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

    RETURN;
END;
GO
