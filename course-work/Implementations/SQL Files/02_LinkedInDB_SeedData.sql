USE LinkedInDB;
GO
SET NOCOUNT ON;
GO

/* ---------- Държави ---------- */
INSERT INTO dbo.Countries (Name, ISOCode) VALUES
(N'Bulgaria','BG'),(N'Germany','DE'),(N'United Kingdom','GB'),(N'United States','US'),
(N'France','FR'),(N'Netherlands','NL'),(N'Spain','ES'),(N'Italy','IT'),
(N'Poland','PL'),(N'Romania','RO');
GO

/* ---------- Компании ---------- */
INSERT INTO dbo.Companies (Name, Industry, Website, FoundedYear, CompanySize, CountryID) VALUES
(N'NovaTech Solutions',     N'IT',            N'https://novatech.example.com',    2008, N'201-500',   1),
(N'Balkan Data Systems',    N'IT',            N'https://balkandata.example.com',  2012, N'51-200',    1),
(N'BlueWave Marketing',     N'Marketing',     N'https://bluewave.example.com',    2015, N'51-200',    3),
(N'Alpine Consulting',      N'Consulting',    N'https://alpine.example.com',      1999, N'501-1000',  2),
(N'GreenLeaf Energy',       N'Energy',        N'https://greenleaf.example.com',   2005, N'1001-5000', 2),
(N'Orbit Finance',          N'Finance',       N'https://orbitfin.example.com',    2001, N'1001-5000', 4),
(N'Sofia Software Labs',    N'IT',            N'https://sofialabs.example.com',   2017, N'1-50',      1),
(N'MediCare Plus',          N'Healthcare',    N'https://medicareplus.example.com',1995, N'501-1000',  5),
(N'Northern Logistics',     N'Logistics',     N'https://northlog.example.com',    2003, N'201-500',   6),
(N'PixelForge Studio',      N'Design',        N'https://pixelforge.example.com',  2018, N'1-50',      7),
(N'Danube Retail Group',    N'Retail',        N'https://danuberetail.example.com',1998, N'1001-5000', 10),
(N'CloudNine Hosting',      N'IT',            N'https://cloudnine.example.com',   2010, N'51-200',    9),
(N'BrightPath Education',   N'Education',     N'https://brightpath.example.com',  2011, N'51-200',    8),
(N'IronBridge Construction',N'Construction',  N'https://ironbridge.example.com',  1990, N'501-1000',  9),
(N'Helix Biotech',          N'Biotechnology', N'https://helixbio.example.com',    2014, N'201-500',   4);
GO

/* ---------- Умения ---------- */
INSERT INTO dbo.Skills (Name, Category) VALUES
(N'SQL',N'Data'),(N'Python',N'Programming'),(N'C#',N'Programming'),(N'JavaScript',N'Programming'),
(N'Power BI',N'Data'),(N'Excel',N'Data'),(N'Project Management',N'Management'),(N'Communication',N'Soft Skills'),
(N'Leadership',N'Management'),(N'UX Design',N'Design'),(N'Figma',N'Design'),(N'Azure',N'Cloud'),
(N'AWS',N'Cloud'),(N'Docker',N'DevOps'),(N'Git',N'DevOps'),(N'Digital Marketing',N'Marketing'),
(N'SEO',N'Marketing'),(N'Recruiting',N'HR'),(N'Negotiation',N'Sales'),(N'Agile/Scrum',N'Management');
GO

/* ---------- Потребители (200) ---------- */
CREATE TABLE #FN (ID INT, Name NVARCHAR(50), IsF BIT);
INSERT INTO #FN VALUES
(1,N'Ivan',0),(2,N'Maria',1),(3,N'Georgi',0),(4,N'Elena',1),(5,N'Dimitar',0),
(6,N'Nikolay',0),(7,N'Petya',1),(8,N'Stefan',0),(9,N'Viktoria',1),(10,N'Aleksandar',0),
(11,N'Katerina',1),(12,N'Boris',0),(13,N'Desislava',1),(14,N'Hristo',0),(15,N'Ivana',1),
(16,N'Kaloyan',0),(17,N'Radostina',1),(18,N'Tihomir',0),(19,N'Yana',1),(20,N'Martin',0);

