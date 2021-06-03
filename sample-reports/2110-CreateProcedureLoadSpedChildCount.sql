-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

CREATE OR ALTER PROCEDURE reporting.LoadSpedChildCount
AS
BEGIN
    DECLARE @datayears VARCHAR(8) = '20212022'
    DECLARE @October1 DATE = LEFT(@datayears,4) + '-10-01'
    DECLARE @SCHOOL_YEAR VARCHAR(10) = '2022-06-30'

    DECLARE @MinOrder TABLE
    (
        BeginDate DATE,
        ProgramEducationOrganizationId INT,
        StudentUSI INT,
        CodeValue NVARCHAR(50),
        ShortDescription NVARCHAR(75),
        OrderOfDisability INT,
        INDEX idx_minorder CLUSTERED (BeginDate, ProgramEducationOrganizationId, StudentUSI)
    );

    INSERT INTO @MinOrder (BeginDate, ProgramEducationOrganizationId, StudentUSI, OrderOfDisability)
    SELECT
        BeginDate,
        ProgramEducationOrganizationId,
        StudentUSI,
        OrderOfDisability = MIN(OrderOfDisability)
    FROM reporting.GetAllDisablitites(@October1)
    GROUP BY
        BeginDate,
        ProgramEducationOrganizationId,
        StudentUSI;

    TRUNCATE TABLE reporting.SpecialEducationChildCount;

    INSERT INTO reporting.SpecialEducationChildCount
    SELECT DISTINCT
        Datayears = @datayears
        , s.StudentUniqueId
        , AgencyId = eoic_SchoolofEnrollment.IdentificationCode
        , DistrictOfResidence = LEFT(eoic_DistrictOfResidence.IdentificationCode,7)
        , SchoolOfResidence = ''
        , LastName = s.LastSurName
        , s.FirstName
        , MiddleName = COALESCE(s.MiddleName,'')
        , s.Birthdate
        , Age = (YEAR(@October1) - YEAR(s.Birthdate)) - (
            CASE WHEN MONTH(s.birthdate) < MONTH(@October1) THEN 0
            WHEN MONTH(s.birthdate) = MONTH(@October1) AND DAY(s.Birthdate) = DAY(@october1) THEN 0 ELSE 1 END
            )
        , DisabilityCode = d_disability.CodeValue
        , DisabilityDescription = d_disability.ShortDescription
        , SpeechLanguageTherapyServices = COALESCE(spas.SL,'N')
        , OccupationalTherapyServices = COALESCE(spas.OT,'N')
        , SettingCode = ISNULL(d_Setting.CodeValue,'')
        , SettingDescription = ISNULL(d_Setting.ShortDescription,'')
        , PartBC = ISNULL(d_Program.ShortDescription,'')
        , SpecialEducationPercentage = CAST(CASE WHEN ISNULL(schoolHoursPerWeek,0.0) > 0.0 THEN CONVERT(INT,ROUND(100.0*ISNULL(SpecialEducationHoursPerWeek,0.0)/ISNULL(schoolHoursPerWeek,0.0),0)) ELSE 0.0 END AS INT)
        , AlternateAssessment = CASE ssepae.ToTakeAlternateAssessment WHEN 1 THEN 'Y' ELSE 'N' END
        , race.reporting_race as RaceCode
        , race.reporting_race_desc as RaceDescription
        , GradeLevel = ISNULL(d_gradelevel.CodeValue,'')
        , GenderCode = COALESCE(LEFT(st.ShortDescription,1),'M')
        , GenderDescription = COALESCE(st.ShortDescription,'Male')
        , EnglishLearnerCode = CASE WHEN el.RedesignatedEnglishFluent = 1 THEN '13'
                                WHEN el.englishLearnerParticipation = 1 THEN '11'
                                WHEN el.englishLearnerParticipation = 0 THEN '12'
                                ELSE '14' END
        , EnglishLearnerDescription = CASE WHEN el.RedesignatedEnglishFluent = 1 THEN 'Redesignated English Fluent'
                                        WHEN el.englishLearnerParticipation = 1 THEN 'English Learner Eligible And Participating'
                                        WHEN el.englishLearnerParticipation = 0 THEN 'English Learner Eligible Not Participating'
                                        ELSE 'Not an English Learner' END
        , ISNULL(d_residentstatus.CodeValue,'') as ResidenceStatusCode
        , ISNULL(d_residentstatus.ShortDescription,'') as ResidenceStatusDescription
        , UpdateDate = GETDATE()
    FROM edfi.GeneralStudentProgramAssociation spa WITH(NOLOCK)
    INNER JOIN reporting.GetSpedBeginDate(@October1) msbd ON
        spa.StudentUSI = msbd.StudentUSI
        AND spa.BeginDate = msbd.BeginDate
    INNER JOIN edfi.Student s WITH(NOLOCK) ON
        spa.StudentUSI = s.StudentUSI
    INNER JOIN edfi.StudentSchoolAssociation ssa WITH(NOLOCK) ON
        spa.StudentUSI = ssa.StudentUSI
    INNER JOIN sk.StudentSchoolAssociationExtension ssae WITH(NOLOCK) ON
        ssa.EntryDate = ssae.EntryDate
        AND ssa.SchoolId = ssae.SchoolId
        AND ssa.StudentUSI = ssae.StudentUSI
    LEFT JOIN edfi.Descriptor d_residentstatus ON
        ssa.ResidencyStatusDescriptorId = d_residentstatus.DescriptorId
    INNER JOIN reporting.GetMinimalSchoolReportingId(@October1) msid ON
        ssa.StudentUSI = msid.StudentUSI
        AND ssae.ReportingSchoolId = msid.ReportingSchoolId
    INNER JOIN edfi.School school WITH(NOLOCK) ON
        ssae.ReportingSchoolId = school.SchoolId
        AND spa.ProgramEducationOrganizationId = school.LocalEducationAgencyId
    INNER JOIN edfi.StudentEducationOrganizationAssociation seod WITH(NOLOCK) ON
        ssa.StudentUSI = seod.StudentUSI
        AND school.LocalEducationAgencyId = seod.EducationOrganizationId
        INNER JOIN edfi.EducationOrganization eo_DistrictOfResidence WITH(NOLOCK) ON
        ssae.ResidentLocalEducationAgencyId = eo_DistrictOfResidence.EducationOrganizationId
    INNER JOIN edfi.EducationOrganizationIdentificationCode eoic_DistrictOfResidence ON
        eo_DistrictOfResidence.EducationOrganizationId = eoic_DistrictOfResidence.EducationOrganizationId
    INNER JOIN edfi.EducationOrganization eo_SchoolofEnrollment WITH(NOLOCK) ON
        msid.ReportingSchoolId = eo_SchoolofEnrollment.EducationOrganizationId
    INNER JOIN edfi.EducationOrganizationIdentificationCode eoic_SchoolofEnrollment ON
        eo_SchoolofEnrollment.EducationOrganizationId = eoic_SchoolofEnrollment.EducationOrganizationId
    INNER JOIN edfi.StudentSpecialEducationProgramAssociation ssepa WITH(NOLOCK) ON
        spa.StudentUSI = ssepa.StudentUSI
        AND spa.EducationOrganizationId = ssepa.EducationOrganizationId
        AND spa.ProgramEducationOrganizationId = ssepa.ProgramEducationOrganizationId
        AND spa.BeginDate = ssepa.BeginDate
        AND spa.ProgramTypeDescriptorId = ssepa.ProgramTypeDescriptorId
        AND spa.ProgramName = ssepa.ProgramName
    INNER JOIN sk.StudentSpecialEducationProgramAssociationExtension ssepae WITH(NOLOCK) ON
        ssepa.StudentUSI = ssepae.StudentUSI
        AND ssepa.EducationOrganizationId = ssepae.EducationOrganizationId
        AND ssepa.ProgramEducationOrganizationId = ssepae.ProgramEducationOrganizationId
        AND ssepa.BeginDate = ssepae.BeginDate
        AND ssepa.ProgramTypeDescriptorId = ssepae.ProgramTypeDescriptorId
        AND ssepa.ProgramName = ssepae.ProgramName
    LEFT JOIN edfi.Descriptor d_Setting WITH(NOLOCK) ON
        ssepa.SpecialEducationSettingDescriptorId = d_Setting.DescriptorId
    LEFT JOIN edfi.Descriptor d_Program WITH(NOLOCK) ON
        ssepae.ProgramTypeDescriptorId = d_Program.DescriptorId
    INNER JOIN reporting.GetAllDisablitites(@October1) d_disability ON
        ssepa.BeginDate = d_disability.BeginDate
        AND ssepa.ProgramEducationOrganizationId = d_disability.ProgramEducationOrganizationId
        AND ssepa.StudentUSI = d_disability.StudentUSI
    INNER JOIN @MinOrder m ON
        d_disability.BeginDate = m.BeginDate
        AND d_disability.ProgramEducationOrganizationId = m.ProgramEducationOrganizationId
        AND d_disability.StudentUSI = m.StudentUSI
        AND d_disability.OrderOfDisability = m.OrderOfDisability
    LEFT JOIN reporting.GetSpedProgramServices() spas ON
        spa.BeginDate = spas.BeginDate
        AND spa.ProgramEducationOrganizationId = spas.ProgramEducationOrganizationId
        AND spa.StudentUSI = spas.StudentUSI
    INNER JOIN reporting.GetRaceInformation() race ON
        msid.StudentUSI = race.StudentUSI
        AND seod.EducationOrganizationId = race.EducationOrganizationId
    LEFT JOIN edfi.Descriptor d_gradelevel WITH(NOLOCK) ON
        ssa.EntryGradeLevelDescriptorId = d_gradelevel.DescriptorId
    LEFT JOIN reporting.GetEnglishLearners(@October1) el ON
        spa.StudentUSI = el.StudentUSI
        AND spa.ProgramEducationOrganizationId = el.ProgramEducationOrganizationId
    LEFT JOIN reporting.GetFreeOrReducedLunchInformation(@October1) frl ON
        spa.StudentUSI = frl.StudentUSI
        AND spa.ProgramEducationOrganizationId = frl.ProgramEducationOrganizationId
    LEFT JOIN edfi.Descriptor st WITH(NOLOCK) ON
        seod.SexDescriptorId = st.DescriptorId
    WHERE spa.ProgramName = 'Special Education'
        AND (spa.EndDate IS NULL OR spa.EndDate >= @October1)
        AND spa.BeginDate <= @October1
        AND ssa.EntryDate <= @October1
        AND (ssa.ExitWithdrawDate IS NULL OR ssa.ExitWithdrawDate >= @October1);
END;
GO
