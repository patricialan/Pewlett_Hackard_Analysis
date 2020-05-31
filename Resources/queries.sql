-- Part 1: retiring employees

-- 1A. Find # of employees retiring (if currently 54-68 years-old)
SELECT COUNT(first_name)
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1965-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- 1B. Find # of employees retiring (if currently 64-68 years-old)
SELECT COUNT(first_name)
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- 1C. Create table of retiring employees
SELECT emp_no, first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1965-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- 1D. Join retirement_info and dept_emp tables using aliases & create new table (current employees about to retire)
SELECT ri.emp_no,
	ri.first_name,
    ri.last_name,
	de.to_date 
INTO current_emp
FROM retirement_info as ri
LEFT JOIN dept_emp as de
ON ri.emp_no = de.emp_no
WHERE de.to_date = ('9999-01-01');

-- 1E. # retiring employees by title (will have duplicates for emp_no)
SELECT ce.emp_no,
    ce.first_name,
    ce.last_name,
    ti.title,
    ti.from_date,
    s.salary
INTO title_emp
FROM current_emp AS ce
INNER JOIN titles AS ti
ON (ce.emp_no = ti.emp_no)
INNER JOIN salaries AS s
ON (ti.emp_no = s.emp_no)
ORDER BY ce.emp_no;

-- 1F. Partition the data to show only most recent title per employee
SELECT emp_no,
 first_name,
 last_name,
 title,
 from_date,
 salary
INTO recentTitle_emp
FROM
 (SELECT emp_no,
 first_name,
 last_name,
 title,
 from_date,
 salary, ROW_NUMBER() OVER
 (PARTITION BY (emp_no)
 ORDER BY from_date DESC) rn
 FROM title_emp
 ) tmp WHERE rn = 1
ORDER BY title;

-- 1G. Create table: # retirees by title
SELECT COUNT(emp_no), title
INTO countByTitle_emp
FROM recentTitle_emp
GROUP BY title
ORDER BY title;

---------------------------------------------------------------------------------

-- Part 2: individuals being hired

-- 2A. Create table: employees most recently hired with hire date & department name & salary start dates
SELECT e.emp_no, 
    e.first_name, 
    e.last_name, 
    e.hire_date,
    s.from_date,
    s.to_date,
    s.salary,
    d.dept_name,
    d.dept_no
INTO duplicates_hired
FROM employees AS e
INNER JOIN salaries AS s
ON (e.emp_no = s.emp_no)
INNER JOIN dept_emp AS de
ON (e.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no)
ORDER BY hire_date DESC;

-- 2B. Combine duplicate rows (combine department names & department IDs for same employee)
SELECT emp_no, 
    first_name, 
    last_name, 
    hire_date,
    from_date,
    to_date,
    salary,
    string_agg(dept_name, '/') AS dept_name,
    string_agg(dept_no, '/') AS dept_no
INTO hired
FROM duplicates_hired
GROUP BY emp_no, 
    first_name, 
    last_name, 
    hire_date,
    from_date,
    to_date,
    salary
ORDER BY hire_date DESC;

-- 2C. Count of employees hired in the most recent month and year in records (January 2000)
SELECT COUNT(emp_no)
FROM hired
WHERE (hire_date BETWEEN '2000-01-01' AND '2000-01-31');

---------------------------------------------------------------------------------

-- Part 3: individuals available for mentorship role

-- 3A. Create table: employees eligible to be mentors (specific birthdate range)
SELECT re.emp_no,
    re.first_name,
    re.last_name,
    re.title,
    re.from_date,
    ti.to_date
INTO duplicates_mentor_emp
FROM recentTitle_emp AS re
INNER JOIN titles AS ti
ON (re.emp_no = ti.emp_no)
INNER JOIN employees AS e
ON (ti.emp_no = e.emp_no)
WHERE (e.birth_date BETWEEN '1965-01-01' AND '1965-12-31')
ORDER BY e.emp_no;

-- 3B. Create table: employees eligible to be mentors (specific birthdate range) & discard duplicates (keep most recent title)
SELECT emp_no,
 first_name,
 last_name,
 title,
 from_date,
 to_date