CREATE TABLE #LN (ID INT, Name NVARCHAR(50));
INSERT INTO #LN VALUES
(1,N'Petrov'),(2,N'Ivanov'),(3,N'Georgiev'),(4,N'Dimitrov'),(5,N'Stoyanov'),
(6,N'Todorov'),(7,N'Kolev'),(8,N'Angelov'),(9,N'Hristov'),(10,N'Marinov');

;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 200)
INSERT INTO dbo.Users (FirstName, LastName, Email, PasswordHash, Headline, Summary, CountryID, City, RegisteredAt, IsPremium)
SELECT f.Name,
       l.Name + CASE WHEN f.IsF = 1 THEN N'a' ELSE N'' END,
       LOWER(f.Name) + N'.' + LOWER(l.Name) + CAST(N.n AS NVARCHAR(10)) + N'@example.com',
       CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', N'Pass' + CAST(N.n AS NVARCHAR(10))), 2),
       CHOOSE((N.n % 10) + 1,
              N'Software Engineer | .NET & SQL', N'Data Analyst | Power BI', N'Product Manager | Agile',
              N'UX Designer | Figma', N'DevOps Engineer | Azure', N'Digital Marketing Specialist',
              N'HR Business Partner', N'Sales Manager | B2B', N'Business Analyst', N'QA Engineer | Automation'),
       CASE WHEN N.n % 3 <> 0
            THEN N'Професионалист с опит в екипна работа, ориентиран към резултати и непрекъснато учене.'
            ELSE NULL END,
       ((N.n - 1) % 10) + 1,
       CHOOSE(((N.n - 1) % 10) + 1, N'Sofia', N'Berlin', N'London', N'New York', N'Paris',
                                    N'Amsterdam', N'Madrid', N'Milan', N'Warsaw', N'Bucharest'),
       DATEADD(DAY, -(100 + (N.n * 97) % 1400), SYSDATETIME()),
       CASE WHEN N.n % 5 = 0 THEN 1 ELSE 0 END
FROM N
JOIN #FN f ON f.ID = ((N.n - 1) % 20) + 1
JOIN #LN l ON l.ID = ((N.n - 1) / 20) + 1
OPTION (MAXRECURSION 0);

DROP TABLE #FN;
DROP TABLE #LN;
GO

/* ---------- Умения на потребителите (4 на човек) ---------- */
INSERT INTO dbo.UserSkills (UserID, SkillID, ProficiencyLevel, EndorsementsCount)
SELECT u.UserID,
       ((u.UserID * 3 + k.k * 7) % 20) + 1,
       1 + ABS(CHECKSUM(NEWID())) % 5,
       ABS(CHECKSUM(NEWID())) % 60
FROM dbo.Users u
CROSS JOIN (VALUES (0),(1),(2),(3)) k(k);
GO

/* ---------- Трудов опит ---------- */
-- Текущо/последно работно място (всеки потребител)
INSERT INTO dbo.Experiences (UserID, CompanyID, Title, StartDate, EndDate, Description)
SELECT u.UserID,
       ((u.UserID * 7) % 15) + 1,
       CHOOSE((u.UserID % 10) + 1,
              N'Software Engineer', N'Data Analyst', N'Product Manager', N'UX Designer', N'DevOps Engineer',
              N'Marketing Specialist', N'HR Business Partner', N'Sales Manager', N'Business Analyst', N'QA Engineer'),
       d.s,
       CASE WHEN u.UserID % 3 = 0 THEN NULL
            ELSE DATEADD(DAY, 100 + (u.UserID * 29) % 500, d.s) END,
       N'Отговорности по проекти, анализ, комуникация с клиенти и работа в екип.'
FROM dbo.Users u
CROSS APPLY (SELECT DATEADD(DAY, -(730 + (u.UserID * 53) % 1500), CAST(GETDATE() AS DATE)) AS s) d;

