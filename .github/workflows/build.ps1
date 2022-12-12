# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.
[CmdLetBinding()]
param(
    [bool]
    $SkipTests = $false
)

$ErrorActionPreference = 'Stop'

$PSVersionTable

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($env:GITHUB_ACTIONS) {
    $basePath = $env:GITHUB_WORKSPACE
    $version = "1.0.$env:GITHUB_RUN_NUMBER"

    # EdFi.Ods.WebApi
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'ConnectionStrings:EdFi_Ods'      'Server=(LocalDB)\\MSSQLLocalDB; Database=EdFi_{0}; Connection Timeout=30; Trusted_Connection=True; Application Name=EdFi.Ods.WebApi;'
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'ConnectionStrings:EdFi_Admin'    'Server=(LocalDB)\\MSSQLLocalDB; Database=EdFi_Admin; Connection Timeout=30; Trusted_Connection=True; Application Name=EdFi.Ods.WebApi;'
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'ConnectionStrings:EdFi_Security' 'Server=(LocalDB)\\MSSQLLocalDB; Database=EdFi_Security; Connection Timeout=30; Trusted_Connection=True; Persist Security Info=True; Application Name=EdFi.Ods.WebApi;'
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'ConnectionStrings:EdFi_Master'   'Server=(LocalDB)\\MSSQLLocalDB; Database=master; Connection Timeout=30; Trusted_Connection=True; Application Name=EdFi.Ods.WebApi;'

    # EdFi.Ods.Api.IntegrationTestHarness
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'ConnectionStrings:EdFi_Ods'      'Server=(LocalDB)\MSSQLLocalDB; Database=EdFi_Ods_Populated_Template_Test; Connection Timeout=30; Trusted_Connection=True; Application Name=EdFi.Ods.Api.IntegrationTestHarness'
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'ConnectionStrings:EdFi_Admin'    'Server=(LocalDB)\MSSQLLocalDB; Database=EdFi_Admin; Connection Timeout=30; Trusted_Connection=True; Application Name=EdFi.Ods.Api.IntegrationTestHarness'
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'ConnectionStrings:EdFi_Security' 'Server=(LocalDB)\MSSQLLocalDB; Database=EdFi_Security; Connection Timeout=30; Trusted_Connection=True; Persist Security Info=True; Application Name=EdFi.Ods.Api.IntegrationTestHarness'
    dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'ConnectionStrings:EdFi_Master'   'Server=(LocalDB)\MSSQLLocalDB; Database=master; Connection Timeout=30; Trusted_Connection=True; Application Name=EdFi.Ods.Api.IntegrationTestHarness'
    
    Write-Host "Starting MSSQLLocalDB"
    SQLLocalDB start MSSQLLocalDB
} else {
    $basePath = (Resolve-Path "$PSScriptRoot/../../../")
    $version = "0.0.0"
}

# EdFi.Ods.WebApi
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'Plugin:Folder' '../../Plugin'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'Plugin:Scripts:0' 'tpdm'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ec 'Plugin:Scripts:1' 'sk'

# EdFi.Ods.Api.IntegrationTestHarness
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'Plugin:Folder' '../../Plugin'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'Plugin:Scripts:0' 'tpdm'
dotnet user-secrets set --id f1506d66-289c-44cb-a2e2-80411cc690ed 'Plugin:Scripts:1' 'sk'   

dotnet nuget add source $env:AZURE_ARTIFACTS_FEED_URL --name EdFiAzureArtifacts

(Get-ChildItem $basePath).FullName
. $basePath/Ed-Fi-ODS-Implementation/Initialize-PowershellForDevelopment.ps1

$skExtensionPath = "$basePath/Starter-Kit-SEA-Modernization/sample-extension/EdFi.Ods.Extensions.Sk/"
Invoke-CodeGen -Engine SQLServer -ExtensionPaths $skExtensionPath
& dotnet build $skExtensionPath --configuration release
& dotnet test $skExtensionPath --no-restore --verbosity normal

$nuget = Install-NuGetCli (Get-ToolsPath)
& $nuget 
$packagesPath = "$basePath/Starter-Kit-SEA-Modernization/.github/workflows/packages/"
& $nuget pack $skExtensionPath/EdFi.Ods.Extensions.Sk.nuspec `
    -OutputDirectory $packagesPath `
    -Version $version `
    -Properties configuration=release `
    -NoPackageAnalysis `
    -NoDefaultExcludes
Copy-Item $packagesPath/EdFi.Suite3.Ods.Extensions.Sk.$version.nupkg $packagesPath/EdFi.Ods.Extensions.Sk.zip
Expand-Archive $packagesPath/EdFi.Ods.Extensions.Sk.zip $basePath/Ed-Fi-ODS-Implementation/Plugin/EdFi.Ods.Extensions.Sk/ -Force

# When building for the purpose CodeQL execution, running tests are not necessary.  
# Additionally, when CodeQL has been initialized, attempting to run -RunDotnetTest fails.
if ($SkipTests) {
    Initialize-DevelopmentEnvironment -RunSdkGen
}
else{
    Initialize-DevelopmentEnvironment -RunDotnetTest -RunSdkGen -RunSmokeTest
}

# & dotnet nuget push $packagesPath/EdFi.Ods.Extensions.Sk.$version.nupkg --api-key AzureArtifacts --skip-duplicate
