USE master;
GO
IF DB_ID('LinkedInDB') IS NOT NULL
BEGIN
    ALTER DATABASE LinkedInDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LinkedInDB;
END
GO
CREATE DATABASE LinkedInDB;
GO
USE LinkedInDB;
GO

/* ===================== ТАБЛИЦИ ===================== */

CREATE TABLE dbo.Countries (
    CountryID   INT IDENTITY(1,1) CONSTRAINT PK_Countries PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL CONSTRAINT UQ_Countries_Name UNIQUE,
    ISOCode     CHAR(2)       NOT NULL CONSTRAINT UQ_Countries_ISO UNIQUE
);

CREATE TABLE dbo.Users (
    UserID       INT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    FirstName    NVARCHAR(50)   NOT NULL,
    LastName     NVARCHAR(50)   NOT NULL,
    Email        NVARCHAR(150)  NOT NULL CONSTRAINT UQ_Users_Email UNIQUE,
    PasswordHash NVARCHAR(200)  NOT NULL,
    Headline     NVARCHAR(200)  NULL,
    Summary      NVARCHAR(MAX)  NULL,
    CountryID    INT            NOT NULL CONSTRAINT FK_Users_Countries REFERENCES dbo.Countries(CountryID),
    City         NVARCHAR(100)  NULL,
    RegisteredAt DATETIME2      NOT NULL CONSTRAINT DF_Users_RegisteredAt DEFAULT SYSDATETIME(),
    IsPremium    BIT            NOT NULL CONSTRAINT DF_Users_IsPremium DEFAULT 0
);

CREATE TABLE dbo.Companies (
    CompanyID   INT IDENTITY(1,1) CONSTRAINT PK_Companies PRIMARY KEY,
    Name        NVARCHAR(150) NOT NULL CONSTRAINT UQ_Companies_Name UNIQUE,
    Industry    NVARCHAR(100) NULL,
    Website     NVARCHAR(200) NULL,
    FoundedYear SMALLINT      NULL,
    CompanySize NVARCHAR(20)  NULL,
    CountryID   INT           NOT NULL CONSTRAINT FK_Companies_Countries REFERENCES dbo.Countries(CountryID)
);

CREATE TABLE dbo.Skills (
    SkillID  INT IDENTITY(1,1) CONSTRAINT PK_Skills PRIMARY KEY,
    Name     NVARCHAR(100) NOT NULL CONSTRAINT UQ_Skills_Name UNIQUE,
    Category NVARCHAR(50)  NULL
);

-- M:N  Users <-> Skills
CREATE TABLE dbo.UserSkills (
    UserID            INT     NOT NULL CONSTRAINT FK_UserSkills_Users  REFERENCES dbo.Users(UserID) ON DELETE CASCADE,
    SkillID           INT     NOT NULL CONSTRAINT FK_UserSkills_Skills REFERENCES dbo.Skills(SkillID),
    ProficiencyLevel  TINYINT NOT NULL CONSTRAINT CK_UserSkills_Level CHECK (ProficiencyLevel BETWEEN 1 AND 5),
    EndorsementsCount INT     NOT NULL CONSTRAINT DF_UserSkills_End DEFAULT 0,
    CONSTRAINT PK_UserSkills PRIMARY KEY (UserID, SkillID)
);

CREATE TABLE dbo.Experiences (
    ExperienceID INT IDENTITY(1,1) CONSTRAINT PK_Experiences PRIMARY KEY,
    UserID       INT           NOT NULL CONSTRAINT FK_Experiences_Users     REFERENCES dbo.Users(UserID) ON DELETE CASCADE,
    CompanyID    INT           NOT NULL CONSTRAINT FK_Experiences_Companies REFERENCES dbo.Companies(CompanyID),
    Title        NVARCHAR(150) NOT NULL,
    StartDate    DATE          NOT NULL,
    EndDate      DATE          NULL,
    Description  NVARCHAR(1000) NULL,
    CONSTRAINT CK_Experiences_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
);

CREATE TABLE dbo.Education (
    EducationID  INT IDENTITY(1,1) CONSTRAINT PK_Education PRIMARY KEY,
    UserID       INT           NOT NULL CONSTRAINT FK_Education_Users REFERENCES dbo.Users(UserID) ON DELETE CASCADE,
    SchoolName   NVARCHAR(200) NOT NULL,
    Degree       NVARCHAR(100) NULL,
    FieldOfStudy NVARCHAR(100) NULL,
    StartYear    SMALLINT      NOT NULL,
    EndYear      SMALLINT      NULL,
    CONSTRAINT CK_Education_Years CHECK (EndYear IS NULL OR EndYear >= StartYear)
);

