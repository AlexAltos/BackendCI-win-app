CREATE TABLE [dbo].[_RunOnceScriptsApplied](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ScriptName] [nvarchar](max) NULL,
	[TS] [datetime] NOT NULL,
	[Hash] [nvarchar](max) NULL,
 CONSTRAINT [PK_RunOnce] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[_RunOnceScriptsApplied] ADD  CONSTRAINT [DF_RunOnce_TS]  DEFAULT (getdate()) FOR [TS]
GO
