-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

CREATE OR ALTER FUNCTION reporting.GetFullTimeEquivalency
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    LocalEducationAgencyId INT,
    StudentUSI INT,
    Total_FTE INT,
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

CREATE OR ALTER FUNCTION reporting.GetMaxFullTimeEquivalency
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    LocalEducationAgencyId INT,
    StudentUSI INT,
    Total_FTE INT,
    Max_FTE INT,
    INDEX idx_maxfte CLUSTERED(LocalEducationAgencyId, StudentUSI)
)
AS
BEGIN
    INSERT INTO @ResultTable (StudentUSI, LocalEducationAgencyId, Total_FTE, Max_FTE)
    SELECT
        ssa.StudentUSI,
        med.LocalEducationAgencyId,
        med.Total_FTE,
        Max_FTE = max(ssa.FullTimeEquivalency)
    FROM edfi.StudentSchoolAssociation ssa
    INNER JOIN sk.StudentSchoolAssociationExtension ssae ON
        ssa.StudentUSI = ssae.StudentUSI
        AND ssa.SchoolId = ssae.SchoolId
        AND ssa.EntryDate = ssae.EntryDate
    INNER JOIN edfi.School sch_Reporting ON
        ssae.ReportingSchoolId = sch_Reporting.SchoolId
    INNER JOIN reporting.GetFullTimeEquivalency(@searchDate) med ON
        ssa.StudentUSI = med.StudentUSI
        AND sch_Reporting.LocalEducationAgencyId = med.LocalEducationAgencyId
    INNER JOIN edfi.Descriptor d_gradelevel ON
        ssa.EntryGradeLevelDescriptorId = d_gradelevel.DescriptorId
    WHERE
        med.total_fte >= 0.51
        AND (ssa.ExitWithdrawDate IS NULL OR ssa.ExitWithdrawDate >= @searchDate)
        AND ssa.EntryDate <= @searchDate
    GROUP BY
        ssa.StudentUSI,
        med.LocalEducationAgencyId,
        total_fte;

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetMinimalSchoolReportingId
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    LocalEducationAgencyId INT,
    StudentUSI INT,
    Total_FTE INT,
    ReportingSchoolId INT
    INDEX idx_minSchoolId CLUSTERED (LocalEducationAgencyId, StudentUSI)
)
AS
BEGIN
    INSERT INTO @ResultTable (StudentUSI, LocalEducationAgencyId, Total_FTE, ReportingSchoolId)
    SELECT
        ssa.StudentUSI,
        fte.LocalEducationAgencyId,
        Total_FTE,
        ReportingSchoolId = MIN(ssae.ReportingSchoolId)
    FROM edfi.StudentSchoolAssociation ssa
    INNER JOIN sk.StudentSchoolAssociationExtension ssae ON
        ssa.StudentUSI = ssae.StudentUSI
        AND ssa.SchoolId = ssae.SchoolId
        AND ssa.EntryDate = ssae.EntryDate
    INNER JOIN edfi.School sch_Reporting ON
        ssae.ReportingSchoolId = sch_Reporting.SchoolId
    INNER JOIN reporting.GetMaxFullTimeEquivalency(@searchDate) fte ON
        ssa.StudentUSI = fte.StudentUSI
        AND sch_Reporting.LocalEducationAgencyId = fte.LocalEducationAgencyId
        AND ssa.FullTimeEquivalency = fte.Max_FTE
    WHERE
        (ssa.ExitWithdrawDate IS NULL or ssa.ExitWithdrawDate >= @searchDate)
        AND ssa.EntryDate <= @searchDate
    GROUP BY ssa.StudentUSI, fte.LocalEducationAgencyId, total_fte;

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetHomeLanguageCode
(
)
RETURNS @ResultTable TABLE
(
    StudentUSI INT,
    EducationOrganizationId INT,
    CodeValue NVARCHAR(50),
    Description NVARCHAR(1024),
    INDEX idx_homelanguage CLUSTERED (StudentUSI, EducationOrganizationId)
)
AS
BEGIN
    INSERT INTO @ResultTable (StudentUSI, EducationOrganizationId, CodeValue, Description)
    SELECT
        seod.StudentUSI,
        seod.EducationOrganizationId,
        d.CodeValue,
        d.Description
    FROM edfi.StudentEducationOrganizationAssociation seod WITH (NOLOCK)
    INNER JOIN edfi.StudentEducationOrganizationAssociationLanguage seodl WITH (NOLOCK) ON
        seod.StudentUSI = seodl.StudentUSI
        AND seod.EducationOrganizationId = seodl.EducationOrganizationId
    INNER JOIN edfi.StudentEducationOrganizationAssociationLanguageUse seodlu WITH (NOLOCK) ON
        seodl.StudentUSI = seodlu.StudentUSI
        AND seodl.EducationOrganizationId = seodlu.EducationOrganizationId
        AND seodl.LanguageDescriptorId = seodlu.LanguageDescriptorId
    INNER JOIN edfi.Descriptor d WITH (NOLOCK) ON
        seodl.LanguageDescriptorId = d.DescriptorId
    INNER JOIN edfi.Descriptor lut WITH (NOLOCK) on
        seodlu.LanguageUseDescriptorId = lut.DescriptorId
    WHERE lut.Description = 'Dominant language';

    INSERT INTO @ResultTable (StudentUSI, EducationOrganizationId, CodeValue, Description)
    SELECT
        seod.StudentUSI,
        seod.EducationOrganizationId,
        d.CodeValue,
        d.Description
    FROM edfi.StudentEducationOrganizationAssociation seod WITH (NOLOCK)
    INNER JOIN edfi.StudentEducationOrganizationAssociationLanguage seodl WITH (NOLOCK) ON
        seod.StudentUSI = seodl.StudentUSI
        AND seod.EducationOrganizationId = seodl.EducationOrganizationId
    INNER JOIN edfi.StudentEducationOrganizationAssociationLanguageUse seodlu WITH (NOLOCK) ON
        seodl.StudentUSI = seodlu.StudentUSI
        AND seodl.EducationOrganizationId = seodlu.EducationOrganizationId
        AND seodl.LanguageDescriptorId = seodlu.LanguageDescriptorId
    INNER JOIN edfi.Descriptor d WITH (NOLOCK) ON
        seodl.LanguageDescriptorId = d.DescriptorId
    INNER JOIN edfi.Descriptor lut WITH (NOLOCK) ON
        seodlu.LanguageUseDescriptorId = lut.DescriptorId
    WHERE
        lut.Description = 'Home language'
        AND CAST(seod.StudentUSI AS VARCHAR(20)) + CAST(seod.EducationOrganizationId AS VARCHAR(20)) NOT IN
            (SELECT CAST(StudentUSI as VARCHAR(20)) + CAST(EducationOrganizationId as VARCHAR(20)) FROM @ResultTable);

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetRaceInformation
(
)
RETURNS @ResultTable TABLE
(
    StudentUSI int,
    EducationOrganizationId int,
    race_1_code NVARCHAR(50),
    race_1_desc NVARCHAR(1024),
    race_2_code NVARCHAR(50),
    race_2_desc NVARCHAR(1024),
    race_3_code NVARCHAR(50),
    race_3_desc NVARCHAR(1024),
    race_4_code NVARCHAR(50),
    race_4_desc NVARCHAR(1024),
    race_5_code NVARCHAR(50),
    race_5_desc NVARCHAR(1024),
    hispanic_indicator NVARCHAR(1),
    reporting_race NVARCHAR(50),
    reporting_race_desc NVARCHAR(1024)
    INDEX idx_raceInformation CLUSTERED (EducationOrganizationId, StudentUSI)
)
AS
BEGIN

    DECLARE @All TABLE
    (
        StudentUSI INT,
        EducationOrganizationId INT,
        RaceCode NVARCHAR(50),
        Deleted BIT
    );

    INSERT INTO @All (StudentUSI, EducationOrganizationId, RaceCode, Deleted)
    SELECT
        sr.StudentUSI,
        sr.EducationOrganizationId,
        r.CodeValue RaceCode,
        0 as Deleted
    FROM edfi.StudentEducationOrganizationAssociationRace sr WITH (NOLOCK)
    INNER JOIN edfi.Descriptor r WITH (NOLOCK)
    on r.DescriptorId = sr.RaceDescriptorId;

    INSERT INTO @ResultTable (StudentUSI, EducationOrganizationId, race_1_code)
    SELECT
        StudentUSI,
        EducationOrganizationId, MIN(RaceCode)
    FROM @All
    GROUP BY StudentUSI, EducationOrganizationId;

    UPDATE al
    SET Deleted = 1
    FROM @All al
    INNER JOIN @ResultTable rl ON
        al.StudentUSI = rl.StudentUSI
        AND al.EducationOrganizationId = rl.EducationOrganizationId
        AND al.RaceCode = rl.race_1_code;

    UPDATE @ResultTable
    SET race_2_code = al.RaceCode
    FROM @ResultTable rl
    INNER JOIN @All al ON
        rl.StudentUSI = al.StudentUSI
        AND rl.EducationOrganizationId = al.EducationOrganizationId
        AND al.Deleted <> 1;

    UPDATE al
    SET Deleted = 1
    FROM @All al
    INNER JOIN @ResultTable rl ON
        al.StudentUSI = rl.StudentUSI
        AND al.EducationOrganizationId = rl.EducationOrganizationId
        AND al.RaceCode = rl.race_2_code;

    UPDATE @ResultTable
    SET race_3_code = al.RaceCode
    FROM @ResultTable rl
    INNER JOIN @All al ON
        rl.StudentUSI = al.StudentUSI
        AND rl.EducationOrganizationId = al.EducationOrganizationId
        AND al.Deleted <> 1;

    UPDATE al
    SET Deleted = 1
    FROM @All al
    INNER JOIN @ResultTable rl ON
        al.StudentUSI = rl.StudentUSI
        AND al.EducationOrganizationId = rl.EducationOrganizationId
        AND al.RaceCode = rl.race_3_code;

    UPDATE @ResultTable
    SET race_4_code = al.RaceCode
    FROM @ResultTable rl
    INNER JOIN @All al ON
        rl.StudentUSI = al.StudentUSI
        AND rl.EducationOrganizationId = al.EducationOrganizationId
        AND al.Deleted <> 1;

    UPDATE al
    SET Deleted = 1
    FROM @All al
    INNER JOIN @ResultTable rl ON
        al.StudentUSI = rl.StudentUSI
        AND al.EducationOrganizationId = rl.EducationOrganizationId
        AND al.RaceCode = rl.race_4_code;

    UPDATE @ResultTable
    SET race_5_code = al.RaceCode
    FROM @ResultTable rl
    INNER JOIN @All al ON
        rl.StudentUSI = al.StudentUSI
        AND rl.EducationOrganizationId = al.EducationOrganizationId
        AND al.Deleted <> 1;

    UPDATE al
    SET Deleted = 1
    FROM @All al
    INNER JOIN @ResultTable rl ON
        al.StudentUSI = rl.StudentUSI
        AND al.EducationOrganizationId = rl.EducationOrganizationId
        AND al.RaceCode = rl.race_5_code;

    UPDATE @ResultTable
    SET hispanic_indicator = CASE seod.hispaniclatinoethnicity WHEN 1 THEN 'Y' ELSE 'N' END
    FROM @ResultTable rl
    INNER JOIN edfi.StudentEducationOrganizationAssociation seod on
        rl.EducationOrganizationId = seod.EducationOrganizationId
        AND rl.studentusi = seod.studentusi;

    UPDATE @ResultTable
    SET reporting_race =
        CASE
            WHEN hispanic_indicator = 'Y' THEN 'Hispanic'
            WHEN race_2_code IS NOT NULL THEN 'Multiple'
            ELSE race_1_code
        END;

    UPDATE @ResultTable
    SET race_1_desc = rcl.Description
    FROM @ResultTable r
    INNER JOIN edfi.Descriptor rcl ON r.race_1_code = rcl.CodeValue;

    UPDATE @ResultTable
    SET race_2_desc = rcl.Description
    FROM @ResultTable r
    INNER JOIN edfi.Descriptor rcl ON
        r.race_2_code = rcl.CodeValue;

    UPDATE @ResultTable
    SET race_3_desc = rcl.Description
    FROM @ResultTable r
    INNER JOIN edfi.Descriptor rcl ON
        r.race_3_code = rcl.CodeValue;

    UPDATE @ResultTable
    SET race_4_desc = rcl.Description
    FROM @ResultTable r
    INNER JOIN edfi.Descriptor rcl ON
        r.race_4_code = rcl.CodeValue;

    UPDATE @ResultTable
    SET race_5_desc = rcl.Description
    FROM @ResultTable r
    INNER JOIN edfi.Descriptor rcl ON
        r.race_5_code = rcl.CodeValue;

    UPDATE @ResultTable
    SET reporting_race_desc = rcl.Description
    FROM @ResultTable r
    INNER JOIN edfi.Descriptor rcl ON
        r.reporting_race = rcl.CodeValue;

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetFreeOrReducedLunchInformation
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    StudentUSI INT,
    ProgramEducationOrganizationId INT,
    ShortDescription NVARCHAR(75),
    CodeValue NVARCHAR(50),
    INDEX idx_FreeOrReducedLunch CLUSTERED (ProgramEducationOrganizationId, StudentUSI)
)
AS
BEGIN
    INSERT INTO @ResultTable (StudentUSI, ProgramEducationOrganizationId, ShortDescription, CodeValue)
    SELECT DISTINCT
        gspa.StudentUSI,
        gspa.ProgramEducationOrganizationId,
        dfsp.ShortDescription,
        dfsp.CodeValue
    FROM edfi.GeneralStudentProgramAssociation gspa WITH (NOLOCK)
    INNER JOIN edfi.EducationOrganization eo ON
        gspa.ProgramEducationOrganizationId = eo.EducationOrganizationId
    INNER JOIN edfi.StudentSchoolFoodServiceProgramAssociation fspa WITH (NOLOCK) ON
        gspa.BeginDate = fspa.BeginDate
        AND gspa.ProgramEducationOrganizationId = fspa.ProgramEducationOrganizationId
        AND gspa.ProgramName = fspa.ProgramName
        AND gspa.StudentUSI = fspa.StudentUSI
    INNER JOIN edfi.StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService fspas WITH (NOLOCK) ON
        fspa.BeginDate = fspas.BeginDate
        AND fspa.ProgramEducationOrganizationId = fspas.ProgramEducationOrganizationId
        AND fspa.ProgramName = fspas.ProgramName
        AND fspa.StudentUSI = fspas.StudentUSI
    INNER JOIN edfi.Descriptor dFSP WITH (NOLOCK) ON
        fspas.SchoolFoodServiceProgramServiceDescriptorId = dFSP.DescriptorId
    INNER JOIN (
            SELECT StudentUSI, ProgramEducationOrganizationId, MAX(BeginDate) as BeginDate
            FROM edfi.GeneralStudentProgramAssociation WITH (NOLOCK)
            WHERE
                ProgramName = 'School Food Service'
                AND BeginDate <= @searchDate
                AND (EndDate IS NULL OR EndDate >= @searchDate)
            GROUP BY
                StudentUSI,
                ProgramEducationOrganizationId
        ) mbd ON
        gspa.StudentUSI = mbd.StudentUSI
        AND gspa.ProgramEducationOrganizationId = mbd.ProgramEducationOrganizationId
        AND gspa.BeginDate = mbd.BeginDate;

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetEnglishLearners
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    StudentUSI INT,
    ProgramEducationOrganizationId INT,
    EnglishLearnerParticipation BIT,
    RedesignatedEnglishFluent BIT,
    INDEX idx_EnglishLearners CLUSTERED (ProgramEducationOrganizationId, StudentUSI)
)
AS
BEGIN
    INSERT INTO @ResultTable (StudentUSI, ProgramEducationOrganizationId, EnglishLearnerParticipation, RedesignatedEnglishFluent)
    SELECT DISTINCT
        gspa.StudentUSI,
        gspa.ProgramEducationOrganizationId,
        slipa.EnglishLearnerParticipation,
        slipae.RedesignatedEnglishFluent
    FROM edfi.GeneralStudentProgramAssociation gspa WITH (NOLOCK)
    INNER JOIN edfi.EducationOrganization eo ON
        gspa.ProgramEducationOrganizationId = eo.EducationOrganizationId
    INNER JOIN edfi.StudentLanguageInstructionProgramAssociation slipa WITH (NOLOCK) ON
        gspa.BeginDate = slipa.BeginDate
        AND gspa.ProgramEducationOrganizationId = slipa.ProgramEducationOrganizationId
        AND gspa.ProgramName = slipa.ProgramName
        AND gspa.StudentUSI = slipa.StudentUSI
    INNER JOIN sk.StudentLanguageInstructionProgramAssociationExtension slipae WITH (NOLOCK) ON
        slipa.BeginDate = slipae.BeginDate
        AND slipa.ProgramEducationOrganizationId = slipae.ProgramEducationOrganizationId
        AND slipa.ProgramName = slipae.ProgramName
        AND slipa.StudentUSI = slipae.StudentUSI
    INNER JOIN
        (
            SELECT StudentUSI, ProgramEducationOrganizationId, MAX(BeginDate) as BeginDate
            FROM edfi.GeneralStudentProgramAssociation WITH (NOLOCK)
            WHERE
                ProgramName = 'English as a Second Language (ESL)'
                AND BeginDate <= @searchDate AND (ENDDate IS NULL or ENDDate >= @searchDate)
            GROUP BY StudentUSI, ProgramEducationOrganizationId
        ) mbd ON
        gspa.StudentUSI = mbd.StudentUSI
        AND gspa.ProgramEducationOrganizationId = mbd.ProgramEducationOrganizationId
        AND gspa.BeginDate = mbd.BeginDate;

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetSpedBeginDate
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    StudentUSI INT,
    ProgramEducationOrganizationId INT,
    BeginDate DATE,
    INDEX idx_SpedBeginDate CLUSTERED (StudentUSI, ProgramEducationOrganizationId)
)
AS
BEGIN
    INSERT INTO @ResultTable (StudentUSI, ProgramEducationOrganizationId, BeginDate)
    SELECT
        gspa.StudentUSI,
        gspa.ProgramEducationOrganizationId,
        BeginDate = MIN(gspa.BeginDate)
    FROM edfi.GeneralStudentProgramAssociation gspa WITH(NOLOCK)
    INNER JOIN edfi.StudentSpecialEducationProgramAssociation ssepa WITH(NOLOCK) ON
        gspa.StudentUSI = ssepa.StudentUSI
        AND gspa.EducationOrganizationId = ssepa.EducationOrganizationId
        AND gspa.ProgramEducationOrganizationId = ssepa.ProgramEducationOrganizationId
        AND gspa.BeginDate = ssepa.BeginDate
        AND gspa.ProgramTypeDescriptorId = ssepa.ProgramTypeDescriptorId
        AND gspa.ProgramName = ssepa.ProgramName
    WHERE gspa.ProgramName = 'Special Education'
        AND (gspa.EndDate IS NULL OR gspa.EndDate >= @searchDate)
        AND gspa.BeginDate <= @searchDate
    GROUP BY
        gspa.StudentUSI,
        gspa.ProgramEducationOrganizationId

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetAllDisablitites
(
    @searchDate DATE
)
RETURNS @ResultTable TABLE
(
    BeginDate DATE,
    ProgramEducationOrganizationId INT,
    StudentUSI INT,
    CodeValue NVARCHAR(50),
    ShortDescription NVARCHAR(75),
    OrderOfDisability INT,
    INDEX idx_allDisabilities CLUSTERED (BeginDate, ProgramEducationOrganizationId, StudentUSI, CodeValue, ShortDescription, OrderOfDisability)
)
AS
BEGIN
    INSERT INTO @ResultTable (BeginDate, ProgramEducationOrganizationId, StudentUSI, CodeValue, ShortDescription, OrderOfDisability)
    SELECT DISTINCT
        ssepad.BeginDate,
        ssepad.ProgramEducationOrganizationId,
        ssepad.StudentUSI,
        d.CodeValue,
        d.ShortDescription,
        OrderOfDisability = COALESCE(ssepad.OrderOfDisability,1)
    FROM edfi.StudentSpecialEducationProgramAssociationDisability ssepad WITH(NOLOCK)
    INNER JOIN edfi.Descriptor d WITH(NOLOCK) ON
        ssepad.DisabilityDescriptorId = d.DescriptorId
    INNER JOIN reporting.GetSpedBeginDate(@searchDate) smbd ON
        ssepad.studentusi = smbd.studentusi
        AND ssepad.ProgramEducationOrganizationId = smbd.ProgramEducationOrganizationId
        AND ssepad.BeginDate = smbd.BeginDate

    RETURN;
