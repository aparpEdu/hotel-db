CREATE ROLE hotel_admin;

GRANT SELECT ON ALL TABLES IN SCHEMA public to hotel_admin;

GRANT INSERT ON TABLE client TO hotel_admin;
GRANT DELETE ON TABLE client TO hotel_admin;

GRANT INSERT ON TABLE reservation TO hotel_admin;
GRANT DELETE ON TABLE reservation TO hotel_admin;

GRANT INSERT ON TABLE client_service TO hotel_admin;
GRANT INSERT ON TABLE service TO hotel_admin;
GRANT UPDATE ON TABLE service TO hotel_admin;
GRANT DELETE ON TABLE service TO hotel_admin;

GRANT DELETE ON TABLE room TO hotel_admin;


CREATE USER alexander WITH ENCRYPTED PASSWORD '!Alexander123';
CREATE USER pavel WITH ENCRYPTED PASSWORD '!Pavel123';
CREATE USER nikolay WITH ENCRYPTED PASSWORD '!Nikolay123';

GRANT hotel_admin TO alexander;
GRANT hotel_admin TO pavel;
GRANT hotel_admin TO nikolay;

-- SELECT table_schema, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE grantee = 'hotel_admin' AND table_schema = 'public';

CREATE ROLE hotel_employee;

GRANT SELECT ON ALL TABLES IN SCHEMA public to hotel_employee;
GRANT INSERT ON TABLE client TO hotel_employee;
GRANT INSERT ON TABLE reservation TO hotel_employee;
GRANT INSERT ON TABLE client_service TO hotel_employee;

-- SELECT table_schema, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE grantee = 'hotel_employee' AND table_schema = 'public';

CREATE USER employee1 WITH ENCRYPTED PASSWORD '!Employee1';
CREATE USER employee2 WITH ENCRYPTED PASSWORD '!Employee2';
CREATE USER employee3 WITH ENCRYPTED PASSWORD '!Employee3';

GRANT hotel_employee TO employee1;
GRANT hotel_employee TO employee2;
GRANT hotel_employee TO employee3;

