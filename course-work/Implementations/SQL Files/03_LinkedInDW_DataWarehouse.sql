USE master;
GO
IF DB_ID('LinkedInDW') IS NOT NULL
BEGIN
    ALTER DATABASE LinkedInDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LinkedInDW;
END
GO
CREATE DATABASE LinkedInDW;
GO
USE LinkedInDW;
GO
SET NOCOUNT ON;
GO

/* ===================== ИЗМЕРЕНИЯ ===================== */

CREATE TABLE dbo.DimDate (
    DateKey     INT          NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY,   -- yyyymmdd
    FullDate    DATE         NOT NULL,
    [Year]      SMALLINT     NOT NULL,
    [Quarter]   TINYINT      NOT NULL,
    [Month]     TINYINT      NOT NULL,
    MonthName   NVARCHAR(20) NOT NULL,
    [Day]       TINYINT      NOT NULL,
    DayOfWeek   TINYINT      NOT NULL,   -- 1 = понеделник
    DayName     NVARCHAR(20) NOT NULL,
    IsWeekend   BIT          NOT NULL
);

CREATE TABLE dbo.DimCountry (
    CountryKey  INT IDENTITY(1,1) CONSTRAINT PK_DimCountry PRIMARY KEY,
    CountryID   INT           NOT NULL,
    CountryName NVARCHAR(100) NOT NULL,
    ISOCode     CHAR(2)       NOT NULL
);

CREATE TABLE dbo.DimUser (
    UserKey             INT IDENTITY(1,1) CONSTRAINT PK_DimUser PRIMARY KEY,
    UserID              INT           NOT NULL,
    FullName            NVARCHAR(120) NOT NULL,
    Headline            NVARCHAR(200) NULL,
    City                NVARCHAR(100) NULL,
    IsPremium           BIT           NOT NULL,
    RegistrationYear    SMALLINT      NOT NULL,
    ProfileCompleteness INT           NOT NULL,
    ConnectionsCount    INT           NOT NULL,
    CountryKey          INT           NOT NULL CONSTRAINT FK_DimUser_Country REFERENCES dbo.DimCountry(CountryKey)
);

CREATE TABLE dbo.DimCompany (
    CompanyKey  INT IDENTITY(1,1) CONSTRAINT PK_DimCompany PRIMARY KEY,
    CompanyID   INT           NOT NULL,
    CompanyName NVARCHAR(150) NOT NULL,
    Industry    NVARCHAR(100) NULL,
    CompanySize NVARCHAR(20)  NULL,
    FoundedYear SMALLINT      NULL,
    CountryKey  INT           NOT NULL CONSTRAINT FK_DimCompany_Country REFERENCES dbo.DimCountry(CountryKey)
);

CREATE TABLE dbo.DimJob (
    JobKey         INT IDENTITY(1,1) CONSTRAINT PK_DimJob PRIMARY KEY,
    JobID          INT           NOT NULL,
    JobTitle       NVARCHAR(150) NOT NULL,
    EmploymentType NVARCHAR(20)  NOT NULL,
    Location       NVARCHAR(100) NULL,
    SalaryMin      DECIMAL(10,2) NULL,
    SalaryMax      DECIMAL(10,2) NULL,
    IsActive       BIT           NOT NULL
);

CREATE TABLE dbo.DimApplicationStatus (
    StatusKey  INT IDENTITY(1,1) CONSTRAINT PK_DimApplicationStatus PRIMARY KEY,
    StatusName NVARCHAR(20) NOT NULL
);

CREATE TABLE dbo.DimConnectionStatus (
    ConnectionStatusKey INT IDENTITY(1,1) CONSTRAINT PK_DimConnectionStatus PRIMARY KEY,
    StatusName          NVARCHAR(20) NOT NULL
);

/* ===================== ФАКТИ ===================== */

-- Грануларност: една кандидатура
CREATE TABLE dbo.FactJobApplications (
    ApplicationKey   INT IDENTITY(1,1) CONSTRAINT PK_FactJobApplications PRIMARY KEY,
    ApplicationID    INT NOT NULL,                       -- дегенерирано измерение
    DateKey          INT NOT NULL CONSTRAINT FK_FJA_Date    REFERENCES dbo.DimDate(DateKey),
    ApplicantUserKey INT NOT NULL CONSTRAINT FK_FJA_User    REFERENCES dbo.DimUser(UserKey),
    JobKey           INT NOT NULL CONSTRAINT FK_FJA_Job     REFERENCES dbo.DimJob(JobKey),
    CompanyKey       INT NOT NULL CONSTRAINT FK_FJA_Company REFERENCES dbo.DimCompany(CompanyKey),
    StatusKey        INT NOT NULL CONSTRAINT FK_FJA_Status  REFERENCES dbo.DimApplicationStatus(StatusKey),
    ApplicationCount INT NOT NULL,                       -- мярка (винаги 1)
    DaysSincePosted  INT NOT NULL                        -- мярка
);