END;
GO

CREATE OR ALTER FUNCTION reporting.GetSpedProgramServices
(
)
RETURNS @ResultTable TABLE
(
    BeginDate DATE,
    StudentUSI INT,
    ProgramEducationOrganizationId INT,
    OT NVARCHAR(1),
    SL NVARCHAR(1),
    INDEX idx_Services (BeginDate, StudentUSI, ProgramEducationOrganizationId)
)
AS
BEGIN
    INSERT INTO @ResultTable (BeginDate, StudentUSI, ProgramEducationOrganizationId, OT, SL)
    SELECT
        spas.BeginDate,
        spas.StudentUSI,
        spas.ProgramEducationOrganizationId,
        OT = MAX(CASE d.CodeValue WHEN 'Occupational And Physical Therapy' then 'Y' else 'N' END),
        SL = MAX(CASE d.CodeValue WHEN 'Speech-Language And Audiology Services' THEN 'Y' ELSE 'N' END)
    FROM edfi.StudentSpecialEducationProgramAssociationSpecialEducationProgramService spas WITH (NOLOCK)
    LEFT JOIN edfi.Descriptor d WITH(NOLOCK) ON
        spas.SpecialEducationProgramServiceDescriptorId = d.DescriptorId
        AND d.CodeValue in ('Speech-Language And Audiology Services', 'Occupational And Physical Therapy')
    WHERE
        spas.ProgramName = 'Special Education'
    GROUP BY
        StudentUSI,
        ProgramEducationOrganizationId,
        BeginDate;

    RETURN;
END;
GO