-- Предишно работно място (за четните потребители)
INSERT INTO dbo.Experiences (UserID, CompanyID, Title, StartDate, EndDate, Description)
SELECT u.UserID,
       ((u.UserID * 11) % 15) + 1,
       CHOOSE((u.UserID % 5) + 1, N'Junior Specialist', N'Intern', N'Associate', N'Assistant', N'Trainee'),
       d.s,
       DATEADD(DAY, 200 + (u.UserID * 17) % 400, d.s),
       N'Първа професионална позиция, натрупване на опит.'
FROM dbo.Users u
CROSS APPLY (SELECT DATEADD(DAY, -(2400 + (u.UserID * 41) % 700), CAST(GETDATE() AS DATE)) AS s) d
WHERE u.UserID % 2 = 0;
GO

/* ---------- Образование ---------- */
INSERT INTO dbo.Education (UserID, SchoolName, Degree, FieldOfStudy, StartYear, EndYear)
SELECT UserID,
       CHOOSE((UserID % 8) + 1, N'Sofia University', N'Technical University of Sofia',
              N'University of National and World Economy', N'Plovdiv University', N'TU Berlin',
              N'University of London', N'Warsaw University of Technology', N'University of Amsterdam'),
       N'Bachelor',
       CHOOSE((UserID % 6) + 1, N'Computer Science', N'Business Administration', N'Marketing',
              N'Information Systems', N'Economics', N'Design'),
       2005 + UserID % 14,
       2009 + UserID % 14
FROM dbo.Users;

INSERT INTO dbo.Education (UserID, SchoolName, Degree, FieldOfStudy, StartYear, EndYear)
SELECT UserID,
       CHOOSE((UserID % 4) + 1, N'Sofia University', N'Technical University of Sofia',
              N'University of National and World Economy', N'University of London'),
       N'Master',
       CHOOSE((UserID % 3) + 1, N'Data Science', N'Management', N'Software Engineering'),
       2009 + UserID % 14,
       2011 + UserID % 14
FROM dbo.Users
WHERE UserID % 4 = 0;
GO

/* ---------- Връзки между потребители ---------- */
;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 200),
O AS (SELECT d FROM (VALUES (1),(2),(3),(5),(8),(13),(21),(34)) v(d)),
P AS (SELECT N.n AS u, N.n + O.d AS v FROM N CROSS JOIN O WHERE N.n + O.d <= 200)
INSERT INTO dbo.Connections (RequesterID, ReceiverID, Status, RequestedAt, AcceptedAt)
SELECT CASE WHEN p.u % 2 = 0 THEN p.v ELSE p.u END,
       CASE WHEN p.u % 2 = 0 THEN p.u ELSE p.v END,
       s.st,
       r.dt,
       CASE WHEN s.st = 'Accepted' THEN DATEADD(DAY, 1 + (p.u + p.v) % 10, r.dt) END
FROM P p
CROSS APPLY (SELECT CASE WHEN (p.u + p.v) % 10 < 7 THEN 'Accepted'
                         WHEN (p.u + p.v) % 10 < 9 THEN 'Pending'
                         ELSE 'Declined' END AS st) s
CROSS APPLY (SELECT DATEADD(DAY, -(20 + (p.u * 53 + p.v * 17) % 700), SYSDATETIME()) AS dt) r
OPTION (MAXRECURSION 0);
GO

/* ---------- Публикации (600) ---------- */
;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 600)
INSERT INTO dbo.Posts (UserID, Content, CreatedAt, Visibility)
SELECT ((N.n * 7) % 200) + 1,
       CHOOSE((N.n % 8) + 1,
              N'Развълнуван съм да споделя, че започвам нова позиция!',
              N'5 съвета за успешно интервю за работа.',
              N'Току-що завърших курс по анализ на данни с Power BI.',
              N'Нашият екип търси нови колеги - пишете ми!',
              N'Какво научих от последния си проект по разработка на софтуер.',
              N'Благодаря на всички, които дойдоха на конференцията вчера.',
              N'Мисли за баланса между работа и личен живот.',
              N'Тенденции в изкуствения интелект през тази година.'),
       DATEADD(MINUTE, -((20 * 1440) + (N.n * 7919) % (345 * 1440)), SYSDATETIME()),
       CASE WHEN N.n % 4 = 0 THEN 'Connections' ELSE 'Public' END
