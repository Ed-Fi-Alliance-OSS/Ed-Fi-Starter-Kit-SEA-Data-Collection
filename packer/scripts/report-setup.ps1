# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

Import-Module SqlServer

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "C:/sample-reports/2000-CreateSchemas.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "C:/sample-reports/2010-CreateTables.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "C:/sample-reports/2050-CreateTableValueFunctions.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "C:/sample-reports/2100-CreateProcedureLoadStudentFallMembership.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "C:/sample-reports/2110-CreateProcedureLoadSpedChildCount.sql"