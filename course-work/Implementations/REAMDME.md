# LinkedIn – Курсова работа по Софтуерно Моделиране и Анализ

| | |
|---|---|
| **Факултетен номер** | 2401322007 |
| **Студент** | Петър Паунов |
| **Проект** | LinkedIn – релационна база данни, Data Warehouse и Power BI доклад |
| **Технологии** | MS SQL Server, draw.io, Power BI Desktop |

## Кратко описание

Проектът моделира професионалната социална мрежа **LinkedIn**. Обхваща:

- **Потребители и профили** – лични данни, трудов опит, образование, умения.
- **Мрежа** – връзки между потребители, съобщения.
- **Съдържание** – публикации, коментари, реакции.
- **Работа** – компании, обяви, изисквани умения, кандидатури.

Проектът се състои от:

1. **Концептуален модел** (Chen notation), **логически модел** (Crow's Foot) и **модел на Data Warehouse** (UML) в draw.io.
2. **Релационна база данни `LinkedInDB`** – 16 таблици, 3 функции, 6 съхранени процедури, 3 тригера и тестови данни.
3. **Data Warehouse `LinkedInDW`** – 3 таблици факти и 7 таблици измерения, зареждани чрез ETL скрипт.
4. **Power BI доклад** с визуализации върху Data Warehouse.

## Структура на репото

| Файл | Описание |
|---|---|
| `LinkedIn_Diagrams.drawio` | Диаграми (3 страници): концептуален, логически, Data Warehouse |
| `01_LinkedInDB_Schema.sql` | Създава `LinkedInDB`: таблици, функции, процедури, тригери |
| `02_LinkedInDB_SeedData.sql` | Попълва базата с данни и съдържа демонстрационни заявки |
| `03_LinkedInDW_DataWarehouse.sql` | Създава `LinkedInDW` и зарежда данните (ETL) |
| `LinkedIn_Report.pbix` | Power BI доклад |

## Логически модел

**Основни таблици:** `Countries`, `Users`, `Companies`, `Skills`, `Experiences`, `Education`, `Posts`, `Comments`, `Jobs`, `Messages`, `AuditLog`.

**Връзки много към много (със свързващи таблици):**

| Връзка | Таблица |
|---|---|
| Потребители ↔ Умения | `UserSkills` |
| Обяви ↔ Умения | `JobSkills` |
| Потребители ↔ Обяви | `JobApplications` |
| Потребители ↔ Потребители | `Connections` |
| Потребители ↔ Публикации | `PostReactions` |

## Изисквания

- Microsoft SQL Server 2016 или по-нова версия (напр. Express или Developer).
- SQL Server Management Studio (SSMS).
- Power BI Desktop.
- draw.io (app.diagrams.net) или desktop приложението.
- Права за създаване на бази данни (`CREATE DATABASE`).

## Инсталация и стартиране

### 1. Създаване на базата данни
1. Отворете SSMS и се свържете със сървъра.
2. Отворете `01_LinkedInDB_Schema.sql` и го изпълнете (**F5**).
   > Скриптът **изтрива и създава наново** базата `LinkedInDB`, ако вече съществува.

### 2. Попълване с данни
1. Отворете `02_LinkedInDB_SeedData.sql` и го изпълнете (**F5**).
2. В края се показва таблица с броя редове във всяка таблица. Следват демонстрационни заявки за функциите, процедурите и тригерите.

### 3. Data Warehouse
1. Отворете `03_LinkedInDW_DataWarehouse.sql` и го изпълнете (**F5**).
2. Скриптът създава `LinkedInDW` и зарежда данните от `LinkedInDB`.

> Скриптовете се изпълняват **по реда 01 → 02 → 03**.

### 4. Power BI доклад
1. Отворете `LinkedIn_Report.pbix` в Power BI Desktop.
2. Ако се появи грешка за връзка: Home → Transform data → Data source settings → Change Source и въведете името на вашия сървър (напр. `localhost`). База: `LinkedInDW`.
3. Натиснете **Refresh**.

### 5. Диаграми
Отворете `LinkedIn_Diagrams.drawio` в draw.io. Страниците са: *Концептуален модел (Chen)*, *Логически модел (Crow's Foot)*, *Data Warehouse (UML)*.

## Функции (Functions)

Ползват се с префикс `dbo.`. Скаларните се викат в `SELECT`/`WHERE`, а табличната – във `FROM`.

| Функция | Тип | Параметри | Връща |
|---|---|---|---|
| `dbo.fn_GetConnectionCount` | Скаларна | `@UserID INT` | Брой приети връзки на потребителя (`INT`) |
| `dbo.fn_GetProfileCompleteness` | Скаларна | `@UserID INT` | Пълнота на профила 0–100 (по 20 т. за заглавие, резюме, опит, образование, поне 3 умения) |
| `dbo.fn_RecommendedJobs` | Таблична | `@UserID INT` | Активни обяви, съвпадащи с уменията на потребителя, с брой съвпадения (`MatchingSkills`) |

**Примери:**

```sql
USE LinkedInDB;

SELECT dbo.fn_GetConnectionCount(1)     AS Connections;
SELECT dbo.fn_GetProfileCompleteness(3) AS Completeness;

SELECT TOP 5 *
FROM dbo.fn_RecommendedJobs(1)
ORDER BY MatchingSkills DESC;
```

## Съхранени процедури (Stored Procedures)

Викат се с `EXEC`.

| Процедура | Параметри | Описание | Грешки |
|---|---|---|---|
| `sp_RegisterUser` | `@FirstName, @LastName, @Email, @PasswordHash, @CountryID, @City, @Headline, @NewUserID OUTPUT` | Регистрира нов потребител и връща неговия ID | 50001 – имейлът съществува; 50002 – невалидна държава |
| `sp_SendConnectionRequest` | `@RequesterID, @ReceiverID` | Изпраща покана за връзка | 50010 – връзка със себе си; 50011 – несъществуващ потребител; 50030 – дублирана покана (тригер) |
| `sp_AcceptConnection` | `@ConnectionID, @UserID` | Получателят приема чакаща покана | 50012 – няма такава покана |
| `sp_ApplyForJob` | `@JobID, @UserID, @CoverLetter` | Кандидатстване за активна обява | 50020 – обявата не е активна; 50021 – вече е кандидатствано |
| `sp_UpdateApplicationStatus` | `@ApplicationID, @NewStatus` | Сменя статуса на кандидатура (записва се в `AuditLog`) | 50022 – не е намерена |
| `sp_GetUserFeed` | `@UserID, @Top = 20` | Публикации на потребителя и на неговите връзки, с брой реакции и коментари | – |

**Примери:**

```sql
USE LinkedInDB;

-- Регистрация (с изходен параметър)
DECLARE @newId INT;
EXEC dbo.sp_RegisterUser N'Anna', N'Petrova', N'anna.petrova@example.com',
                         N'hash123', 1, N'Sofia', N'Data Analyst', @newId OUTPUT;

-- Връзки
EXEC dbo.sp_SendConnectionRequest @RequesterID = @newId, @ReceiverID = 1;
DECLARE @cid INT = (SELECT ConnectionID FROM dbo.Connections
                    WHERE RequesterID = @newId AND ReceiverID = 1);
EXEC dbo.sp_AcceptConnection @ConnectionID = @cid, @UserID = 1;

-- Кандидатстване и смяна на статус
EXEC dbo.sp_ApplyForJob @JobID = 1, @UserID = @newId, @CoverLetter = N'Заинтересован съм.';
DECLARE @aid INT = (SELECT ApplicationID FROM dbo.JobApplications
                    WHERE JobID = 1 AND UserID = @newId);
EXEC dbo.sp_UpdateApplicationStatus @ApplicationID = @aid, @NewStatus = 'Interview';

-- Новинарски поток
EXEC dbo.sp_GetUserFeed @UserID = 1, @Top = 5;
```

## Тригери (Triggers)

| Тригер | Таблица | Тип | Действие |
|---|---|---|---|
| `trg_Connections_PreventDuplicate` | `Connections` | `INSTEAD OF INSERT` | Забранява дублирани и огледални покани (A→B и B→A) |
| `trg_JobApplications_AuditStatus` | `JobApplications` | `AFTER UPDATE` | Записва в `AuditLog` всяка смяна на статус |
| `trg_Posts_AuditDelete` | `Posts` | `AFTER DELETE` | Архивира в `AuditLog` информация за изтрити публикации |

Преглед на резултата: `SELECT * FROM dbo.AuditLog ORDER BY AuditID DESC;`

## Data Warehouse

**Таблици факти (3):**

| Таблица | Грануларност | Мерки |
|---|---|---|
| `FactJobApplications` | една кандидатура | `ApplicationCount`, `DaysSincePosted` |
| `FactPostEngagement` | една публикация | `ReactionsCount`, `CommentsCount` |
| `FactConnections` | една покана за връзка | `ConnectionCount`, `DaysToAccept` |

**Таблици измерения (7):** `DimDate`, `DimUser`, `DimCompany`, `DimJob`, `DimCountry`, `DimApplicationStatus`, `DimConnectionStatus`.

`DimUser` е измерение с различни роли (автор, кандидат, подател, получател). `DimCountry` е свързано към `DimUser` и `DimCompany` (снежинка).

## Power BI доклад

Докладът е изграден върху `LinkedInDW` и съдържа визуализации за:

- кандидатури по месеци, по статус и по компании;
- ангажираност на публикациите във времето;
- потребители по държава и пълнота на профилите;
- процент приети връзки и средно време за приемане.

Основни DAX мерки: `Total Applications`, `Offer Rate`, `Total Engagement`, `Acceptance Rate`, `Avg Days To Accept`.
