# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
.SYNOPSIS
    This builds a Starter Kit virtual machine using Packer
.DESCRIPTION
    Configures Packer logging, Defines a network adapter and vm switch,
    compresses assessment PowerShell scripts, and intitiates the packer build.
.EXAMPLE
    PS C:\> .\build-vm.ps1
    Creates a virtual machine image that can be imported using the Hyper-V Manager
.NOTES
    Sets the Packer debug mode and logging path variables at runtime.
#>

param([string] $VMSwitch = "packer-hyperv-iso",
    [string] $ISOUrl = $null,
    [switch] $SkipCreateVMSwitch = $false,
    [switch] $SkipRunPacker = $false)

#Requires -RunAsAdministrator
#Requires -Version 5

#imports
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "scripts/modules"
Import-Module (Resolve-Path -Path (Join-Path -Path $modulesPath -ChildPath "file-helper.psm1")).Path

#global vars
$buildPath = Join-Path -Path $PSScriptRoot -ChildPath "build"
$logsPath = Join-Path -Path $buildPath -ChildPath "logs"

function Invoke-CreateFolders {
    New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
    New-Item -ItemType Directory -Path $logsPath -force | Out-Null
}

function Invoke-PackageDownloads {
    $configPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "build-configuration.json")).Path

    $config = Get-Content $configPath | ConvertFrom-Json

    $url_template = $config.url_template

    $components = @{}
    $config.components.psobject.properties | ForEach-Object { $components[$_.Name] = $_.Value }

    foreach ($key in $components.Keys) {
        $version = $components[$key].version
        $package_name = $components[$key].package_name

        $fullName = (Join-Path -Path $buildPath -ChildPath ( "{0}.zip" -f $package_name ))
        $url = $url_template -f $package_name, $version

        # ignore if already downloaded
        if ((Test-Path -Path $fullName)) {
            Write-Output ("Skipping '{1}' package version '{2}' download of '{0}'" -f $fullName, $package_name, $version)
        }
        else {
            Write-Output ("Downloading '{1}' package version '{2}' to '{0}'" -f $fullName, $package_name, $version)
            Invoke-WebRequest -Uri $url -OutFile $fullName
        }
    }
}

function Set-EnvironmentVariables {
    Set-Item -Path Env:PACKER_LOG -Value 1
    Set-Item -Path Env:PACKER_LOG_PATH -Value (Join-Path -Path (Resolve-Path -Path $logsPath).Path -ChildPath "packer.log")
    Set-Item -Path Env:PACKER_CACHE_DIR -Value (Join-Path -Path (Resolve-Path -Path $buildPath).Path -ChildPath "packer_cache")
}

function Invoke-CreateVMSwitch {
    # Get the first physical network adapter that has an Up status.
    $net_adapter = ((Get-NetAdapter -Name "*" -Physical) | Where-Object { $_.Status -eq 'Up' })[0].Name

    Write-Output "Checking for existence of VM Switch $($VMSwitch)"

    # Note this requires admin privilages
    if ($null -eq (Get-VMSwitch -Name $VMSwitch -ErrorAction SilentlyContinue)) {
        Write-Output "Creating new VM Switch $($VMSwitch)"
        New-VMSwitch -Name $VMSwitch -AllowManagementOS $true -NetAdapterName $net_adapter -MinimumBandwidthMode Weight
    }
}

function Invoke-Packer {
    $packerConfig = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath sea-starter-kit-win2019-eval.pkr.hcl)).Path
    $commonVars = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath common-variables.json)).Path

    #initialize packer and its packages
    & packer init $packerConfig

    # run build vm with packer
    if ( -not $ISOUrl) {
        & packer build -force -var "vm_switch=$($VMSwitch)" "-var-file=$($commonVars)" $packerConfig
    }
    else {
        & packer build -force -var "vm_switch=$($VMSwitch)" -var "iso_url=$($ISOUrl)" "-var-file=$($commonVars)" $packerConfig
    }
}

function Invoke-ValidateDriveSpace($minimumSpace) {
    $drive = ((Get-Location).Path.Split(":")).Get(0)

    $spaceAvailable = (Get-Volume -DriveLetter $drive).SizeRemaining/1GB

    if ($spaceAvailable -lt $minimumSpace) { throw "Not enough space to build the VM. {0} GB is required." -f $minimumSpace }
}


# Validate we have enough disk space
Invoke-ValidateDriveSpace(30)

# Enable Tls2 support
Set-TLS12Support

# Create Build and Distribution Folders
Invoke-CreateFolders

#download packages and push to to build folder
Invoke-PackageDownloads

# Compress our PowerShell to a zip archive
Compress-Archive -Path (Join-Path -Path $PSScriptRoot -ChildPath "scripts") -Destination  (Join-Path -Path $buildPath -ChildPath "sea-starter-kit.zip") -Force

# Configure runtime environment vars
Set-EnvironmentVariables

# Configure VMSwitch
if (-not ($SkipCreateVMSwitch)) { Invoke-CreateVMSwitch }
else { Write-Output "Skipping VM Switch validation and creation." }

# Kick off the packer build with the force to override prior builds
if (-not ($SkipRunPacker)) { Invoke-Packer }
else { Write-Output "Skipping Packer Execution" }
