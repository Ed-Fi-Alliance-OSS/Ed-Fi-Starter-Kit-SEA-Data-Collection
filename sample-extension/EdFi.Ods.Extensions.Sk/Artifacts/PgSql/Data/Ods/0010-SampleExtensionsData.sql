do $$
declare grandBendHighSchoolId int;
declare residentLocalEducationAgencyId int;
declare student604822USI int;
declare student604823USI int;
declare student604822EntryDate date;
declare student604823EntryDate date;

begin

SELECT  SchoolId ,localEducationAgencyId into grandBendHighSchoolId ,residentLocalEducationAgencyId FROM edfi.School WHERE SchoolId = 255901001;
SELECT StudentUSI into student604822USI FROM edfi.Student WHERE StudentUniqueId = '604822';
SELECT StudentUSI into student604823USI FROM edfi.Student WHERE StudentUniqueId = '604823';
SELECT EntryDate into student604822EntryDate FROM edfi.StudentSchoolAssociation WHERE StudentUSI = student604822USI;
SELECT EntryDate into student604823EntryDate FROM edfi.StudentSchoolAssociation WHERE StudentUSI = student604823USI;

-- Sanity check to make sure some data exists, otherwise skip the script
if grandBendHighSchoolId is null or student604822USI is null or student604823USI is null then
    return;
end if;

INSERT INTO sk.studentschoolassociationextension (EntryDate,SchoolId,StudentUSI,ResidentLocalEducationAgencyId,ResidentSchoolId,ReportingSchoolId)
VALUES (student604822EntryDate,grandBendHighSchoolId,student604822USI,residentLocalEducationAgencyId,grandBendHighSchoolId,grandBendHighSchoolId);

INSERT INTO sk.studentschoolassociationextension (EntryDate,SchoolId,StudentUSI,ResidentLocalEducationAgencyId,ResidentSchoolId,ReportingSchoolId)
VALUES (student604823EntryDate,grandBendHighSchoolId,student604823USI,residentLocalEducationAgencyId,grandBendHighSchoolId,grandBendHighSchoolId);

end $$;
