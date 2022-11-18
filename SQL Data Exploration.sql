--------------------------------------------------------------------------------------------------------------
/******************************** GENERAL DATA EXPLORTION ON EMPLOYEEs' DATA *****************************************/
--------------------------------------------------------------------------------------------------------------

/*** 1. Total Employee ***/
SELECT COUNT(*) AS TotalEmp
FROM HRAnalytics..HRDataset

---------------------------------------------------------------------------------------------------------------------------------

/*** 2.  Employee Average Performance Score ***/
-- Assigned: Exceeds = 4, Fully Meets = 3, Needs Improvement = 2, PIP = 1

WITH PerformanceScoreRank_CTE AS (
	SELECT EmpID, PerformanceScore, DENSE_RANK() OVER (ORDER BY PerformanceScore DESC) AS PerformanceScoreRank
	FROM HRAnalytics..EmployeeScore )

SELECT CAST(CAST(SUM(PerformanceScoreRank) AS DECIMAL)/ CAST(Count(*) As DECIMAL) AS DECIMAL(3,2)) AS AvgPerformanceScore
FROM PerformanceScoreRank_CTE


-------------------------------------------------------------------------------------------------------------------------------

/*** 3. Employee Average Satisfaction Score ***/

SELECT CAST(CAST(SUM(EmpSatisfaction) AS DECIMAL)/ CAST(Count(*) As DECIMAL) AS DECIMAL(3,2)) AS AvgSatisfactionScore
FROM HRAnalytics..EmployeeScore


-------------------------------------------------------------------------------------------------------------------------------

/*** 4. Employee Average Absence Rate ***/
-- I'm going to assume the employee absence records are for this year
-- there are 250 working days in year 2022

SELECT CAST(CAST(SUM(Absences) AS DECIMAL) / (250.0 * Count(*)) * 100.0 AS DECIMAL (5,2)) AvgAbsenceRate
FROM HRAnalytics..HRDataset


--------------------------------------------------------------------------------------------------------------------------------

/*** 5. Gender Distribution ***/

-- Gender Distribution in Number
SELECT DISTINCT(Sex), 
	   Count(*) OVER (PARTITION BY Sex) AS NumOfEmp
FROM HRAnalytics..EmployeeDetails emp


-- Gender Distribution in Percentage
SELECT --Sex, 
	   100 * SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END)/ COUNT(*) male_percent,
	   100 * SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END)/ COUNT(*) female_percent
FROM HRAnalytics..EmployeeDetails emp


--------------------------------------------------------------------------------------------------------------------------------

/*** 6. Gender Distribution across departments ***/

-- Gender Distribution in Number
SELECT DISTINCT(Department), Sex, 
	   Count(*) OVER (PARTITION BY Department, Sex) AS NumOfEmp
FROM HRAnalytics..EmployeeDetails emp
JOIN HRAnalytics..HRDataset hr
	 ON emp.EmpID = hr.EmpID


-- Gender Distribution in Percentage
SELECT DISTINCT(Department), 
	   CAST(100.0 * SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END)/ COUNT(*) AS DECIMAL (5,2)) male_percent,
	   CAST(100.0 * SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END)/ COUNT(*) AS DECIMAL(5,2)) female_percent
FROM HRAnalytics..EmployeeDetails emp
JOIN HRAnalytics..HRDataset hr
	 ON emp.EmpID = hr.EmpID
GROUP BY Department;


------------------------------------------------------------------------------------------------------------------------------

/*** 7. Employees Length of Employment ***/
WITH DaysOfEmployment_CTE AS (
SELECT EmpID, DateofHire, DateofTermination, --YearsOfEmployment, MonthsOfEmployment,
CASE
	WHEN DateofTermination IS NOT NULL THEN DATEDIFF(day, DateofHire, DateofTermination) -  
	(CASE WHEN DATEADD(day, DATEDIFF(day, DateofHire, DateofTermination), DateofHire) > DateofTermination
		  THEN 1 ELSE 0
	 END)
	
	ELSE DATEDIFF(day, DateofHire, GETDATE()) - 
	(CASE WHEN DATEADD(day, DATEDIFF(day, DateofHire, GETDATE()), DateofHire) > DateofTermination
		  THEN 1 ELSE 0
	 END)
END AS DaysOfEmployment
--FROM MonthsOfEmployment_CTE )
FROM HRAnalytics..EmploymentHistory )