-- Грануларност: една публикация
CREATE TABLE dbo.FactPostEngagement (
    PostEngagementKey INT IDENTITY(1,1) CONSTRAINT PK_FactPostEngagement PRIMARY KEY,
    PostID            INT          NOT NULL,             -- дегенерирано измерение
    DateKey           INT          NOT NULL CONSTRAINT FK_FPE_Date REFERENCES dbo.DimDate(DateKey),
    AuthorUserKey     INT          NOT NULL CONSTRAINT FK_FPE_User REFERENCES dbo.DimUser(UserKey),
    Visibility        NVARCHAR(20) NOT NULL,             -- дегенерирано измерение
    ReactionsCount    INT          NOT NULL,             -- мярка
    CommentsCount     INT          NOT NULL              -- мярка
);

-- Грануларност: една покана за връзка
CREATE TABLE dbo.FactConnections (
    ConnectionKey       INT IDENTITY(1,1) CONSTRAINT PK_FactConnections PRIMARY KEY,
    ConnectionID        INT NOT NULL,                    -- дегенерирано измерение
    DateKey             INT NOT NULL CONSTRAINT FK_FC_Date      REFERENCES dbo.DimDate(DateKey),
    RequesterUserKey    INT NOT NULL CONSTRAINT FK_FC_Requester REFERENCES dbo.DimUser(UserKey),
    ReceiverUserKey     INT NOT NULL CONSTRAINT FK_FC_Receiver  REFERENCES dbo.DimUser(UserKey),
    ConnectionStatusKey INT NOT NULL CONSTRAINT FK_FC_Status    REFERENCES dbo.DimConnectionStatus(ConnectionStatusKey),
    ConnectionCount     INT NOT NULL,                    -- мярка (винаги 1)
    DaysToAccept        INT NULL                         -- мярка (NULL ако не е приета)
);
GO

/* ===================== ETL (зареждане на данните) ===================== */

