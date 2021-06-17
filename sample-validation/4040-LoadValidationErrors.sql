-- SPDX-License-Identifier: Apache-2.0
-- Licensed to the Ed-Fi Alliance under one or more agreements.
-- The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
-- See the LICENSE and NOTICES files in the project root for more information.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [validation].[LoadValidationErrors] 
( 
       @StateOrganizationId  nvarchar(11)= 'all',  
       @Datayear nvarchar(9)
) 
AS
BEGIN

TRUNCATE TABLE [validation].[DistrictErrorLog];
INSERT INTO [validation].[DistrictErrorLog](ErrorCode, ErrorMessage, Datayears, DistrictCode, StudentUSI, DateAdded)
SELECT * FROM [validation].[GetValidationError_743](@StateOrganizationId, @Datayear)

INSERT INTO [validation].[DistrictErrorLog](ErrorCode, ErrorMessage, Datayears, DistrictCode, StudentUSI, DateAdded)
SELECT * FROM [validation].[GetValidationError_705](@StateOrganizationId, @Datayear)

END;
GO

