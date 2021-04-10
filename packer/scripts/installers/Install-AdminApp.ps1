# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

# imports
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "../modules"
$installerPath = Join-Path -Path $PSScriptRoot -ChildPath "../EdFi.Suite3.Installer.AdminApp"

Import-Module (Resolve-Path -Path (Join-Path -Path $modulesPath -ChildPath "config-helper.psm1")).Path

# TODO NEED TO FIX THIS IMPORT
# Import-Module (Resolve-Path -Path (Join-Path -Path $installerPath -ChildPath "Install-EdFiOdsWebApi.psm1")).Path

$config = Get-AdminAppConfig

$parameters = @{
    PackageVersion   = $config["PackageVersion"]
    DbConnectionInfo = @{
        Engine                = "SqlServer"
        Server                = "localhost"
        UseIntegratedSecurity = $true
    }
    OdsApiUrl        = ($config["OdsApiUrl"] -f [Environment]::MachineName)
}

Write-Output "Installing AdminApp"

Write-Output @parameters

Set-Location $installerPath

# TODO NEED TO LOOK AT THE install.ps1 script and mimic it here, unless we can call it and pass in the above parameters.
