-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

CREATE OR ALTER PROCEDURE reporting.LoadStudentFallMembership
AS
BEGIN
    DECLARE @Datayear NVARCHAR(9) = '2020-2021'

    --October 1st
    DECLARE @October_1st date = LEFT(@Datayear,4) + '-10-01'
    DECLARE @SCHOOL_YEAR VARCHAR(10) = '2021-06-30'

    --Age 21 Date
    DECLARE @Age_21 date = CAST(CAST(LEFT(@Datayear,4) AS INT)-21 AS CHAR(4)) + '-08-01'

    DECLARE @StudentIdentDesc int

    SELECT @StudentIdentDesc = d.DescriptorId
    FROM edfi.Descriptor as d
    INNER JOIN edfi.StudentIdentificationSystemDescriptor s ON
        s.StudentIdentificationSystemDescriptorId = d.DescriptorId
        AND d.CodeValue = 'District';

    TRUNCATE TABLE reporting.StudentFallMembership;

    INSERT INTO reporting.StudentFallMembership
    SELECT
        DATAYEARS = LEFT(@DATAYEAR,4) + RIGHT(@DATAYEAR,4)
        ,DISTRICT_CODE = LEFT(eoic.IdentificationCode,7)
        ,SCHOOL_CODE = RIGHT(eoic.IdentificationCode,3)
        ,NDE_STUDENT_ID = LEFT(LTRIM(s.StudentUniqueId),10)
        ,LOCAL_STUDENT_ID = LEFT(COALESCE(sic.IdentificationCode,''),25)
        ,DISTRICT_CODE_RESIDENCE = LEFT(eoic_resdist.IdentificationCode,7)
        ,SCHOOL_CODE_RESIDENCE = ''--ISNULL(RIGHT(ressch.StateOrganizationID,3),'')
        ,STUDENT_NAME = LEFT(s.LastSurname+', '+s.FirstName,42)
        ,STUDENT_LAST_NM = LEFT(s.LastSurname,60)
        ,STUDENT_FIRST_NM = LEFT(s.FirstName,60)
        ,STUDENT_MID_INIT = COALESCE(LEFT(s.MiddleName,1),'')
        ,ALIAS_FIRST_NAME = ''
        ,ALIAS_LAST_NAME = ''
        ,ALIAS_MID_NAME = ''
        ,ALIAS_NAME_SUFFIX = ''
        ,STUD_MIDDLE_NM = ''
        ,GRADE_LEVEL = LEFT(d.CodeValue,2)
        ,BIRTHDATE = s.BirthDate
        ,GENDER_CODE = LEFT(sex.CodeValue,1)
        ,ETHNIC_CODE = r.reporting_race
        ,ETHNIC_DESC = r.reporting_race_desc
        ,SPECIAL_EDUCATION_CODE = CASE WHEN specialeducation.studentusi IS NULL THEN '2' else '1' END
        ,SPECIAL_EDUCATION_DESC = CASE WHEN specialeducation.studentusi IS NULL THEN 'No' else 'Yes' END
        ,LEP_ELIGIBILITY_CODE = CASE WHEN el.StudentUSI is not null AND ISNULL(el.RedesignatedEnglishFluent,0) = 0 THEN '1' else '2' END
        ,LEP_ELIGIBILITY_DESC = CASE WHEN el.StudentUSI is not null AND ISNULL(el.RedesignatedEnglishFluent,0) = 0 THEN 'Yes' else 'No' END
        ,LEP_PARTICIPATION_CODE = CASE WHEN ISNULL(el.EnglishLearnerParticipation,0) = 1 AND ISNULL(el.RedesignatedEnglishFluent,0) = 0 THEN '1' else '2' END
        ,LEP_PARTICIPATION_DESC = CASE WHEN ISNULL(el.EnglishLearnerParticipation,0) = 1 AND ISNULL(el.RedesignatedEnglishFluent,0) = 0 THEN 'Yes' else 'No' END
        ,LEP_DURATION_CODE = null
        ,LEP_DURATION_DESC = null
        ,ENGLISH_PROFICIENCY_CODE = CASE WHEN ISNULL(el.RedesignatedEnglishFluent,0) = 1 THEN '04' else '00' END
        ,ENGLISH_PROFICIENCY_DESC = CASE WHEN ISNULL(el.RedesignatedEnglishFluent,0) = 1 THEN 'Redesignated as English Fluent' else 'Not Applicable' END
        ,HOME_LANGUAGE_CODE = homelanguage.CodeValue
        ,HOME_LANGUAGE_DESC = LEFT(homelanguage.Description,100)
        ,TARGETED_ASSISTANCE_NONPUBLIC_CODE = '2' --because this is Fall Membership, there are no non-public students in the table
        ,TARGETED_ASSISTANCE_NONPUBLIC_DESC = 'No' --because this is Fall Membership, there are no non-public students in the table
        ,EXPECTED_GRADUATION_YEAR = seodcy.SchoolYear
        ,STUD_SINGLE_PARENT_CODE = CASE WHEN singleparent.StudentUSI IS NULL THEN '2' else '1' END
        ,STUD_SINGLE_PARENT_DESC = CASE WHEN singleparent.StudentUSI IS NULL THEN 'No' else 'Yes' END
        ,IMMIGRANT_CODE = imm.CodeValue
        ,IMMIGRANT_DESC = imm.Description
        ,FTE_PERCENT = msid.total_fte
        ,HISPANIC_IND = case r.hispanic_indicator WHEN 'Y' THEN 'Yes' else 'No' END
        ,PRIMARY_RACE_IND = null
        ,ETHNIC_CODE_2 = null
        ,ETHNIC_DESC_2 = null
        ,RACE1_SHORT_DESC = r.race_1_desc
        ,RACE2_CODE = r.race_2_code
        ,RACE2_SHORT_DESC = r.race_2_desc
        ,RACE3_CODE = r.race_3_code
        ,RACE3_SHORT_DESC = r.race_3_desc
        ,RACE4_CODE = r.race_4_code
        ,RACE4_SHORT_DESC = r.race_4_desc
        ,RACE5_CODE = r.race_5_code
        ,RACE5_SHORT_DESC = r.race_5_desc
        ,UNACCOMPANIED_HOMELESS_YOUTH_CODE = CASE WHEN ISNULL(home.HomelessUnaccompaniedYouth,0) = 1 THEN '1' else '2' END
        ,UNACCOMPANIED_HOMELESS_YOUTH_DESC = CASE WHEN ISNULL(home.HomelessUnaccompaniedYouth,0) = 1 THEN 'Yes' else 'No' END
        ,MILITARY_FAMILY_CODE = CASE WHEN parentinmilitary.StudentUSI IS NULL THEN '2' else '1' END
        ,MILITARY_FAMILY_DESC = CASE WHEN parentinmilitary.StudentUSI IS NULL THEN 'No' else 'Yes' END
        ,RESIDENCE_STATUS_CODE = COALESCE(d_residencestatus.CodeValue,'00')
        ,RESIDENCE_STATUS_DESCRIPTION = COALESCE(d_residencestatus.ShortDescription,'Not applicable')
        ,BATCH_ID = null
        ,STUDENT_ID = LEFT(LTRIM(s.StudentUniqueId),10)
        ,STUDENT_KEY = s.StudentUSI
        ,DISTRICT_KEY = cast('31'+LEFT(eoic.IdentificationCode,2)+substring(eoic.IdentificationCode,4,4) as int)
        ,LOCATION_KEY = eo.EducationOrganizationId
        ,SCHOOL_YEAR = RIGHT(@DATAYEAR,4)+'-06-30'
    FROM edfi.Student s WITH (NOLOCK)

    INNER JOIN edfi.StudentSchoolAssociation ssa WITH (NOLOCK) ON
        s.StudentUSI = ssa.StudentUSI
    INNER JOIN sk.StudentSchoolAssociationExtension ssaext WITH (NOLOCK) ON
        ssa.StudentUSI = ssaext.StudentUSI
        AND ssa.SchoolId = ssaext.SchoolId
        AND ssa.EntryDate = ssaext.EntryDate
    INNER JOIN edfi.EducationOrganization resdist ON
        resdist.EducationOrganizationId = ssaext.ResidentLocalEducationAgencyId
    INNER JOIN edfi.EducationOrganizationIdentificationCode eoic_resdist ON
        resdist.EducationOrganizationId = eoic_resdist.EducationOrganizationId
    LEFT JOIN edfi.EducationOrganization ressch ON
        ressch.EducationOrganizationId = ssaext.ResidentSchoolId
    INNER JOIN reporting.GetMinimalSchoolReportingId(@October_1st) msid ON
        ssa.StudentUSI = msid.StudentUSI
        AND ssaext.ReportingSchoolId = msid.ReportingSchoolId
    LEFT JOIN edfi.Descriptor d_residencestatus ON
        ssa.ResidencyStatusDescriptorId = d_residencestatus.DescriptorId
    INNER JOIN edfi.school as school ON
        ssa.SchoolId = school.SchoolId
    INNER JOIN edfi.EducationOrganization ed WITH (NOLOCK) ON
        ed.EducationOrganizationId = school.LocalEducationAgencyId
    INNER JOIN edfi.StudentEducationOrganizationAssociation seod WITH (NOLOCK) ON
        ssa.StudentUSI = seod.StudentUSI
        AND school.LocalEducationAgencyId = seod.EducationOrganizationId
    INNER JOIN edfi.StudentEducationOrganizationAssociationStudentCharacteristic as seodx WITH (NOLOCK) ON
        seodx.StudentUSI = seod.StudentUSI
        AND seodx.EducationOrganizationId = seod.EducationOrganizationId
    INNER JOIN edfi.Descriptor sex ON
        sex.DescriptorId = seod.SexDescriptorId
    INNER JOIN edfi.EducationOrganization eo WITH (NOLOCK) ON
        eo.EducationOrganizationId = ssaext.ReportingSchoolId
    INNER JOIN edfi.EducationOrganizationIdentificationCode eoic ON
        eo.EducationOrganizationId = eoic.EducationOrganizationId
    INNER JOIN reporting.GetRaceInformation() r ON
        r.StudentUSI = s.StudentUSI
        AND r.EducationOrganizationId = seod.EducationOrganizationId
    INNER JOIN edfi.Descriptor d WITH (NOLOCK) ON
        d.DescriptorId = ssa.EntryGradeLevelDescriptorId
    LEFT JOIN edfi.StudentEducationOrganizationAssociationStudentIdentificationCode sic ON
        sic.StudentIdentificationSystemDescriptorId = @StudentIdentDesc
        AND s.StudentUSI = sic.StudentUSI
        AND school.LocalEducationAgencyId = sic.EducationOrganizationId
    LEFT JOIN reporting.GetFreeOrReducedLunchInformation(@October_1st) frl ON
        ssa.StudentUSI = frl.StudentUSI
        AND school.LocalEducationAgencyId = frl.ProgramEducationOrganizationId
    LEFT JOIN reporting.GetEnglishLearners(@October_1st) el ON
        ssa.StudentUSI = el.StudentUSI
        AND school.LocalEducationAgencyId = el.ProgramEducationOrganizationId
    LEFT JOIN edfi.GeneralStudentProgramAssociation homespa WITH (NOLOCK) ON
        homespa.StudentUSI = ssa.StudentUSI
        AND homespa.ProgramName = 'Homeless'
        AND homespa.BeginDate <= @October_1st
        AND (homespa.ENDDate IS NULL or homespa.ENDDate >= @October_1st)
    LEFT JOIN edfi.StudentHomelessProgramAssociation home ON
        home.BeginDate = homespa.BeginDate
        AND home.EducationOrganizationId = homespa.EducationOrganizationId
        AND home.ProgramEducationOrganizationId = homespa.ProgramEducationOrganizationId
        AND home.ProgramName = homespa.ProgramName
        AND home.ProgramTypeDescriptorId = homespa.ProgramTypeDescriptorId
        AND home.StudentUSI = homespa.StudentUSI
    LEFT JOIN edfi.Descriptor imm WITH (NOLOCK) ON
        imm.DescriptorId = seodx.StudentCharacteristicDescriptorId
        AND imm.CodeValue = 'Immigrant'
    LEFT JOIN (
        SELECT
            seodsc.EducationOrganizationId,
            seodsc.StudentUSI,
            d.CodeValue,
            d.Description
        FROM edfi.StudentEducationOrganizationAssociationStudentCharacteristic seodsc WITH (NOLOCK)
        INNER JOIN edfi.Descriptor d ON
            seodsc.StudentCharacteristicDescriptorId = d.DescriptorId
            AND d.CodeValue = 'Parent in Military'
        ) parentinmilitary ON
            seod.StudentUSI = parentinmilitary.StudentUSI
            AND seod.EducationOrganizationId = parentinmilitary.EducationOrganizationId
    LEFT JOIN (
        SELECT
            seodsc.EducationOrganizationId,
            seodsc.StudentUSI,
            d.CodeValue,
            d.Description
        FROM edfi.StudentEducationOrganizationAssociationStudentCharacteristic seodsc
        INNER JOIN edfi.Descriptor d ON
            seodsc.StudentCharacteristicDescriptorId = d.DescriptorId
            AND d.CodeValue = 'Single Parent'
        ) singleparent ON
            seod.StudentUSI = singleparent.StudentUSI
            AND seod.EducationOrganizationId = singleparent.EducationOrganizationId
    LEFT JOIN (
        SELECT DISTINCT
            spa.StudentUSI,
            spa.ProgramEducationOrganizationId
        FROM edfi.GeneralStudentProgramAssociation spa
        WHERE spa.ProgramName = 'Special Education'
            AND (spa.ENDDate >= @October_1st or spa.ENDDate IS NULL)
            AND spa.BeginDate <= @October_1st) specialeducation ON
        ssa.StudentUSI = specialeducation.StudentUSI
        AND school.LocalEducationAgencyId = specialeducation.ProgramEducationOrganizationId
    LEFT JOIN reporting.GetHomeLanguageCode() homelanguage ON
        seod.StudentUSI = homelanguage.StudentUSI
        AND seod.EducationOrganizationId = homelanguage.EducationOrganizationId
    LEFT JOIN edfi.StudentEducationOrganizationAssociationCohortYear seodcy WITH (NOLOCK) ON
        seodcy.CohortYearTypeDescriptorId = (SELECT TOP 1 DescriptorId FROM edfi.Descriptor WHERE namespace like '%CohortYearType%' AND CodeValue='Ninth grade')
        AND seodcy.StudentUSI = seod.StudentUSI
        AND seodcy.EducationOrganizationId = seod.EducationOrganizationId
    WHERE
        ssa.EntryDate <= @October_1st
        AND (ssa.ExitWithdrawDate >= @October_1st or ssa.ExitWithdrawDate IS NULL)
        AND msid.total_fte >= (CASE WHEN d.CodeValue IN ('HP', 'PK') THEN 0 else 51 END)
        AND s.BirthDate >= (CASE WHEN substring(eoic.IdentificationCode,5,1) = '6' THEN @Age_21 else '1900-01-01' END);
END;
GO
