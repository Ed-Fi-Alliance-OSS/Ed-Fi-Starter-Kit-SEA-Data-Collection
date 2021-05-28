
USE EdFi_Ods_2022
GO

/****** Object:  Table [dbo].[DeployJournal]    Script Date: 5/17/2021 11:54:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DistrictErrorStaging](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ErrorCode] [nvarchar](255) NOT NULL,
	[ErrorMessage] [nvarchar](255) NOT NULL,
	[Datayears] [nvarchar](255) NOT NULL,
	[DistrictCode] [nvarchar](255) NOT NULL,
	[StudentUSI] [nvarchar](255) NOT NULL,
    [DateAdded] [datetime] NOT NULL
 CONSTRAINT [PK_DistrictErrorStaging_Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
