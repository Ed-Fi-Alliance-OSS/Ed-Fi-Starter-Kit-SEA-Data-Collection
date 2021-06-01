-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

use EdFi_Ods_2022
Go

DECLARE @grandBendHighSchoolId INT;
DECLARE @localEducationAgencyId INT;
DECLARE @student604822USI INT;
DECLARE @student604823USI INT;
DECLARE @student604822EntryDate date;
DECLARE @student604823EntryDate date;

SELECT @grandBendHighSchoolId = SchoolId , @localEducationAgencyId= localEducationAgencyId FROM edfi.School WHERE SchoolId = 255901001
SELECT @student604822USI = StudentUSI FROM edfi.Student WHERE StudentUniqueId = '604822'
SELECT @student604823USI = StudentUSI FROM edfi.Student WHERE StudentUniqueId = '604823'
SELECT @student604822EntryDate= EntryDate FROM edfi.[StudentSchoolAssociation] where StudentUSI =@student604822USI
SELECT @student604823EntryDate =EntryDate FROM edfi.[StudentSchoolAssociation] where StudentUSI =@student604823USI


--Sanity check to make sure some data exists, otherwise skip the script

IF (@grandBendHighSchoolId IS NULL OR @student604822USI IS NULL OR @student604823USI IS NULL) RETURN

INSERT INTO [sk].[StudentSchoolAssociationExtension]
([EntryDate]
,[SchoolId]
,[StudentUSI]
,[ResidentLocalEducationAgencyId]
,[ResidentSchoolId]
,[ReportingSchoolId])
VALUES
(@student604822EntryDate
,@grandBendHighSchoolId
,@student604822USI
,@localEducationAgencyId
,@grandBendHighSchoolId
,@grandBendHighSchoolId
)


INSERT INTO [sk].[StudentSchoolAssociationExtension]
([EntryDate]
,[SchoolId]
,[StudentUSI]
,[ResidentLocalEducationAgencyId]
,[ResidentSchoolId]
,[ReportingSchoolId])
VALUES
(@student604823EntryDate
,@grandBendHighSchoolId
,@student604823USI
,@localEducationAgencyId
,@grandBendHighSchoolId
,@grandBendHighSchoolId
)

GO
