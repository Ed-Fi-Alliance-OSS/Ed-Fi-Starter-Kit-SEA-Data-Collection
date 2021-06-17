# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

Import-Module SqlServer

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -Query "EXEC reporting.LoadStudentFallMembership" -OutputSqlErrors $true

Invoke-Sqlcmd -Database "EdFi_Ods_2022" -Query "EXEC reporting.LoadSpedChildCount" -OutputSqlErrors $true

$path = "C:/Users/Public/Desktop/Reports/"
if (-not (Test-path $path)) {
    New-Item -Path "C:/Users/Public/Desktop/" -Name Reports -ItemType directory
}

if (-not (Get-InstalledModule | Where-Object -Property Name -eq "ImportExcel")) {
    Install-Module -Force -Scope CurrentUser -Name ImportExcel
}

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "./3100-MembershipCountByGradeRaceGenderReport.sql" | Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/MembershipCountByGradeRaceGenderReport.xlsx" -WorksheetName "Student Count" -AutoSize

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "./3110-MembershipCountByGradeReport.sql" | Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/MembershipCountByGradeReport.xlsx" -WorksheetName "Student Count" -AutoSize

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "./3120-SpecialEducationByAgeReport.sql" | Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/SpecialEducationByAgeReport.xlsx" -WorksheetName "Student Count" -AutoSize

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "./3130-SpecialEducationPrimaryDisabilityReport.sql" | Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/SpecialEducationPrimaryDisabilityReport.xlsx" -WorksheetName "Student Count" -AutoSize

$SQLresults = Invoke-Sqlcmd -Database "EdFi_Ods_2022" -InputFile "./3140-SpecialEducationSettingReport.sql" | Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors

$SQLresults | Export-Excel -Path "C:/Users/Public/Desktop/Reports/SpecialEducationSettingReport.xlsx" -WorksheetName "Student Count" -AutoSize

