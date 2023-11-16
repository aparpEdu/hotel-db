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