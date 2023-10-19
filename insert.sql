INSERT INTO public.client (first_name, last_name, email, phone_number, birthday, eu_gdpr, uin)
VALUES ('Emily', 'Johnson', 'emily.j@example.com', '555-123-4567', '1990-05-15', true, 'ABC1234567'),
       ('Michael', 'Davis', 'michael.d@example.com', '555-987-6543', '1985-08-22', true, 'DEF9876543'),
       ('Sara', 'Brown', 'sara.b@example.com', '555-234-5678', '1992-11-10', true, 'GHI2345678'),
       ('Daniel', 'White', 'daniel.w@example.com', '555-876-5432', '1980-04-30', true, 'JKL8765432'),
       ('Laura', 'Lee', 'laura.l@example.com', '555-345-6789', '1988-09-02', true, 'MNO3456789'),
       ('Matthew', 'Young', 'matthew.y@example.com', '555-654-3210', '1995-02-18', true, 'PQR6543210'),
       ('Olivia', 'Moore', 'olivia.m@example.com', '555-432-1098', '1991-07-25', true, 'STU4321098'),
       ('James', 'Williams', 'james.w@example.com', '555-210-9876', '1983-12-07', true, 'VWX2109876'),
       ('Ava', 'Martinez', 'ava.m@example.com', '555-789-0123', '1993-03-14', true, 'YZA7890123'),
       ('Ethan', 'Garcia', 'ethan.g@example.com', '555-901-2345', '1987-06-29', true, 'BCD9012345');


INSERT INTO public.service (name, price, season_start_date, season_end_date, is_seasonal)
VALUES ('Penthouse Suite', 500.00, '2023-01-01', '2023-12-31', TRUE),
       ('Executive Room', 180.00, NULL, NULL, FALSE),
       ('Honeymoon Package', 250.00, NULL, NULL, FALSE),
       ('Meeting Room Rental', 300.00, NULL, NULL, FALSE),
       ('Airport Shuttle', 50.00, NULL, NULL, FALSE),
       ('Spa Package', 120.00, NULL, NULL, FALSE),
       ('Gym Access', 75.00, NULL, NULL, FALSE),
       ('City Tour', 90.00, NULL, NULL, FALSE),
       ('Car Rental', 200.00, NULL, NULL, FALSE),
       ('Concierge Service', 30.00, NULL, NULL, FALSE);

INSERT INTO public.client_service (service_id, client_id)
VALUES (1, 1),
       (2, 2),
       (3, 3),
       (4, 4),
       (5, 5),
       (6, 6),
       (7, 7),
       (8, 8),
       (9, 9),
       (10, 10);

INSERT INTO public.room_type (room_type)
VALUES ('King Suite'),
       ('Twin Room'),
       ('Presidential Suite'),
       ('VIP Suite'),
       ('Accessible Room'),
       ('Adjoining Rooms'),
       ('Balcony Room'),
       ('Cabana'),
       ('Studio Suite'),
       ('Bungalow');

INSERT INTO public.room (room_type_id, price_per_night, room_capacity)
VALUES (4, 300.00, 2),
       (5, 100.00, 1),
       (6, 150.00, 2),
       (7, 180.00, 2),
       (8, 250.00, 2),
       (9, 200.00, 2),
       (10, 280.00, 2),
       (1, 450.00, 2),
       (2, 120.00, 2),
       (3, 600.00, 2);

INSERT INTO public.payment_type (payment_type)
VALUES ('Cash'),
       ('Debit Card'),
	   ('Credit Card'),
	   ('Bitcoin'),
       ('Apple Pay'),
       ('Google Pay'),
       ('Venmo'),
       ('Cryptocurrency'),
       ('Ethereum'),
       ('Litecoin'),
       ('Dogecoin'),
       ('Zelle'),
       ('Stripe');

INSERT INTO public.payment (type_id, total_sum)
VALUES (4, 75.00),
       (5, 150.00),
       (6, 200.00),
       (7, 100.00),
       (8, 50.00),
       (9, 300.00),
       (10, 180.00),
       (1, 500.00),
       (2, 120.00),
       (3, 250.00);

INSERT INTO public.reservation (room_id, client_id, payment_id, reservation_date, check_in_date, check_out_date)
VALUES (4, 4, 10, '2023-10-18', '2023-11-05', '2023-11-10'),
       (5, 5, 9, '2023-10-18', '2023-10-25', '2023-10-30'),
       (6, 6, 8, '2023-10-18', '2023-11-01', '2023-11-03'),
       (7, 7, 1, '2023-10-18', '2023-10-20', '2023-10-22'),
       (8, 8, 2, '2023-10-18', '2023-10-22', '2023-10-25'),
       (9, 9, 3, '2023-10-18', '2023-10-23', '2023-10-28'),
       (10, 10, 4, '2023-10-18', '2023-10-21', '2023-10-24'),
       (1, 1, 5, '2023-10-18', '2023-10-25', '2023-10-28'),
       (2, 2, 6, '2023-10-18', '2023-10-30', '2023-11-02'),
       (3, 3, 7, '2023-10-18', '2023-10-29', '2023-11-01');

INSERT INTO public.reservation_review (reservation_id, client_id, comment, rating)
VALUES (4, 4, 'Beautiful view from the room!', 5),
       (5, 5, 'Very clean and comfortable.', 4),
       (6, 6, 'Enjoyed the spa services.', 4),
       (7, 7, 'Friendly staff and great service.', 5),
       (8, 8, 'Convenient location, will come back!', 4),
       (9, 9, 'Spacious room, excellent amenities.', 5),
       (10, 10, 'Loved the balcony and beach access.', 5),
       (1, 1, 'Perfect stay, highly recommended!', 5),
       (2, 2, 'Great experience, will recommend to friends.', 4),
       (3, 3, 'Helpful concierge, enjoyed the city tour.', 5);
