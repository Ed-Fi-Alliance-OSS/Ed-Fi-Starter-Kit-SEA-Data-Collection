-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[ValidationError_705]
(
      @StateOrganizationId  nvarchar(11)= 'all',
       @Datayear nvarchar(9)
)
as
/**
Student Has Over 100 Percent Total FTE Within District

Student has over 100 percent FTE reported across all School Enrollment records in your district. Please verify FTE and enrollment records for the student.
**/

declare @maydate date
set @maydate = right(@datayear,4)+ '-05-01'  --work around for schools that add end of year date prevous to end of year

DECLARE @ERROR_CODE INT = 705
DECLARE @ERROR_MESSAGE  nvarchar(100) = 'Student Has Over 100 Percent Total FTE Within District'
DROP TABLE IF EXISTS #fte

--determine FTE
select distinct
 ssa.StudentUSI
 , school.LocalEducationAgencyId
 , sum(ssa.FullTimeEquivalency) *100 as fte
 into #fte
from edfi.StudentSchoolAssociation as ssa
	inner join edfi.School as school
		on ssa.SchoolId = school.SchoolId
where (ssa.ExitWithdrawDate is null or ssa.ExitWithdrawDate > @maydate)		--check for full year enrollments
	and ssa.EntryDate < @maydate											--skip summer school
group by ssa.StudentUSI, school.LocalEducationAgencyId
order by fte


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
,[ErrorMessage]=@ERROR_MESSAGE
, Datayears = @Datayear
, DistrictCode = eoic.IdentificationCode
, [StudentUSI] = #fte.StudentUSI
, DateAdded = GETDATE()
from  #fte
	inner join edfi.EducationOrganizationIdentificationCode eoic
			 on #fte.LocalEducationAgencyId = eoic.EducationOrganizationId
where #fte.fte > 100
	and (eoic.IdentificationCode = @StateOrganizationId or @StateOrganizationId='all')

drop table #fte



select * from [dbo].[DistrictErrorStaging] where [ErrorCode] = 705
