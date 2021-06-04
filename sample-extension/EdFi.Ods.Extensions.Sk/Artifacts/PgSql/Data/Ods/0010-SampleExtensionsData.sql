do $$

begin

INSERT INTO sk.StudentSchoolAssociationExtension (EntryDate, SchoolId, StudentUSI, ResidentLocalEducationAgencyId, ResidentSchoolId, ReportingSchoolId)
SELECT ssa.EntryDate, ssa.SchoolId, st.StudentUSI, sc.LocalEducationAgencyId, sc.SchoolId, sc.SchoolId
FROM edfi.Student st
JOIN edfi.StudentSchoolAssociation ssa ON st.StudentUSI = ssa.StudentUSI
JOIN edfi.School sc ON ssa.SchoolId = sc.SchoolId
WHERE st.StudentUSI NOT IN (SELECT StudentUSI FROM sk.StudentSchoolAssociationExtension)

end $$;
