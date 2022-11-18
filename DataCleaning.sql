/****** 1. After importing dataset, set PRIMARY & FOREIGN KEYS contraint to form a relationship between the tables ******/
ALTER TABLE HRAnalytics..HRDataset
ADD CONSTRAINT PK_EmpID PRIMARY KEY (EmpID);

ALTER TABLE HRAnalytics..EmployeeDetails
ADD CONSTRAINT FK_EmployeeDetails_EmpID FOREIGN KEY (EmpID)
REFERENCES HRAnalytics..HRDataset (EmpID);

ALTER TABLE HRAnalytics..EmploymentHistory
ADD CONSTRAINT FK_EmploymentHistory_EmpID FOREIGN KEY (EmpID)
REFERENCES HRAnalytics..HRDataset (EmpID);

ALTER TABLE HRAnalytics..EmployeeScore
ADD CONSTRAINT FK_EmployeeScore_EmpID FOREIGN KEY (EmpID)
REFERENCES HRAnalytics..HRDataset (EmpID);

-----------------------------------------------------------------------------------------------------------------------------


/****** 2. Convert to appropriate data type to reduce memory space usage ******/

-- convert DOB from nvarchar(50) to date
ALTER TABLE HRAnalytics..EmployeeDetails
ALTER COLUMN DOB Date;

-- convert FromDiversityJobFair from nvarchar(50) to bit 
ALTER TABLE HRAnalytics..EmployeeDetails
ALTER COLUMN FromDiversityJobFair bit;

-- convert EmpSatisfaction from nvarchar(50) to tinyint
ALTER TABLE HRAnalytics..EmployeeScore
ALTER COLUMN EmpSatisfaction tinyint;

-- convert SpecialProjectsCount from nvarchar(50) to smallint
ALTER TABLE HRAnalytics..EmployeeScore
ALTER COLUMN SpecialProjectsCount smallint;

-- convert LastPerformanceReview_Date from nvarchar(50) to date
ALTER TABLE HRAnalytics..EmployeeScore
ALTER COLUMN SpecialProjectsCount smallint;

-- convert DateofHire from nvarchar(50) to date
ALTER TABLE HRAnalytics..EmploymentHistory
ALTER COLUMN DateofHire date;

-- convert DateofTermination from nvarchar(50) to date
ALTER TABLE HRAnalytics..EmploymentHistory
ALTER COLUMN DateofTermination date;

-- convert Absences from from nvarchar(50) to int
ALTER TABLE HRAnalytics..HRDataset
ALTER COLUMN Absences int;


----------------------------------------------------------------------------------------------------------------------------


/****** 3. Split Full Name into First Name and Last Name columns ******/
-- NOTE: ManagerName and Employee_Name are in different format 

-- Split ManagerName into First and Last Name columns
ALTER TABLE HRAnalytics..HRDataset
ADD ManagerFirstName nvarchar(50);

UPDATE HRAnalytics..HRDataset
SET ManagerFirstName = PARSENAME(REPLACE(ManagerName, ' ', '.'), 2)

ALTER TABLE HRAnalytics..HRDataset
ADD ManagerLastName nvarchar(50);

UPDATE HRAnalytics..HRDataset
SET ManagerLastName = PARSENAME(REPLACE(ManagerName, ' ', '.'), 1)

-- Handle SPECIAL CASE with Name contains middle Name
UPDATE HRAnalytics..HRDataset
SET ManagerFirstName = PARSENAME(ManagerName, 2)
WHERE ManagerName = 'Brandon R. LeBlanc'

-- Handle SPECIAL CASE with 'Board of Directors' as ManagerName instead of actual manager's name
-- There are 4 employees with 'Director' in their Title/Position
SELECT hr.EmpID, hr.Position
FROM HRAnalytics..HRDataset hr
WHERE hr.Position LIKE '%Director%'

-- Remove incorrect First Name resulting from PARSENAME function earlier
UPDATE HRAnalytics..HRDataset
SET ManagerFirstName = NULL
WHERE ManagerName = 'Board of Directors'