INTO mentor_emp
FROM
 (SELECT emp_no,
 first_name,
 last_name,
 title,
 from_date,
 to_date, ROW_NUMBER() OVER
 (PARTITION BY (emp_no)
 ORDER BY to_date DESC) rn
 FROM duplicates_mentor_emp
 ) tmp WHERE rn = 1
ORDER BY emp_no;

---------------------------------------------------------------------------------

-- Part 4: Additional queries

-- Current managers of each department
SELECT d.dept_no,
	d.dept_name,
     dm.emp_no,
     dm.from_date,
     dm.to_date
FROM departments as d
INNER JOIN dept_manager as dm
ON d.dept_no = dm.dept_no
WHERE to_date = '9999-01-01'
ORDER BY emp_no;

-- Current managers of each department who are potential retirees
SELECT d.dept_no,
	d.dept_name,
     dm.emp_no,
     dm.from_date,
     dm.to_date
FROM departments as d
INNER JOIN dept_manager as dm
ON d.dept_no = dm.dept_no
INNER JOIN employees as e
ON e.emp_no = dm.emp_no
WHERE (to_date = '9999-01-01')
AND (birth_date BETWEEN '1952-01-01' AND '1965-12-31')
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31')
ORDER BY emp_no;

-- Joining tables departments and dept_manager using aliases
SELECT d.dept_name,
     dm.emp_no,
     dm.from_date,
     dm.to_date
FROM departments as d
INNER JOIN dept_manager as dm
ON d.dept_no = dm.dept_no;

-- Create table: count of retiring employees by department #
SELECT COUNT(ce.emp_no), de.dept_no
INTO count_emp
FROM current_emp as ce
LEFT JOIN dept_emp as de
ON ce.emp_no = de.emp_no
GROUP BY de.dept_no
ORDER BY de.dept_no;

-- Create table of employee info for retirees
SELECT e.emp_no,
	e.first_name,
    e.last_name,
	e.gender,
	s.salary,
	de.to_date
INTO emp_info
FROM employees as e
INNER JOIN salaries as s
ON (e.emp_no = s.emp_no)
INNER JOIN dept_emp as de
ON (e.emp_no = de.emp_no)
WHERE (e.birth_date BETWEEN '1952-01-01' AND '1955-12-31')
    AND (e.hire_date BETWEEN '1985-01-01' AND '1988-12-31')
    AND (de.to_date = '9999-01-01');

-- Create table of retiring managers by department
SELECT  dm.dept_no,
        d.dept_name,
        dm.emp_no,
        ce.last_name,
        ce.first_name,
        dm.from_date,
        dm.to_date
INTO manager_info
FROM dept_manager AS dm
    INNER JOIN departments AS d
        ON (dm.dept_no = d.dept_no)
    INNER JOIN current_emp AS ce
        ON (dm.emp_no = ce.emp_no);

-- Create table of retirees by department
SELECT ce.emp_no,
    ce.first_name,
    ce.last_name,
    d.dept_name	
INTO dept_info
FROM current_emp AS ce
INNER JOIN dept_emp AS de
ON (ce.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no);

-- Create table of retirees for just Sales department
SELECT ce.emp_no,
    ce.first_name,
    ce.last_name,
    d.dept_name
INTO sales_info
FROM current_emp AS ce
INNER JOIN dept_emp AS de
ON (ce.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no)
WHERE (de.dept_no = 'd007')
    AND (d.dept_name = 'Sales');

-- Create table of retirees for Sales & Development departments
SELECT ce.emp_no,
    ce.first_name,
    ce.last_name,
    d.dept_name
INTO salesDev_info
FROM current_emp AS ce
INNER JOIN dept_emp AS de
ON (ce.emp_no = de.emp_no)
INNER JOIN departments AS d
ON (de.dept_no = d.dept_no)
WHERE de.dept_no IN ('d007', 'd005')
    AND d.dept_name IN ('Sales', 'Development')
ORDER BY d.dept_name;