FROM N
OPTION (MAXRECURSION 0);
GO

/* ---------- Коментари (1200) ---------- */
;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 1200)
INSERT INTO dbo.Comments (PostID, UserID, Content, CreatedAt)
SELECT p.PostID,
       ((N.n * 11) % 200) + 1,
       CHOOSE((N.n % 5) + 1, N'Поздравления!', N'Много полезно, благодаря!', N'Напълно съм съгласен.',
                             N'Страхотна новина!', N'Интересна гледна точка.'),
       DATEADD(MINUTE, 30 + (N.n * 131) % 5000, p.CreatedAt)
FROM N
JOIN dbo.Posts p ON p.PostID = (N.n % 600) + 1
OPTION (MAXRECURSION 0);
GO

/* ---------- Реакции (5 на публикация) ---------- */
INSERT INTO dbo.PostReactions (PostID, UserID, ReactionType, ReactedAt)
SELECT p.PostID,
       ((p.PostID * 13 + k.k * 37) % 200) + 1,
       CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 6, 'Like','Celebrate','Support','Insightful','Funny','Love'),
       DATEADD(MINUTE, 5 + (p.PostID * 17 + k.k * 101) % 3000, p.CreatedAt)
FROM dbo.Posts p
CROSS JOIN (VALUES (0),(1),(2),(3),(4)) k(k);
GO

/* ---------- Обяви за работа (60) ---------- */
;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 60)
INSERT INTO dbo.Jobs (CompanyID, PostedByUserID, Title, Description, Location, EmploymentType, SalaryMin, SalaryMax, PostedAt, IsActive)
SELECT (N.n % 15) + 1,
       ((N.n * 3) % 200) + 1,
       CHOOSE((N.n % 10) + 1,
              N'Software Engineer', N'Data Analyst', N'Product Manager', N'UX Designer', N'DevOps Engineer',
              N'Marketing Specialist', N'HR Business Partner', N'Sales Manager', N'Business Analyst', N'QA Engineer'),
       N'Търсим мотивиран колега за динамичен екип. Предлагаме гъвкаво работно време и възможности за развитие.',
       CHOOSE((N.n % 10) + 1, N'Sofia, BG', N'Berlin, DE', N'London, GB', N'Remote', N'Paris, FR',
                              N'Amsterdam, NL', N'Madrid, ES', N'Plovdiv, BG', N'Warsaw, PL', N'Bucharest, RO'),
       CHOOSE((N.n % 4) + 1, 'Full-time', 'Part-time', 'Contract', 'Internship'),
       1500 + (N.n % 10) * 500,
       3000 + (N.n % 10) * 500 + (N.n % 5) * 500,
       DATEADD(DAY, -(40 + (N.n * 37) % 120), SYSDATETIME()),
       CASE WHEN N.n % 6 = 0 THEN 0 ELSE 1 END
FROM N
OPTION (MAXRECURSION 0);

-- Изисквани умения (3 на обява)
INSERT INTO dbo.JobSkills (JobID, SkillID)
SELECT j.JobID, ((j.JobID * 3 + k.k * 7) % 20) + 1
FROM dbo.Jobs j
CROSS JOIN (VALUES (0),(1),(2)) k(k);
GO

/* ---------- Кандидатури (800) ---------- */
;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 800)
INSERT INTO dbo.JobApplications (JobID, UserID, AppliedAt, Status, CoverLetter)
SELECT j.JobID,
       ((N.n / 60) * 13 + (N.n % 60) * 3) % 200 + 1,
       DATEADD(HOUR, (N.n * 31) % 500, j.PostedAt),
       CHOOSE(1 + (N.n * 7) % 5, 'Submitted', 'In Review', 'Interview', 'Offer', 'Rejected'),
       N'Здравейте, интересувам се от позицията и вярвам, че опитът ми е подходящ.'
FROM N
JOIN dbo.Jobs j ON j.JobID = (N.n % 60) + 1
OPTION (MAXRECURSION 0);
GO

