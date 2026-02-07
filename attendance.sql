CREATE DATABASE EMPLOYEE_ATTENDANCE ;
USE EMPLOYEE_ATTENDANCE;
SELECT * FROM employee_attendance;
SHOW TABLES;
-- Attendance Percentage 
select   employee_id, ROUND(
SUM(CASE WHEN  status = 'Present' THEN 1 ELSE 0 END)* 100 / COUNT(*) ,2) AS PERCENTAGE 
FROM employee_attendance
GROUP BY employee_id;

-- Identify employees whose attendance percentage is more than  75%.
SELECT 
    employee_id, PERCENTAGE
FROM
    (SELECT 
        employee_id,
            ROUND(SUM(CASE
                WHEN status = 'Present' THEN 1
                ELSE 0
            END) * 100 / COUNT(*), 2) AS PERCENTAGE
    FROM
        employee_attendance
    GROUP BY employee_id) t
WHERE
    PERCENTAGE > 75;

-- add column of percentage 
ALTER TABLE employee_attendance
ADD COLUMN percentage DECIMAL(5,2);
UPDATE employee_attendance ea
JOIN (
    SELECT 
        employee_id,
        ROUND(
            SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS pct
    FROM employee_attendance
    GROUP BY employee_id
) t
ON ea.employee_id = t.employee_id
SET ea.percentage = t.pct;


-- Compare average working hours for employees working Remote vs Office.
select location,
round(avg(timestampdiff(MINUTE, check_in_time , check_out_time) / 60),2) as working_hours from employee_attendance
where check_in_time is not null and check_out_time is not null 
group by location;




SELECT 
    location,
    ROUND(
        AVG(
            TIME_TO_SEC(
                TIMEDIFF(check_out_time, check_in_time)
            )
        ) / 3600,
        2
    ) AS avg_working_hours
FROM employee_attendance
WHERE check_in_time IS NOT NULL
  AND check_out_time IS NOT NULL
GROUP BY location;

-- Find departments where more than 20% of employees have attendance below 75%.
SELECT 
    department,
    COUNT(CASE WHEN attendance_pct < 75 THEN 1 END) * 100.0
    / COUNT(DISTINCT employee_id) AS low_attendance_pct
FROM (
    SELECT 
        employee_id,
        department,
        ROUND(
            SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) * 100.0
            / COUNT(*),
            2
        ) AS attendance_pct
    FROM employee_attendance
    GROUP BY employee_id, department
) t
GROUP BY department
HAVING low_attendance_pct > 20;

-- Monthly Attendance Trend
-- Show month-wise attendance percentage for the entire company.

SELECT 
    monthname, AVG(percentage)
FROM
    (SELECT 
        percentage,
            MONTHNAME(STR_TO_DATE(date, '%d/%m/%y')) AS monthname
    FROM
        employee_attendance) t
GROUP BY monthname ;




-- Top Consistent Employees
-- For each department, identify top 3 employees with the highest attendance count.
WITH monthly_attendance AS (
    SELECT
        employee_id,
        DATE_FORMAT(STR_TO_DATE(`date`, '%d/%m/%y'), '%Y-%m') AS month,
        ROUND(
            SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) * 100.0
            / COUNT(*),
            2
        ) AS monthly_attendance_pct
    FROM employee_attendance
    GROUP BY employee_id, month
)
SELECT
    employee_id,
    month,
    previous_month_attendance,
    monthly_attendance_pct AS current_month_attendance
FROM (
    SELECT
        employee_id,
        month,
        monthly_attendance_pct,
        LAG(monthly_attendance_pct) OVER (
            PARTITION BY employee_id
            ORDER BY month
        ) AS previous_month_attendance
    FROM monthly_attendance
) t
WHERE monthly_attendance_pct < previous_month_attendance;





-- Which location (Office/Remote) has higher absenteeism?
select  location , count(status) as number_absenteeism from employee_attendance
where status = 'Absent'
group by location;





-- List employees who were absent more than 5 days in any single month .
SELECT 
    employee_id,
    MONTHname(str_to_date(`date` ,'%d/%m/%y')) AS month,
    year(str_to_date(`date` ,'%d/%m/%y'))as year,
    COUNT(*) AS absent_days
FROM employee_attendance
WHERE status = 'Absent'
GROUP BY employee_id, month ,year
HAVING COUNT(*) >= 3;


-- compare each employee's attendance with department average using window functions.
select department as DEPARTMENT,
 AVG_DEPARTMENT_PERCENTAGE,
 dense_rank() over(order by AVG_DEPARTMENT_PERCENTAGE desc) as `Rank_Department` from 
(select  department , avg(percentage)as AVG_DEPARTMENT_PERCENTAGE from employee_attendance
group by department )t;


-- Find the top departments with highest absenteeism rate 
select department , COUNT(*)AS ABSENT_EMPLOYEES from employee_attendance
where status = 'Absent'
GROUP BY DEPARTMENT
order by ABSENT_EMPLOYEES DESC LIMIT 3;


