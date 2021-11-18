# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://dot.net/v1/dotnet-install.ps1'))) -Channel 3.1 -InstallDir 'C:/Program Files/dotnet'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'Plugin:Folder' '../../Plugin'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'Plugin:Scripts:0' 'sk'
. C:/Ed-Fi-ODS-Implementation/Initialize-PowershellForDevelopment.ps1
Initialize-DevelopmentEnvironment -RunDotnetTest -RunSdkGen -RunSmokeTest
