-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[ValidationError_743] 
( 
       @StateOrganizationId  nvarchar(11)= 'all',  
       @Datayear nvarchar(9)
) 
as
/**
No Race Reported for Student

No race codes were submitted in a student’s demographic record. Please submit at least one race.
**/
DECLARE @ERROR_CODE INT = 743
DECLARE @ERROR_MESSAGE  nvarchar(100) = 'No Race Reported for Student'

--set error

INSERT INTO [dbo].[DistrictErrorStaging]
(	[ErrorCode],
    [ErrorMessage],
	[Datayears],
	[DistrictCode],
    [StudentUSI],
	[DateAdded]
	)
select distinct
 ErrorCode = @ERROR_CODE
, [ErrorMessage] = @ERROR_MESSAGE
, Datayears = @Datayear
, DistrictCode = school.LocalEducationAgencyId 
, ErrorKey1 = s.StudentUSI
, DateAdded = GETDATE()
from  edfi.Student as s
inner join edfi.StudentSchoolAssociation as ssa
	on s.StudentUSI = ssa.StudentUSI
inner join edfi.school as school
	on ssa.SchoolId = school.SchoolId
inner join edfi.StudentEducationOrganizationAssociation as seoa
	on ssa.studentusi = seoa.StudentUSI
	and school.LocalEducationAgencyId = seoa.EducationOrganizationId
left join edfi.StudentEducationOrganizationAssociationRace as seoar
	on ssa.StudentUSI = seoar.StudentUSI
	and school.LocalEducationAgencyId = seoar.EducationOrganizationId
inner join edfi.EducationOrganizationIdentificationCode eoic
	on ssa.SchoolId = eoic.EducationOrganizationId
where  seoar.StudentUSI is null
	and  (left(cast(eoic.IdentificationCode as varchar),6) = left(@StateOrganizationId,6) or @StateOrganizationId='all')


select * from [dbo].[DistrictErrorStaging] where [ErrorCode] = 743



