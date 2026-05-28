CREATE ROLE student_role;
GRANT USAGE ON SCHEMA public TO student_role;
GRANT SELECT ON film, actor TO student_role;
CREATE USER student1 WITH PASSWORD 'pass123';
GRANT student_role TO student1;
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'film';