-- M:N  Users <-> Users (връзки между потребители)
CREATE TABLE dbo.Connections (
    ConnectionID INT IDENTITY(1,1) CONSTRAINT PK_Connections PRIMARY KEY,
    RequesterID  INT          NOT NULL CONSTRAINT FK_Connections_Requester REFERENCES dbo.Users(UserID),
    ReceiverID   INT          NOT NULL CONSTRAINT FK_Connections_Receiver  REFERENCES dbo.Users(UserID),
    Status       NVARCHAR(20) NOT NULL CONSTRAINT DF_Connections_Status DEFAULT 'Pending',
    RequestedAt  DATETIME2    NOT NULL CONSTRAINT DF_Connections_ReqAt DEFAULT SYSDATETIME(),
    AcceptedAt   DATETIME2    NULL,
    CONSTRAINT CK_Connections_Status CHECK (Status IN ('Pending','Accepted','Declined')),
    CONSTRAINT CK_Connections_NotSelf CHECK (RequesterID <> ReceiverID)
);

CREATE TABLE dbo.Posts (
    PostID     INT IDENTITY(1,1) CONSTRAINT PK_Posts PRIMARY KEY,
    UserID     INT           NOT NULL CONSTRAINT FK_Posts_Users REFERENCES dbo.Users(UserID),
    Content    NVARCHAR(3000) NOT NULL,
    CreatedAt  DATETIME2     NOT NULL CONSTRAINT DF_Posts_CreatedAt DEFAULT SYSDATETIME(),
    Visibility NVARCHAR(20)  NOT NULL CONSTRAINT DF_Posts_Visibility DEFAULT 'Public',
    CONSTRAINT CK_Posts_Visibility CHECK (Visibility IN ('Public','Connections'))
);

CREATE TABLE dbo.Comments (
    CommentID INT IDENTITY(1,1) CONSTRAINT PK_Comments PRIMARY KEY,
    PostID    INT           NOT NULL CONSTRAINT FK_Comments_Posts REFERENCES dbo.Posts(PostID) ON DELETE CASCADE,
    UserID    INT           NOT NULL CONSTRAINT FK_Comments_Users REFERENCES dbo.Users(UserID),
    Content   NVARCHAR(1500) NOT NULL,
    CreatedAt DATETIME2     NOT NULL CONSTRAINT DF_Comments_CreatedAt DEFAULT SYSDATETIME()
);

-- M:N  Users <-> Posts (реакции)
CREATE TABLE dbo.PostReactions (
    PostID       INT          NOT NULL CONSTRAINT FK_Reactions_Posts REFERENCES dbo.Posts(PostID) ON DELETE CASCADE,
    UserID       INT          NOT NULL CONSTRAINT FK_Reactions_Users REFERENCES dbo.Users(UserID),
    ReactionType NVARCHAR(20) NOT NULL,
    ReactedAt    DATETIME2    NOT NULL CONSTRAINT DF_Reactions_At DEFAULT SYSDATETIME(),
    CONSTRAINT PK_PostReactions PRIMARY KEY (PostID, UserID),
    CONSTRAINT CK_Reactions_Type CHECK (ReactionType IN ('Like','Celebrate','Support','Insightful','Funny','Love'))
);

CREATE TABLE dbo.Jobs (
    JobID          INT IDENTITY(1,1) CONSTRAINT PK_Jobs PRIMARY KEY,
    CompanyID      INT           NOT NULL CONSTRAINT FK_Jobs_Companies REFERENCES dbo.Companies(CompanyID),
    PostedByUserID INT           NOT NULL CONSTRAINT FK_Jobs_Users REFERENCES dbo.Users(UserID),
    Title          NVARCHAR(150) NOT NULL,
    Description    NVARCHAR(MAX) NULL,
    Location       NVARCHAR(100) NULL,
    EmploymentType NVARCHAR(20)  NOT NULL,
    SalaryMin      DECIMAL(10,2) NULL,
    SalaryMax      DECIMAL(10,2) NULL,
    PostedAt       DATETIME2     NOT NULL CONSTRAINT DF_Jobs_PostedAt DEFAULT SYSDATETIME(),
    IsActive       BIT           NOT NULL CONSTRAINT DF_Jobs_IsActive DEFAULT 1,
    CONSTRAINT CK_Jobs_Type   CHECK (EmploymentType IN ('Full-time','Part-time','Contract','Internship')),
    CONSTRAINT CK_Jobs_Salary CHECK (SalaryMin IS NULL OR SalaryMax IS NULL OR SalaryMax >= SalaryMin)
);

