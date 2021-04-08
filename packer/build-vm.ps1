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

param([string] $vmSwitch = "packer-hyperv-iso", [string] $isoUrl)

#Requires -RunAsAdministrator
#Requires -Version 5

# Create Build and Distribution Folders
$buildPath = Join-Path -Path $PSScriptRoot -ChildPath "build"
$logsPath = Join-Path -Path $buildPath -ChildPath "logs"
$distPath = Join-Path -Path $PSScriptRoot -ChildPath "dist"

New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
New-Item -ItemType Directory -Path $logsPath -force | Out-Null
New-Item -ItemType Directory -Path $distPath -force | Out-Null

# Configure runtime environment vars
Set-Item -Path Env:PACKER_LOG -Value 1
Set-Item -Path Env:PACKER_LOG_PATH -Value (Join-Path -Path (Resolve-Path -Path $logsPath).Path -ChildPath "packer.log")
Set-Item -Path Env:PACKER_CACHE_DIR -Value (Join-Path -Path (Resolve-Path -Path $buildPath).Path -ChildPath "packer_cache")

# Get the first physical network adapter that has an Up status.
$net_adapter = ((Get-NetAdapter -Name "*" -Physical) | ? { $_.Status -eq 'Up' })[0].Name

Write-Output "Checking for existence of VM Switch $($vmSwitch)"

# Note this requires admin privilages
if ($null -eq (Get-VMSwitch -Name $vmSwitch -ErrorAction SilentlyContinue)) {
    Write-Output "Creating new VM Switch $($vmSwitch)"
    New-VMSwitch -Name $vmSwitch -AllowManagementOS $true -NetAdapterName $net_adapter -MinimumBandwidthMode Weight
}

# Compress our PowerShell to a zip archive
Compress-Archive -Path (Join-Path -Path $PSScriptRoot -ChildPath "scripts") -Destination  (Join-Path -Path $buildPath -ChildPath "sea-starter-kit.zip") -Force

# Kick off the packer build with the force to override prior builds
$packerConfig = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath sea-starter-kit-win2019-eval.pkr.hcl)).Path

#initialize packer and its packages
& packer init $packerConfig

# run build vm with packer
if ($isoUrl -eq "") {
    & packer build -force -var "vm_switch=$($vmSwitch)" $packerConfig
}
else {
    & packer build -force -var "vm_switch=$($vmSwitch)" -var "iso_url=$($isoUrl)" $packerConfig
}