SELECT emp.EmpID, emp.Employee_Name, hr.Position, hr.Department, cte.DateofHire, cte.DateofTermination, 
	   /*cte.YearsOfEmployment, cte.MonthsOfEmployment,*/ cte.DaysOfEmployment
FROM DaysOfEmployment_CTE cte
JOIN HRAnalytics..EmployeeDetails emp
	 ON cte.EmpID = emp.EmpID
JOIN HRAnalytics..HRDataset hr
	 ON emp.EmpID = hr.EmpID
ORDER BY DaysOfEmployment DESC


----------------------------------------------------------------------------------------------------------------------------------

/*** 8. Number of active employees on a given day ***/
SELECT cal.CalendarDate AS CalendarDate, COUNT(*) AS NumofEmp--,emp.DateofHire, emp.DateofTermination, 
FROM HRAnalytics..EmploymentHistory emp
CROSS JOIN HRAnalytics..Calendar cal
WHERE cal.CalendarDate >= emp.DateofHire
	  AND (cal.CalendarDate <= emp.DateofTermination
		   OR emp.DateofTermination IS NULL)
GROUP BY cal.CalendarDate--, emp.DateofHire, emp.DateofTermination
ORDER BY cal.CalendarDate


---------------------------------------------------------------------------------------------------------------------------------

/*** 9. Number of Employee by Location ***/
SELECT EmpID, Employee_Name, State, Zip
FROM HRAnalytics..EmployeeDetails

-- 276 out of 311 employees live in MA which means the company is based in MA
SELECT State, COUNT(*) NumOfEmp
FROM HRAnalytics..EmployeeDetails
GROUP BY State


---------------------------------------------------------------------------------------------------------------------------------

/*** 10. Age Distribution ***/
-- find out the age range of the employees
SELECT MIN(Age) Min_Age, MAX(Age) Max_Age
FROM HRAnalytics..EmployeeDetails

-- divided ages into age groups
WITH AgeGroup_CTE AS (
SELECT EmpID, Age, Sex,
	   CASE WHEN CONVERT(nvarchar(50), Age) BETWEEN 15 AND 24 THEN '15-24 year-old' 
			WHEN CONVERT(nvarchar(50), Age) BETWEEN 25 AND 34 THEN '25-34 year-old'
			WHEN CONVERT(nvarchar(50), Age) BETWEEN 35 AND 44 THEN '35-44 year-old'
			WHEN CONVERT(nvarchar(50), Age) BETWEEN 45 AND 54 THEN '44-45 year-old'
			WHEN CONVERT(nvarchar(50), Age) BETWEEN 55 AND 64 THEN '55-65 year old'
			WHEN CONVERT(nvarchar(50), Age) >= 65 THEN '65+'
	   ELSE CONVERT(nvarchar(50), Age)
	   END AS AgeGroup 
FROM HRAnalytics..EmployeeDetails)

SELECT *
FROM AgeGroup_CTE
ORDER BY AgeGroup, Sex

-- Number of employees in each Age group
SELECT AgeGroup, COUNT(*) NumOfEmp
FROM AgeGroup_CTE
GROUP BY AgeGroup


------------------------------------------------------------------------------------------------------------------------------------

/*** 11. Number of employee by Ethnicity ***/
SELECT RaceDesc, Count(*) NumOfEmp
FROM HRAnalytics..EmployeeDetails
GROUP BY RaceDesc


-----------------------------------------------------------------------------------------------------------------------------------

/*** 12. Recruitment Resources ***/
SELECT RecruitmentSource, Count(*) NumOfEmp
FROM HRAnalytics..EmployeeDetails
GROUP BY RecruitmentSource


-----------------------------------------------------------------------------------------------------------------------------------

/*** 13. Average Pay in each Department ***/
SELECT DISTINCT(Department), Position, AVG(Salary) AvgSalary
FROM HRAnalytics..HRDataset
GROUP BY Position, Department


