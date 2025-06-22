
/********************************************************************************************************************
			Summarizing the final_attendance_2024_leave_realistic  to  attendance_data
********************************************************************************************************************/
select count(*) from final_attendance_2024_leave_realistic limit 50;

select * from final_attendance_2024_leave_realistic limit 50;


CREATE TABLE attendance_data (
    employee_id INT,
    monthyr TEXT,
    total_work_days INT,
    sick_leave_cnt INT,
    absent_count INT,
    present_count INT,
    vacation_count INT,
    late_login INT,
    WFH INT,
    OT_Hours INT,
    avg_login_hours DECIMAL(5 , 2 )
);
INSERT INTO techsphere.attendance_data (
    employee_id, monthyr, total_work_days, sick_leave_cnt, absent_count, 
    present_count, vacation_count, late_login, WFH, OT_Hours, avg_login_hours
)
SELECT 
    employee_id, monthyr, COUNT(*) AS total_work_days, 
    SUM(sick_leave), SUM(days_absent_x), SUM(days_present_x), 
    SUM(vacation_leaves), SUM(late_check_ins), SUM(work_from_home), 
    SUM(overtime_hours), ROUND(AVG(total_hours), 2)
FROM final_attendance_2024_leave_realistic
GROUP BY employee_id, monthyr;

select * from attendance_data limit 50;

select * from final_attendance_2024_leave_realistic limit 20;

/********************************************************************************************************************
			Summarizing the final_attendance_2024_leave_realistic  to  attendance_data
********************************************************************************************************************/

select * from employee_details;
select * from attendance_data;
select * from employee_qty_review;
select * from project_assignments;
select * from training_records;


/********************************************************************************************************************
														ANALSYSIS Tasks 
********************************************************************************************************************/
-- Analysis Tasks 
-- 1. Employee Productivity Analysis:                                                              
-- - Identify employees with the highest total hours worked and least absenteeism. 
-- 2. Departmental Training Impact: - Analyze how training programs improve departmental performance. 
-- 3. Project Budget Efficiency: - Evaluate the efficiency of project budgets by calculating costs per hour worked. 
-- 4. Attendance Consistency: - Measure attendance trends and identify departments with significant deviations. 
-- 5. Training and Project Success Correlaion: - Link training technologies with project milestones to assess the real-world impact of training. 
-- 6. High-Impact Employees: - Identify employees who significantly contribute to high-budget projects while maintaining excellent 
-- performance scores. 
-- 7. Cross Analysis of Training and Project Success - Identify employees who have undergone training in specific technologies and contributed to high
-- performing projects using those technologies.


/********************************************************************************************************************
											Task 1  :
-- 1. Employee Productivity Analysis:                                                              
-- - Identify employees with the highest total hours worked and least absenteeism. 
********************************************************************************************************************/


select distinct employee_id from attendance_data ; 
-- count 119 -- 
create table techsphere_op.1_Employee_Productivity as 
SELECT employee_id,
sum(total_work_days) as total_work_day_cnt,
SUM(present_count) AS total_present,
SUM(total_work_days-present_count) AS total_absences,
sum(present_count*avg_login_hours) as total_hours

FROM attendance_data
GROUP BY employee_id
ORDER BY total_hours DESC, total_absences ;

/********************************************************************************************************************
Task 2 : Departmental Training Impact: - Analyze how training programs improve departmental performance. 
********************************************************************************************************************/

-- Departmental Training Participation and Quality :

create table techsphere_op.2_dep_training_impact_1 as
SELECT 
    Department_Id, 
    COUNT(*) AS total_trainings,
    SUM(CASE WHEN completion_status = 'Completed' THEN 1 ELSE 0 END) AS trainings_completed,
    round(AVG(feedback_score),2) AS avg_feedback_score,
    round(AVG(Trainer_Rating),2) AS avg_trainer_rating
--     AVG(CAST(Trainer_Rating AS DECIMAL(3,2))) AS avg_trainer_rating
FROM training_records
GROUP BY Department_Id;


create table techsphere_op.2_dep_training_impact_2 as
SELECT 
    t.Department_Id,
    p.Client_Satisfaction,
    COUNT(DISTINCT p.project_id) AS total_projects,
    COUNT(DISTINCT t.employee_id) AS unique_trained_employees,
    round(avg(p.milestones_achieved),2) AS avg_milestones_achieved,
    round(AVG(p.`Project Risk Score`),2) AS avg_project_risk_score
FROM training_records t
JOIN project_assignments p ON t.employee_id = p.employee_id
GROUP BY t.Department_Id, p.Client_Satisfaction
ORDER BY t.Department_Id, 
         CASE 
           WHEN p.Client_Satisfaction = 'High' THEN 1
           WHEN p.Client_Satisfaction = 'Medium' THEN 2
           WHEN p.Client_Satisfaction = 'Low' THEN 3
           ELSE 4
         END;

create table techsphere_op.2_dep_training_impact_3 as
SELECT 
    e.Department_Id,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT p.project_id) AS total_projects,
    SUM(CASE WHEN p.Client_Satisfaction = 'High' THEN 1 ELSE 0 END) AS high_satisfaction_projects,
    SUM(CASE WHEN p.Client_Satisfaction = 'Medium' THEN 1 ELSE 0 END) AS medium_satisfaction_projects,
    SUM(CASE WHEN p.Client_Satisfaction = 'Low' THEN 1 ELSE 0 END) AS low_satisfaction_projects,
    t.total_trainings,
    t.trainings_completed,
    t.avg_feedback_score
