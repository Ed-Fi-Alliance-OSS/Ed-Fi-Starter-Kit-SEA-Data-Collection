# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
.description
    Runs CreateVMSwitch to create in VMSwitch in admin mode.
.parameter $VMSwitchname
    VMswitch name
#>
param(
    [string] $VMSwitchname = "packer-hyperv-iso"
)

function Invoke-CreateVMSwitch {

    # Get the first physical network adapter that has an Up status.
    $net_adapter = ((Get-NetAdapter -Name "*" -Physical) | Where-Object { $_.Status -eq 'Up' })[0].Name

    Write-Output "Checking for existence of VM Switch $($VMSwitchname)"

    # Note this requires admin privileges
    if ($null -eq (Get-VMSwitch -Name $VMSwitchname -ErrorAction SilentlyContinue)) {
        Write-Output "Creating new VM Switch $($VMSwitchname)"
        New-VMSwitch -Name $VMSwitchname -AllowManagementOS $true -NetAdapterName $net_adapter -MinimumBandwidthMode Weight
        $VmSwitchCount = (Get-VMSwitch | Where-Object -Property Name -EQ -Value $VMSwitchname).count
        If($VmSwitchCount -eq '1'){
            Write-Output "New VM Switch $($VMSwitchname) created successfully."
        }
        else{
            Write-Output "New VM Switch $($VMSwitchname) failed to create."
        }
    }
}

Invoke-CreateVMSwitch
