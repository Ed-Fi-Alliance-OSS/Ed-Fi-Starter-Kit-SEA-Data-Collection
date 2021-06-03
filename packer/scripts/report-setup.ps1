# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

Import-Module SqlServer

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile ".\Artifacts\MsSql\Structure\Ods\2000-CreateSchemas.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile ".\Artifacts\MsSql\Structure\Ods\2010-CreateTables.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile ".\Artifacts\MsSql\Structure\Ods\2050-CreateTableValueFunctions.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile ".\Artifacts\MsSql\Structure\Ods\2100-CreateProcedureLoadStudentFallMembership.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile ".\Artifacts\MsSql\Structure\Ods\2110-CreateProcedureLoadSpedChildCount.sql"

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -Query "EXEC reporting.LoadStudentFallMembership" -OutputSqlErrors $true

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -Query "EXEC reporting.LoadSpedChildCount" -OutputSqlErrors $true

New-Item -Path "C:/Users/Public/Desktop/" -Name Reports -ItemType directory

if (-not (Get-InstalledModule | Where-Object -Property Name -eq "ImportExcel")) {
    Install-Module -Force -Scope CurrentUser -Name ImportExcel
}

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile ".\Artifacts\MsSql\Structure\Ods\3100-StudentFallMembershipReport.sql" | Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/StudentFallMembershipReport.xlsx" -WorksheetName "Membership" -AutoSize

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -Query "SELECT * FROM [EdFi_Ods_2022].[reporting].[SpecialEducationChildCount]" -OutputSqlErrors $true

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/SpecialEducationChildCount.xlsx" -WorksheetName "2021-2022" -AutoSize -Show