-- M:N  Jobs <-> Skills
CREATE TABLE dbo.JobSkills (
    JobID   INT NOT NULL CONSTRAINT FK_JobSkills_Jobs   REFERENCES dbo.Jobs(JobID) ON DELETE CASCADE,
    SkillID INT NOT NULL CONSTRAINT FK_JobSkills_Skills REFERENCES dbo.Skills(SkillID),
    CONSTRAINT PK_JobSkills PRIMARY KEY (JobID, SkillID)
);

-- M:N  Users <-> Jobs (кандидатури)
CREATE TABLE dbo.JobApplications (
    ApplicationID INT IDENTITY(1,1) CONSTRAINT PK_JobApplications PRIMARY KEY,
    JobID         INT           NOT NULL CONSTRAINT FK_Applications_Jobs  REFERENCES dbo.Jobs(JobID),
    UserID        INT           NOT NULL CONSTRAINT FK_Applications_Users REFERENCES dbo.Users(UserID),
    AppliedAt     DATETIME2     NOT NULL CONSTRAINT DF_Applications_At DEFAULT SYSDATETIME(),
    Status        NVARCHAR(20)  NOT NULL CONSTRAINT DF_Applications_Status DEFAULT 'Submitted',
    CoverLetter   NVARCHAR(2000) NULL,
    CONSTRAINT UQ_Applications_JobUser UNIQUE (JobID, UserID),
    CONSTRAINT CK_Applications_Status CHECK (Status IN ('Submitted','In Review','Interview','Offer','Rejected'))
);

CREATE TABLE dbo.Messages (
    MessageID  INT IDENTITY(1,1) CONSTRAINT PK_Messages PRIMARY KEY,
    SenderID   INT           NOT NULL CONSTRAINT FK_Messages_Sender   REFERENCES dbo.Users(UserID),
    ReceiverID INT           NOT NULL CONSTRAINT FK_Messages_Receiver REFERENCES dbo.Users(UserID),
    Content    NVARCHAR(2000) NOT NULL,
    SentAt     DATETIME2     NOT NULL CONSTRAINT DF_Messages_SentAt DEFAULT SYSDATETIME(),
    IsRead     BIT           NOT NULL CONSTRAINT DF_Messages_IsRead DEFAULT 0,
    CONSTRAINT CK_Messages_NotSelf CHECK (SenderID <> ReceiverID)
);

-- Журнал на промените (пълни се от тригерите)
CREATE TABLE dbo.AuditLog (
    AuditID    INT IDENTITY(1,1) CONSTRAINT PK_AuditLog PRIMARY KEY,
    TableName  NVARCHAR(100) NOT NULL,
    ActionType NVARCHAR(20)  NOT NULL,
    RecordID   INT           NULL,
    Details    NVARCHAR(500) NULL,
    ChangedAt  DATETIME2     NOT NULL CONSTRAINT DF_Audit_At DEFAULT SYSDATETIME(),
    ChangedBy  NVARCHAR(128) NOT NULL CONSTRAINT DF_Audit_By DEFAULT SYSTEM_USER
);
GO

/* Индекси за по-бързи заявки */
CREATE INDEX IX_Users_CountryID        ON dbo.Users(CountryID);
CREATE INDEX IX_Connections_Requester  ON dbo.Connections(RequesterID);
CREATE INDEX IX_Connections_Receiver   ON dbo.Connections(ReceiverID);
CREATE INDEX IX_Posts_UserID           ON dbo.Posts(UserID);
CREATE INDEX IX_Jobs_CompanyID         ON dbo.Jobs(CompanyID);
CREATE INDEX IX_Applications_UserID    ON dbo.JobApplications(UserID);
GO

/* ===================== ФУНКЦИИ ===================== */

