------------------------------------------------------
-- COMP9311 24T2 Project 1 
-- SQL and PL/pgSQL 
-- Solution Template
-- Name:Yang Zhang
-- zID:z5503515
------------------------------------------------------
-- Note: Before submission, please check your solution on the nw-syd-vxdb server using the check file.


-- Q1:
DROP VIEW IF EXISTS Q1 CASCADE;
CREATE VIEW Q1(code) as
SELECT DISTINCT subjects.code
FROM subjects
JOIN orgunits ON subjects.offeredby = orgunits.id
WHERE subjects.longname LIKE '%Database%'
AND orgunits.longname = 'School of Computer Science and Engineering'
;

-- Q2:
DROP VIEW IF EXISTS Q2 CASCADE;
CREATE VIEW Q2(id) as
SELECT DISTINCT courses.id
FROM courses
JOIN classes ON courses.id = classes.course
JOIN class_types ON classes.ctype = class_types.id
JOIN rooms ON classes.room = rooms.id
WHERE class_types.name = 'Laboratory'
AND rooms.longname = 'MB-G4'
;

-- Q3:
DROP VIEW IF EXISTS Q3 CASCADE;
CREATE VIEW Q3(name) as
SELECT DISTINCT people.name
FROM people
JOIN course_enrolments ON people.id = course_enrolments.student
JOIN subjects ON course_enrolments.course = subjects.id
WHERE course_enrolments.mark >= 95
AND subjects.code = 'COMP3311'
;

-- Q4:
DROP VIEW IF EXISTS Q4 CASCADE;
CREATE VIEW Q4(code) as
SELECT DISTINCT subjects.code
FROM subjects
JOIN courses ON subjects.id = courses.subject
JOIN classes ON courses.id = classes.course
JOIN rooms ON classes.room = rooms.id
JOIN room_facilities ON rooms.id = room_facilities.room
JOIN facilities ON room_facilities.facility = facilities.id
WHERE subjects.code LIKE 'COMM%'
AND facilities.description = 'Student wheelchair access'
;

-- Q5:
DROP VIEW IF EXISTS Q5 CASCADE;
CREATE VIEW Q5(unswid) as
SELECT DISTINCT people.unswid
FROM people
JOIN course_enrolments ON people.id = course_enrolments.student
JOIN subjects ON course_enrolments.course = subjects.id
WHERE course_enrolments.grade = 'HD'
AND subjects.code LIKE 'COMP9%'
GROUP BY people.unswid
HAVING COUNT(DISTINCT subjects.code) = COUNT(DISTINCT CASE WHEN course_enrolments.grade = 'HD' THEN subjects.code END)
;

-- Q6:
DROP VIEW IF EXISTS Q6 CASCADE;
CREATE VIEW Q6(code, avg_mark) as
SELECT subjects.code, ROUND(AVG(course_enrolments.mark), 2) AS avg_mark
FROM subjects
JOIN courses ON subjects.id = courses.subject
JOIN course_enrolments ON courses.id = course_enrolments.course
JOIN orgunits ON subjects.offeredby = orgunits.id
JOIN semesters ON courses.semester = semesters.id
WHERE subjects.career = 'UG'
AND subjects.uoc < 6
AND orgunits.longname = 'School of Civil and Environmental Engineering'
AND course_enrolments.mark >= 50
AND semesters.year = '2008'
GROUP BY subjects.code
ORDER BY avg_mark DESC
;

-- Q7:
DROP VIEW IF EXISTS Q7 CASCADE;
CREATE VIEW Q7(student, course) as
SELECT course_enrolments.student AS student, courses.id AS course
FROM course_enrolments
JOIN courses ON course_enrolments.course = courses.id
JOIN subjects ON courses.subject = subjects.id
JOIN semesters ON courses.semester = semesters.id
WHERE subjects.code LIKE 'COMP93%'
AND semesters.year = '2008'
AND semesters.term = '1'
AND course_enrolments.mark = (SELECT MAX(mark) 
                              FROM course_enrolments 
                              WHERE course_enrolments.course = courses.id)
;

-- Q8:
DROP VIEW IF EXISTS Q8 CASCADE;
CREATE VIEW Q8(course_id, staffs_names) as 
SELECT courses.id AS course_id, STRING_AGG(people.name, ', ' ORDER BY people.name) AS staffs_names
FROM courses
JOIN course_enrolments ON courses.id = course_enrolments.course
JOIN course_staff ON courses.id = course_staff.course
JOIN people ON course_staff.staff = people.id
WHERE people.title = 'AProf'
GROUP BY courses.id
HAVING COUNT(DISTINCT course_enrolments.student) >= 650
AND COUNT(DISTINCT people.id) = 2
;


-- Q9
DROP FUNCTION IF EXISTS Q9 CASCADE;
CREATE or REPLACE FUNCTION Q9(subject_code text) returns text
as $$
DECLARE
    prereqs TEXT;
BEGIN
    SELECT STRING_AGG(DISTINCT _prereq, ', ' ORDER BY _prereq) INTO prereqs
    FROM subjects
    WHERE code = subject_code;
    
    IF prereqs IS NULL THEN
        RETURN 'There is no prerequisite for subject ' || subject_code || '.';
    ELSE
        RETURN 'The prerequisites for subject ' || subject_code || ' are ' || prereqs || '.';
    END IF;
END;
$$ language plpgsql;


-- Q10
DROP FUNCTION IF EXISTS Q10 CASCADE;
CREATE or REPLACE FUNCTION Q10(subject_code text) returns text
as $$
DECLARE
    prereqs TEXT;
BEGIN
    WITH RECURSIVE PrereqTree AS (
        SELECT code, _prereq
        FROM subjects
        WHERE code = subject_code
        UNION
        SELECT s.code, s._prereq
        FROM subjects s
        INNER JOIN PrereqTree pt ON s.code = pt._prereq
    )
    SELECT STRING_AGG(DISTINCT _prereq, ', ' ORDER BY _prereq) INTO prereqs
    FROM PrereqTree;

    IF prereqs IS NULL THEN
        RETURN 'There is no prerequisite for subject ' || subject_code || '.';
    ELSE
        RETURN 'The prerequisites for subject ' || subject_code || ' are ' || prereqs || '.';
    END IF;
END;
$$ language plpgsql;
