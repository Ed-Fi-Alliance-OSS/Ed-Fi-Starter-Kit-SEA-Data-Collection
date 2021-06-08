-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.


-- =========================================================================================
-- Query to generate SEA Starter Kit - Special Education by Primary Disability = Student Count report
-- =========================================================================================
SELECT [DisabilityCode] AS [Primary Disability]
    , [2021-2022]
    , [2020-2021]
    , [2019-2020]
    , [2018-2019]
    , [2017-2018]
FROM  
(
    SELECT DISTINCT StudentUniqueId, Datayears, DisabilityCode 
    FROM [EdFi_Ods_2022].[reporting].[SpecialEducationChildCount]
) AS SourceTable  
PIVOT  
(  
    COUNT(StudentUniqueId)  
    FOR Datayears IN ([2021-2022], [2020-2021], [2019-2020], [2018-2019], [2017-2018])  
) AS PivotTable
ORDER BY [DisabilityCode];
