# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

Write-Output "Installing SQLServer Powershell Module"

Install-Module -Name SqlServer -MinimumVersion "21.1.18068" -Scope AllUsers -Force -AllowClobber | Out-Null