-- Функция 1: брой приети връзки на потребител
CREATE FUNCTION dbo.fn_GetConnectionCount (@UserID INT)
RETURNS INT
AS
BEGIN
    DECLARE @cnt INT;
    SELECT @cnt = COUNT(*)
    FROM dbo.Connections
    WHERE Status = 'Accepted' AND (RequesterID = @UserID OR ReceiverID = @UserID);
    RETURN @cnt;
END
GO

-- Функция 2: пълнота на профила в проценти (0-100)
CREATE FUNCTION dbo.fn_GetProfileCompleteness (@UserID INT)
RETURNS INT
AS
BEGIN
    DECLARE @score INT = 0;
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @UserID AND ISNULL(Headline, N'') <> N'')
        SET @score += 20;
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @UserID AND ISNULL(Summary, N'') <> N'')
        SET @score += 20;
    IF EXISTS (SELECT 1 FROM dbo.Experiences WHERE UserID = @UserID)
        SET @score += 20;
    IF EXISTS (SELECT 1 FROM dbo.Education WHERE UserID = @UserID)
        SET @score += 20;
    IF (SELECT COUNT(*) FROM dbo.UserSkills WHERE UserID = @UserID) >= 3
        SET @score += 20;
    RETURN @score;
END
GO

-- Функция 3 (табличната): препоръчани обяви според уменията на потребителя
CREATE FUNCTION dbo.fn_RecommendedJobs (@UserID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT j.JobID,
           j.Title,
           c.Name AS CompanyName,
           j.Location,
           j.EmploymentType,
           COUNT(js.SkillID) AS MatchingSkills
    FROM dbo.Jobs j
    JOIN dbo.Companies c  ON c.CompanyID = j.CompanyID
    JOIN dbo.JobSkills js ON js.JobID = j.JobID
    JOIN dbo.UserSkills us ON us.SkillID = js.SkillID AND us.UserID = @UserID
    WHERE j.IsActive = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.JobApplications a
                      WHERE a.JobID = j.JobID AND a.UserID = @UserID)
    GROUP BY j.JobID, j.Title, c.Name, j.Location, j.EmploymentType
);
GO

/* ===================== СЪХРАНЕНИ ПРОЦЕДУРИ ===================== */

-- Процедура 1: регистрация на потребител
CREATE PROCEDURE dbo.sp_RegisterUser
    @FirstName    NVARCHAR(50),
    @LastName     NVARCHAR(50),
    @Email        NVARCHAR(150),
    @PasswordHash NVARCHAR(200),
    @CountryID    INT,
    @City         NVARCHAR(100) = NULL,
    @Headline     NVARCHAR(200) = NULL,
    @NewUserID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email)
        THROW 50001, N'Потребител с този имейл вече съществува.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Countries WHERE CountryID = @CountryID)
        THROW 50002, N'Невалидна държава.', 1;

    INSERT INTO dbo.Users (FirstName, LastName, Email, PasswordHash, Headline, CountryID, City, RegisteredAt, IsPremium)
    VALUES (@FirstName, @LastName, @Email, @PasswordHash, @Headline, @CountryID, @City, SYSDATETIME(), 0);

    SET @NewUserID = SCOPE_IDENTITY();
END
GO

-- Процедура 2: изпращане на покана за връзка
CREATE PROCEDURE dbo.sp_SendConnectionRequest
    @RequesterID INT,
    @ReceiverID  INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @RequesterID = @ReceiverID
        THROW 50010, N'Не можете да се свържете сами със себе си.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @RequesterID)
       OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserID = @ReceiverID)
        THROW 50011, N'Несъществуващ потребител.', 1;

    -- дублиращи се покани се хващат от тригера trg_Connections_PreventDuplicate
    INSERT INTO dbo.Connections (RequesterID, ReceiverID, Status, RequestedAt)
    VALUES (@RequesterID, @ReceiverID, 'Pending', SYSDATETIME());
END
GO

-- Процедура 3: приемане на покана (само получателят може да я приеме)
CREATE PROCEDURE dbo.sp_AcceptConnection
    @ConnectionID INT,
    @UserID       INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Connections
    SET Status = 'Accepted', AcceptedAt = SYSDATETIME()
    WHERE ConnectionID = @ConnectionID
      AND ReceiverID   = @UserID
      AND Status       = 'Pending';

    IF @@ROWCOUNT = 0
        THROW 50012, N'Няма чакаща покана с тези данни.', 1;
END
GO

