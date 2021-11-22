# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#imports
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "C:/Starter-Kit-SEA-Modernization/packer/scripts/modules"
Import-Module (Resolve-Path -Path (Join-Path -Path $modulesPath -ChildPath "file-helper.psm1")).Path
Import-Module (Resolve-Path -Path (Join-Path -Path $modulesPath -ChildPath "packer-helper.psm1")).Path -Force

#global vars
$buildPath = Join-Path -Path $PSScriptRoot -ChildPath "C:/"
$configPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "C:/Starter-Kit-SEA-Modernization/packer/build-configuration.json")).Path

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://dot.net/v1/dotnet-install.ps1'))) -Channel 3.1 -InstallDir 'C:/Program Files/dotnet'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'Plugin:Folder' '../../Plugin'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'Plugin:Folder' '../../Plugin'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'Plugin:Scripts:0' 'sk'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'Plugin:Scripts:0' 'sk'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'ApiSettings:PopulatedTemplateScript' 'sampledata'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'ApiSettings:PopulatedTemplateScript' 'sampledata'
Invoke-PackageDownloads -ConfigPath $configPath -BuildPath $buildPath
Copy-Item -Path C:/Starter-Kit-SEA-Modernization/packer/scripts/sampledata.ps1 C:/Ed-Fi-ODS-Implementation/DatabaseTemplate/Scripts/
. C:/Ed-Fi-ODS-Implementation/Initialize-PowershellForDevelopment.ps1
Initialize-DevelopmentEnvironment -RunDotnetTest -RunSdkGen -RunSmokeTest
