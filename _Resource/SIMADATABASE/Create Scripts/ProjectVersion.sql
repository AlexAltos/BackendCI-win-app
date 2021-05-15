SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ProjectVersion](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SectionProject] [varchar](200) NULL,
	[ProjectType] [varchar](200) NULL,
	[Project] [varchar](200) NULL,
	[GMajor] [varchar](200) NULL,
	[Major] [int] NULL,
	[Minor] [int] NULL,
	[Date] [datetime] NOT NULL CONSTRAINT [DF_ProjectVersion_Date]  DEFAULT (getdate()),
 CONSTRAINT [PK_ProjectVersion] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


