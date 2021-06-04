-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

INSERT INTO sk.StudentSchoolAssociationExtension (EntryDate, SchoolId, StudentUSI, ResidentLocalEducationAgencyId, ResidentSchoolId, ReportingSchoolId)
SELECT ssa.EntryDate, ssa.SchoolId, st.StudentUSI, sc.LocalEducationAgencyId, sc.SchoolId, sc.SchoolId
FROM edfi.Student st
JOIN edfi.StudentSchoolAssociation ssa ON st.StudentUSI = ssa.StudentUSI
JOIN edfi.School sc ON ssa.SchoolId = sc.SchoolId
WHERE st.StudentUSI NOT IN (SELECT StudentUSI FROM sk.StudentSchoolAssociationExtension)

GO