FROM employee_details e
LEFT JOIN (
    SELECT 
        Department_Id,
        COUNT(*) AS total_trainings,
        SUM(CASE WHEN completion_status = 'Completed' THEN 1 ELSE 0 END) AS trainings_completed,
        round(AVG(feedback_score),2) AS avg_feedback_score
    FROM training_records
    GROUP BY Department_Id
) t 
ON e.Department_Id = t.Department_Id
LEFT JOIN project_assignments p ON e.employee_id = p.employee_id
GROUP BY e.Department_Id, t.total_trainings, t.trainings_completed, t.avg_feedback_score
ORDER BY e.Department_Id;




/********************************************************************************************************************
Task 3 : Project Budget Efficiency: -
 Evaluate the efficiency of project budgets by calculating costs per hour worked.
********************************************************************************************************************/

create table techsphere_op.3_project_budget_efficiency as 
SELECT project_id, project_name, budget, hours_worked, 
       round((budget / hours_worked),2) AS cost_per_hour
FROM project_assignments
ORDER BY cost_per_hour ASC;


/********************************************************************************************************************
Task 4 : Attendance Consistency: -
	Measure attendance trends and identify departments with significant deviations.
********************************************************************************************************************/


create table techsphere_op.4_Attendance_Consistency as

SELECT a.employee_id, e.department_id,
sum(a.total_work_days) as total_work_day_cnt,
SUM(a.present_count) AS total_present,
SUM(a.total_work_days-a.present_count) AS total_absences,
sum(a.present_count*a.avg_login_hours) as total_hours

FROM attendance_data a join employee_details e
on a.employee_id=e.employee_id
GROUP BY employee_id, department_id
ORDER BY total_hours DESC, total_absences ;



/********************************************************************************************************************
Task 5 : Training and Project Success Correlation: -
	Link training technologies with project milestones to assess the real-world impact of training. 
********************************************************************************************************************/


create table techsphere_op.5_Project_Success as
select 
department_id,
-- program_id,
employee_id,
completion_status,
client_satisfaction,
project_status,

round(avg(milestones_achieved),2) as avg_milestone,
round(sum(milestones_achieved),2) as sum_milestone,
round(avg(`Project Risk Score`),2) as avg_risk_score,
round(sum(training_cost_dollars),2) as total_training_cost,
round(avg(hours_worked),2) as avg_hour_per_project
from 

(select 
t.Department_Id,
-- t.program_id,
t.employee_id,
t.training_cost_currency,
p.project_status,
cost,
round(case 
 when t.training_cost_currency='GBP' then cost*1.35
 when t.training_cost_currency='USD' then cost*1
 when t.training_cost_currency='CAD' then cost*0.73
 when t.training_cost_currency='EUR' then cost*1.15 
 else 0 
 end) as training_cost_dollars,
 t.completion_status,
-- 1 as train_done,
p.milestones_achieved,
p.hours_worked,
p.Client_Satisfaction,
p.`Project Risk Score`
 from project_assignments p 
 
 left join training_records t
on p.employee_id=t.employee_id) as q

group by department_id, employee_id,
-- program_id,
completion_status, client_satisfaction, project_status
-- where completion_status = 'Completed';




/********************************************************************************************************************
Task 6 : High-Impact Employees: -
- Identify employees who significantly contribute to high-budget projects while maintaining excellent
********************************************************************************************************************/

create table techsphere_op.6_High_Impact_Employees as
select 
e.employee_id,
e.employee_name,
e.performance_score,  -- excellent
e.age,
e.department_id,
p.project_status,
p.budget,
p.client_satisfaction 
from 
employee_details e join project_assignments p
on e.employee_id=p.employee_id

-- where performance_score="Excellent"
order by budget desc;



/********************************************************************************************************************
Task 7 : Cross Analysis of Training and Project Success : -
- Identify employees who have undergone training in specific technologies and contributed to high
performing projects using those technologies. 
********************************************************************************************************************/

create table techsphere_op.7_Cross_Analysis as 
WITH tech_split AS (
  SELECT 
    t.employee_id,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.technologies_covered, ',', numbers.n), ',', -1)) AS single_tech
  FROM training_records t
  JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  ) AS numbers
    ON CHAR_LENGTH(t.technologies_covered) - CHAR_LENGTH(REPLACE(t.technologies_covered, ',', '')) >= numbers.n - 1
)

SELECT 
  t.employee_id,
  t.employee_name,
  t.technologies_covered,
  p.project_name,
  p.`Project Risk Score`,
  p.Client_Satisfaction,
  p.milestones_achieved,
  p.budget
FROM 
  training_records t
JOIN project_assignments p 
  ON t.employee_id = p.employee_id
JOIN tech_split ts 
  ON ts.employee_id = t.employee_id
WHERE 
  CONCAT(',', p.technologies_used, ',') LIKE CONCAT('%,', ts.single_tech, ',%')
ORDER BY 
  p.budget DESC;



/********************************************************************************************************************
    END OF TASKS & QUERIES
********************************************************************************************************************/