-- DimDate: 2020-01-01 .. 2027-12-31
;WITH D AS (
    SELECT CAST('2020-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM D WHERE d < '2027-12-31'
)
INSERT INTO dbo.DimDate (DateKey, FullDate, [Year], [Quarter], [Month], MonthName, [Day], DayOfWeek, DayName, IsWeekend)
SELECT YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
       d,
       YEAR(d),
       DATEPART(QUARTER, d),
       MONTH(d),
       DATENAME(MONTH, d),
       DAY(d),
       (DATEDIFF(DAY, '19000101', d) % 7) + 1,           -- 1900-01-01 е понеделник
       DATENAME(WEEKDAY, d),
       CASE WHEN DATEDIFF(DAY, '19000101', d) % 7 IN (5, 6) THEN 1 ELSE 0 END
FROM D
OPTION (MAXRECURSION 0);

-- DimCountry
INSERT INTO dbo.DimCountry (CountryID, CountryName, ISOCode)
SELECT CountryID, Name, ISOCode FROM LinkedInDB.dbo.Countries;

-- DimUser (с изчислени показатели чрез функциите от LinkedInDB)
INSERT INTO dbo.DimUser (UserID, FullName, Headline, City, IsPremium, RegistrationYear, ProfileCompleteness, ConnectionsCount, CountryKey)
SELECT u.UserID,
       u.FirstName + N' ' + u.LastName,
       u.Headline,
       u.City,
       u.IsPremium,
       YEAR(u.RegisteredAt),
       LinkedInDB.dbo.fn_GetProfileCompleteness(u.UserID),
       LinkedInDB.dbo.fn_GetConnectionCount(u.UserID),
       dc.CountryKey
FROM LinkedInDB.dbo.Users u
JOIN dbo.DimCountry dc ON dc.CountryID = u.CountryID;

-- DimCompany
INSERT INTO dbo.DimCompany (CompanyID, CompanyName, Industry, CompanySize, FoundedYear, CountryKey)
SELECT c.CompanyID, c.Name, c.Industry, c.CompanySize, c.FoundedYear, dc.CountryKey
FROM LinkedInDB.dbo.Companies c
JOIN dbo.DimCountry dc ON dc.CountryID = c.CountryID;

-- DimJob
INSERT INTO dbo.DimJob (JobID, JobTitle, EmploymentType, Location, SalaryMin, SalaryMax, IsActive)
SELECT JobID, Title, EmploymentType, Location, SalaryMin, SalaryMax, IsActive
FROM LinkedInDB.dbo.Jobs;

-- Статуси
INSERT INTO dbo.DimApplicationStatus (StatusName)
SELECT DISTINCT Status FROM LinkedInDB.dbo.JobApplications;

INSERT INTO dbo.DimConnectionStatus (StatusName)
SELECT DISTINCT Status FROM LinkedInDB.dbo.Connections;

-- FactJobApplications
INSERT INTO dbo.FactJobApplications (ApplicationID, DateKey, ApplicantUserKey, JobKey, CompanyKey, StatusKey, ApplicationCount, DaysSincePosted)
SELECT a.ApplicationID,
       dd.DateKey,
       du.UserKey,
       dj.JobKey,
       dc.CompanyKey,
       ds.StatusKey,
       1,
       DATEDIFF(DAY, j.PostedAt, a.AppliedAt)
FROM LinkedInDB.dbo.JobApplications a
JOIN LinkedInDB.dbo.Jobs j        ON j.JobID = a.JobID
JOIN dbo.DimDate dd               ON dd.FullDate = CAST(a.AppliedAt AS DATE)
JOIN dbo.DimUser du               ON du.UserID = a.UserID
JOIN dbo.DimJob dj                ON dj.JobID = j.JobID
JOIN dbo.DimCompany dc            ON dc.CompanyID = j.CompanyID
JOIN dbo.DimApplicationStatus ds  ON ds.StatusName = a.Status;

-- FactPostEngagement
INSERT INTO dbo.FactPostEngagement (PostID, DateKey, AuthorUserKey, Visibility, ReactionsCount, CommentsCount)
SELECT p.PostID,
       dd.DateKey,
       du.UserKey,
       p.Visibility,
       (SELECT COUNT(*) FROM LinkedInDB.dbo.PostReactions r WHERE r.PostID = p.PostID),
       (SELECT COUNT(*) FROM LinkedInDB.dbo.Comments c      WHERE c.PostID = p.PostID)
FROM LinkedInDB.dbo.Posts p
JOIN dbo.DimDate dd ON dd.FullDate = CAST(p.CreatedAt AS DATE)
JOIN dbo.DimUser du ON du.UserID = p.UserID;

-- FactConnections
INSERT INTO dbo.FactConnections (ConnectionID, DateKey, RequesterUserKey, ReceiverUserKey, ConnectionStatusKey, ConnectionCount, DaysToAccept)
SELECT cn.ConnectionID,
       dd.DateKey,
       dreq.UserKey,
       drec.UserKey,
       dcs.ConnectionStatusKey,
       1,
       DATEDIFF(DAY, cn.RequestedAt, cn.AcceptedAt)
FROM LinkedInDB.dbo.Connections cn
JOIN dbo.DimDate dd                ON dd.FullDate = CAST(cn.RequestedAt AS DATE)
JOIN dbo.DimUser dreq              ON dreq.UserID = cn.RequesterID
JOIN dbo.DimUser drec              ON drec.UserID = cn.ReceiverID
JOIN dbo.DimConnectionStatus dcs   ON dcs.StatusName = cn.Status;
GO

/* ---------- Проверка ---------- */
SELECT 'DimDate' AS TableName, COUNT(*) AS Rows FROM dbo.DimDate UNION ALL
SELECT 'DimCountry', COUNT(*) FROM dbo.DimCountry UNION ALL
SELECT 'DimUser', COUNT(*) FROM dbo.DimUser UNION ALL
SELECT 'DimCompany', COUNT(*) FROM dbo.DimCompany UNION ALL
SELECT 'DimJob', COUNT(*) FROM dbo.DimJob UNION ALL
SELECT 'DimApplicationStatus', COUNT(*) FROM dbo.DimApplicationStatus UNION ALL
SELECT 'DimConnectionStatus', COUNT(*) FROM dbo.DimConnectionStatus UNION ALL
SELECT 'FactJobApplications', COUNT(*) FROM dbo.FactJobApplications UNION ALL
SELECT 'FactPostEngagement', COUNT(*) FROM dbo.FactPostEngagement UNION ALL
SELECT 'FactConnections', COUNT(*) FROM dbo.FactConnections;
GO