/* ---------- Съобщения (500) ---------- */
;WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 500)
INSERT INTO dbo.Messages (SenderID, ReceiverID, Content, SentAt, IsRead)
SELECT (N.n * 7) % 200 + 1,
       ((N.n * 7) % 200 + 1 + (N.n % 150)) % 200 + 1,
       CHOOSE((N.n % 5) + 1, N'Здравей! Може ли да се свържем?', N'Благодаря за препоръката!',
                             N'Имаш ли време за кратък разговор тази седмица?',
                             N'Изпращам ти CV-то си, както се разбрахме.', N'Поздравления за новата позиция!'),
       DATEADD(MINUTE, -((N.n * 1237) % (90 * 1440)), SYSDATETIME()),
       N.n % 2
FROM N
OPTION (MAXRECURSION 0);
GO

/* ---------- Проверка ---------- */
SELECT 'Countries' AS TableName, COUNT(*) AS Rows FROM dbo.Countries UNION ALL
SELECT 'Users', COUNT(*) FROM dbo.Users UNION ALL
SELECT 'Companies', COUNT(*) FROM dbo.Companies UNION ALL
SELECT 'Skills', COUNT(*) FROM dbo.Skills UNION ALL
SELECT 'UserSkills', COUNT(*) FROM dbo.UserSkills UNION ALL
SELECT 'Experiences', COUNT(*) FROM dbo.Experiences UNION ALL
SELECT 'Education', COUNT(*) FROM dbo.Education UNION ALL
SELECT 'Connections', COUNT(*) FROM dbo.Connections UNION ALL
SELECT 'Posts', COUNT(*) FROM dbo.Posts UNION ALL
SELECT 'Comments', COUNT(*) FROM dbo.Comments UNION ALL
SELECT 'PostReactions', COUNT(*) FROM dbo.PostReactions UNION ALL
SELECT 'Jobs', COUNT(*) FROM dbo.Jobs UNION ALL
SELECT 'JobSkills', COUNT(*) FROM dbo.JobSkills UNION ALL
SELECT 'JobApplications', COUNT(*) FROM dbo.JobApplications UNION ALL
SELECT 'Messages', COUNT(*) FROM dbo.Messages;
GO

/* ---------- ДЕМОНСТРАЦИЯ (за защитата) ---------- */
-- Функции
SELECT dbo.fn_GetConnectionCount(1)     AS ConnectionsOfUser1,
       dbo.fn_GetProfileCompleteness(3) AS CompletenessOfUser3;

SELECT TOP 5 * FROM dbo.fn_RecommendedJobs(1) ORDER BY MatchingSkills DESC;

-- Процедури
DECLARE @newId INT;
EXEC dbo.sp_RegisterUser N'Test', N'User', N'test.user@example.com', N'hash123', 1, N'Sofia', N'Demo user', @newId OUTPUT;
SELECT @newId AS NewUserID;

EXEC dbo.sp_SendConnectionRequest @RequesterID = @newId, @ReceiverID = 1;
-- Втори опит (огледален) -> тригерът trg_Connections_PreventDuplicate ще върне грешка:
-- EXEC dbo.sp_SendConnectionRequest @RequesterID = 1, @ReceiverID = @newId;

DECLARE @cid INT = (SELECT ConnectionID FROM dbo.Connections WHERE RequesterID = @newId AND ReceiverID = 1);
EXEC dbo.sp_AcceptConnection @ConnectionID = @cid, @UserID = 1;

EXEC dbo.sp_ApplyForJob @JobID = 1, @UserID = @newId, @CoverLetter = N'Заинтересован съм от позицията.';
DECLARE @aid INT = (SELECT ApplicationID FROM dbo.JobApplications WHERE JobID = 1 AND UserID = @newId);
EXEC dbo.sp_UpdateApplicationStatus @ApplicationID = @aid, @NewStatus = 'Interview';   -- задейства тригер 2

EXEC dbo.sp_GetUserFeed @UserID = 1, @Top = 5;

-- Тригер 3
DELETE FROM dbo.Posts WHERE PostID = 1;

SELECT * FROM dbo.AuditLog ORDER BY AuditID DESC;
GO