-- Remove incorrect Last Name resulting from PARSENAME function earlier
UPDATE HRAnalytics..HRDataset
SET ManagerLastName = NULL
WHERE ManagerName = 'Board of Directors'


-- Split Employee_Name into First and Last Name columns
ALTER TABLE HRAnalytics..EmployeeDetails
ADD Employee_FirstName nvarchar(50);

UPDATE HRAnalytics..EmployeeDetails
SET Employee_FirstName = PARSENAME(REPLACE(Employee_Name, ',', '.'), 1)

ALTER TABLE HRAnalytics..EmployeeDetails
ADD Employee_LastName nvarchar(50);

UPDATE HRAnalytics..EmployeeDetails
SET Employee_LastName = PARSENAME(REPLACE(Employee_Name, ',', '.'), 2);

-- Handle SPECIAL CASE with unwanted spaces in front of the Employee_FirstName resulting from PARSENAME function earlier
UPDATE HRAnalytics..EmployeeDetails
SET Employee_FirstName = 
	(CASE 
		WHEN Employee_FirstName LIKE ' %' THEN TRIM(Employee_FirstName)
		ELSE Employee_FirstName
	 END);

-------------------------------------------------------------------------------------------------------------------------------


/*** 4. Check if ManagerName are included in the Employee_Name column since they are employees too ***/
-- 6 out of 21 ManagerName are not included the Employee_Name, 1 of them are the Board of Directors
-- ideally in real life, we would like to obtain employee details on these 5 managers and add them to the Employee List
-- in our case, this doesn't affect what we are trying to achieve with this dataset so we will ignore it for now
SELECT DISTINCT(hr.ManagerName)
FROM HRAnalytics..HRDataset hr
WHERE hr.ManagerName NOT IN ( 
SELECT DISTINCT(hr.ManagerName)
FROM HRAnalytics..HRDataset hr, HRAnalytics..EmployeeDetails emp
WHERE (hr.ManagerFirstName) IN (emp.Employee_FirstName)
	  AND (hr.ManagerLastName) IN (emp.Employee_LastName));
 
-- alternative method
SELECT DISTINCT(hr.ManagerName)
FROM HRAnalytics..HRDataset hr
WHERE hr.ManagerFirstName NOT IN 
(
	SELECT DISTINCT(emp.Employee_FirstName)
	FROM HRAnalytics..EmployeeDetails emp
)
UNION ALL 
SELECT DISTINCT(hr.ManagerName)
FROM HRAnalytics..HRDataset hr
WHERE hr.ManagerLastName NOT IN 
(
	SELECT DISTINCT(emp.Employee_LastName)
	FROM HRAnalytics..EmployeeDetails emp
);

------------------------------------------------------------------------------------------------------------------------------


/*** 5. Add a Age column calculated from DOB ***/
ALTER TABLE HRAnalytics..EmployeeDetails
ADD Age smallint;

UPDATE HRAnalytics..EmployeeDetails
SET Age = DATEDIFF(year, DOB, (SELECT getdate()))

-----------------------------------------------------------------------------------------------------------------------------


/*** 6. Check for any duplicates ***/
-- there should not be two or more employees with the exact same name and DOB
SELECT Employee_FirstName, Employee_LastName, DOB, COUNT(*) AS EmpCount
FROM HRAnalytics..EmployeeDetails
GROUP BY Employee_FirstName, Employee_LastName, DOB
HAVING COUNT(*) > 1

-- alternative method with CTE
WITH RowNum_CTE AS (
SELECT *, 
	ROW_NUMBER() OVER
	(PARTITION BY Employee_FirstName, Employee_LastName, DOB
	 ORDER BY EmpID) RowNum
FROM HRAnalytics..EmployeeDetails )

SELECT * FROM RowNum_CTE
WHERE RowNum > 1

----------------------------------------------------------------------------------------------------------------------------


/*** Delete Unused Columns ***/ 
--ALTER TABLE HRAnalytics..
--DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict;
