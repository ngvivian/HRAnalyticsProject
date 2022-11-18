-- Delete existing calendar table if the date inside is not longer applicable
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Calendar' AND TABLE_TYPE = 'BASE TABLE')
	BEGIN
		DROP TABLE [Calendar]
	END


-- Create the structure of Calendar table
-- tinyint (0-255), smallint (-2^15 (-32,768) to 2^15-1 (32,767))
CREATE TABLE [Calendar]
(
    [CalendarDate] DATE NOT NULL CONSTRAINT PK_CalendarDate PRIMARY KEY CLUSTERED,
	[CalendarDay]  TINYINT NOT NULL,
	[CalendarMonth] TINYINT NOT NULL,
	[CalendarQuarter] TINYINT NOT NULL,
	[CalendarYear] SMALLINT NOT NULL,
	[DayOfWeekNum] TINYINT NOT NULL,
	[DayOfWeekName] varchar(10),
	--[DateNum] varchar(10),
	[QuarterCD] varchar(10),
	[MonthNameCD] varchar(10),
	[FullMonthName] varchar(10),
	[HolidayName] varchar(50),
	[HolidayFlag] varchar(10)
)
Go

DECLARE @StartDate DATE
DECLARE @EndDate DATE
SET @StartDate = '2006-01-09'
SET @EndDate = '2018-12-31'


WHILE @StartDate <= @EndDate
	BEGIN
		INSERT INTO [Calendar]
		(	
			CalendarDate,
			CalendarDay,
	   	    CalendarMonth,
			CalendarQuarter,
			CalendarYear,
			DayOfWeekNum,
			DayOfWeekName,
			--DateNum,
			QuarterCD,
			MonthNameCD,
			FullMonthName
			--HolidayName,
			--HolidayFlag
		)

		SELECT @StartDate,
			DAY(@StartDate),
			MONTH(@StartDate),
			DATEPART(QUARTER, (@StartDate)),
			YEAR(@StartDate),
			DATEPART(WEEKDAY, (@StartDate)),
   			DATENAME(WEEKDAY, (@StartDate)),
			--CONVERT(VARCHAR(10), @StartDate, 112),
			CONVERT(VARCHAR(10), YEAR(@StartDate)) + 'Q' + CONVERT(VARCHAR(10) ,DATEPART(QUARTER, (@StartDate))),
   			LEFT(DATENAME(MONTH, (@StartDate)),3),
			DATENAME(MONTH, (@StartDate)),
			NULL,
			'N'	
			
		SET @StartDate = DATEADD(dd, 1, @StartDate)
	END



SELECT * 
FROM [Calendar] 
ORDER BY 1 DESC