-- Процедура 4: кандидатстване за обява
CREATE PROCEDURE dbo.sp_ApplyForJob
    @JobID       INT,
    @UserID      INT,
    @CoverLetter NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Jobs WHERE JobID = @JobID AND IsActive = 1)
        THROW 50020, N'Обявата не съществува или вече не е активна.', 1;
    IF EXISTS (SELECT 1 FROM dbo.JobApplications WHERE JobID = @JobID AND UserID = @UserID)
        THROW 50021, N'Вече сте кандидатствали за тази обява.', 1;

    INSERT INTO dbo.JobApplications (JobID, UserID, AppliedAt, Status, CoverLetter)
    VALUES (@JobID, @UserID, SYSDATETIME(), 'Submitted', @CoverLetter);
END
GO

-- Процедура 5: смяна на статус на кандидатура (задейства тригера за одит)
CREATE PROCEDURE dbo.sp_UpdateApplicationStatus
    @ApplicationID INT,
    @NewStatus     NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.JobApplications SET Status = @NewStatus WHERE ApplicationID = @ApplicationID;
    IF @@ROWCOUNT = 0
        THROW 50022, N'Кандидатурата не е намерена.', 1;
END
GO

-- Процедура 6: новинарски поток (feed) - публикации на мен и на моите връзки
CREATE PROCEDURE dbo.sp_GetUserFeed
    @UserID INT,
    @Top    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
           p.PostID,
           u.FirstName + N' ' + u.LastName AS Author,
           p.Content,
           p.CreatedAt,
           (SELECT COUNT(*) FROM dbo.PostReactions r WHERE r.PostID = p.PostID) AS Reactions,
           (SELECT COUNT(*) FROM dbo.Comments c      WHERE c.PostID = p.PostID) AS CommentsCount
    FROM dbo.Posts p
    JOIN dbo.Users u ON u.UserID = p.UserID
    WHERE p.UserID = @UserID
       OR p.UserID IN (
            SELECT CASE WHEN RequesterID = @UserID THEN ReceiverID ELSE RequesterID END
            FROM dbo.Connections
            WHERE Status = 'Accepted' AND (RequesterID = @UserID OR ReceiverID = @UserID))
    ORDER BY p.CreatedAt DESC;
END
GO

/* ===================== ТРИГЕРИ ===================== */

-- Тригер 1 (INSTEAD OF INSERT): забранява дублирани/огледални покани A->B и B->A
CREATE TRIGGER dbo.trg_Connections_PreventDuplicate
ON dbo.Connections
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Connections c
          ON (c.RequesterID = i.RequesterID AND c.ReceiverID = i.ReceiverID)
          OR (c.RequesterID = i.ReceiverID  AND c.ReceiverID = i.RequesterID))
    BEGIN
        THROW 50030, N'Между тези двама потребители вече съществува връзка или покана.', 1;
    END

    INSERT INTO dbo.Connections (RequesterID, ReceiverID, Status, RequestedAt, AcceptedAt)
    SELECT RequesterID, ReceiverID,
           ISNULL(Status, 'Pending'),
           ISNULL(RequestedAt, SYSDATETIME()),
           AcceptedAt
    FROM inserted;
END
GO

-- Тригер 2 (AFTER UPDATE): записва в AuditLog всяка смяна на статус на кандидатура
CREATE TRIGGER dbo.trg_JobApplications_AuditStatus
ON dbo.JobApplications
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Status)
    BEGIN
        INSERT INTO dbo.AuditLog (TableName, ActionType, RecordID, Details)
        SELECT N'JobApplications', N'UPDATE', i.ApplicationID,
               N'Статус: ' + d.Status + N' -> ' + i.Status
        FROM inserted i
        JOIN deleted  d ON d.ApplicationID = i.ApplicationID
        WHERE i.Status <> d.Status;
    END
END
GO

-- Тригер 3 (AFTER DELETE): архивира информация за изтрити публикации
CREATE TRIGGER dbo.trg_Posts_AuditDelete
ON dbo.Posts
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.AuditLog (TableName, ActionType, RecordID, Details)
    SELECT N'Posts', N'DELETE', d.PostID,
           N'Изтрита публикация на UserID=' + CAST(d.UserID AS NVARCHAR(20)) +
           N': ' + LEFT(d.Content, 100)
    FROM deleted d;
END
GO

PRINT N'Схемата на LinkedInDB е създадена успешно.';
GO
