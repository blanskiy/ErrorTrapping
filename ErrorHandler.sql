

CREATE TABLE [dbo].[ErrorLog](
	[ErrorLogID] [int] IDENTITY(1,1) NOT NULL,
	[ErrorTime] [datetime] NOT NULL,
	[UserName] [sysname] NOT NULL,
	[ErrorNumber] [int] NOT NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorState] [int] NULL,
	[ErrorProcedure] [nvarchar](126) NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [nvarchar](4000) NOT NULL,
 CONSTRAINT [PK_ErrorLog_ErrorLogID] PRIMARY KEY CLUSTERED 
(
	[ErrorLogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key for ErrorLog records.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorLogID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The date and time at which the error occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The user who executed the batch in which the error occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'UserName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The error number of the error that occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorNumber'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The severity of the error that occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorSeverity'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The state number of the error that occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorState'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The name of the stored procedure or trigger where the error occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorProcedure'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The line number at which the error occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorLine'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The message text of the error that occurred.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'COLUMN',@level2name=N'ErrorMessage'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Audit table tracking errors in the the AdventureWorks database that are caught by the CATCH block of a TRY...CATCH construct. Data is inserted by stored procedure dbo.uspLogError when it is executed from inside the CATCH block of a TRY...CATCH construct.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key (clustered) constraint' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ErrorLog', @level2type=N'CONSTRAINT',@level2name=N'PK_ErrorLog_ErrorLogID'
GO
/****** Object:  StoredProcedure [dbo].[printerror]    Script Date: 02/25/2014 10:12:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_ErrorTime]  DEFAULT (getdate()) FOR [ErrorTime]
GO
-----------------------------------------------------------

CREATE procedure [dbo].[printerror] 
as
begin
-- =============================================
-- Author:		Bruce Lanskiy
-- Create date: 11/28/2016
-- Modified:    by Bruce Lanskiy 
-- Description:	
-- =============================================
set nocount on;
-- print error information. 
print 'error ' + convert(varchar(50), error_number()) +
', severity ' + convert(varchar(5), error_severity()) +
', state ' + convert(varchar(5), error_state()) + 
', procedure ' + isnull(error_procedure(), '-') + 
', line ' + convert(varchar(5), error_line());
print error_message();
end;
GO



--------------------------------------------------

CREATE procedure [dbo].[logerror] 
@errorlogid [int] = 0 output -- contains the errorlogid of the row inserted
as -- by usplogerror in the errorlog table
begin
-- =============================================
-- Author:		Bruce Lanskiy
-- Create date: 11/28/2016
-- Modified: by Bruce Lanskiy 
-- Description:	
-- =============================================
set nocount on;
-- output parameter value of 0 indicates that error 
-- information was not logged
set @errorlogid = 0;
begin try
-- return if there is no error information to log
if error_number() is null
return;
-- return if inside an uncommittable transaction.
-- data insertion/modification is not allowed when 
-- a transaction is in an uncommittable state.
if xact_state() = -1
begin
print 'cannot log error since the current transaction is in an uncommittable state. ' 
+ 'rollback the transaction before executing usplogerror in order to successfully log error information.';
return;
end
insert [dbo].[errorlog] 
(
[username], 
[errornumber], 
[errorseverity], 
[errorstate], 
[errorprocedure], 
[errorline], 
[errormessage]
) 
values 
(
convert(sysname, current_user), 
error_number(),
error_severity(),
error_state(),
error_procedure(),
error_line(),
error_message()
);
-- pass back the errorlogid of the row inserted
set @errorlogid = @@identity;
end try
begin catch
print 'an error occurred in stored procedure usplogerror: ';
execute [dbo].[printerror];
return -1;
end catch
end;

GO
/****** Object:  StoredProcedure [dbo].[OneTimeUpdate_AC_DOB]    Script Date: 2/25/2014 10:09:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO