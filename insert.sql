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


INSERT INTO public.service (name, price, offer_start_month, offer_end_month, is_limited_time_offer)
VALUES ('Penthouse Suite', 500.00, 1, 10, TRUE),
       ('Executive Room', 180.00, NULL, NULL, FALSE),
       ('Honeymoon Package', 250.00, NULL, NULL, FALSE),
       ('Meeting Room Rental', 300.00, NULL, NULL, FALSE),
       ('Airport Shuttle', 50.00, NULL, NULL, FALSE),
       ('Spa Package', 120.00, NULL, NULL, FALSE),
       ('Gym Access', 75.00, NULL, NULL, FALSE),
       ('City Tour', 90.00, NULL, NULL, FALSE),
       ('Car Rental', 200.00, NULL, NULL, FALSE),
       ('Concierge Service', 30.00, NULL, NULL, FALSE);

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

 INSERT INTO public.status (status_name)
 VALUES ('ACTIVE'),
        ('CANCELLED'),
        ('COMPLETED'),
        ('FAILED');

INSERT INTO public.room (room_type_id, price_per_night, room_capacity, room_number)
VALUES (4, 300.00, 2, '101A'),
       (5, 100.00, 1, '101B'),
       (6, 150.00, 2, '102A'),
       (7, 180.00, 2, '102B'),
       (8, 250.00, 2, '103A'),
       (9, 200.00, 2, '103B'),
       (10, 280.00, 2, '104A'),
       (1, 450.00, 2, '104B'),
       (2, 120.00, 2, '201A'),
       (3, 600.00, 2, '201B');

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

INSERT INTO public.payment (type_id, status_id)
VALUES (4, 1),
       (5, 1),
       (6, 1),
       (7, 1),
       (8, 1),
       (9, 1),
       (10, 1),
       (1, 1),
       (2, 1),
       (3, 1);

INSERT INTO public.reservation (room_id, client_id, payment_id, status_id, number_of_guests, reservation_date, check_in_date, check_out_date)
VALUES (4, 4, 10, 1, 2, '2024-10-18', '2024-11-17', '2024-11-25'),
       (5, 5, 9, 1, 2, '2024-10-18', '2024-11-17', '2024-11-30'),
       (6, 6, 8, 1, 2, '2024-10-18', '2024-11-01', '2024-11-03'),
       (7, 7, 1, 1, 2, '2023-12-15', '2023-12-15', '2024-01-15'),
       (8, 8, 2, 1, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 day'),
       (9, 9, 3, 1, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '2 days'),
       (10, 10, 4, 1, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '3 days'),
       (1, 1, 5, 1, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL'7 days'),
       (2, 2, 6, 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL'5 days'),
       (3, 3, 7, 1, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '2 days');

INSERT INTO public.reservation_service (service_id, reservation_id)
VALUES
       (2, 9),
       (3, 10),
       (4, 1),
       (5, 2),
       (6, 3),
       (7, 4),
       (8, 5),
       (9, 6),
       (10, 7);



INSERT INTO public.reservation_review (reservation_id, client_id, comment, rating, date_posted)
VALUES (1, 4, 'Beautiful view from the room!', 5, CURRENT_TIMESTAMP),
       (2, 5, 'Very clean and comfortable.', 4, CURRENT_TIMESTAMP),
       (3, 6, 'Enjoyed the spa services.', 4, CURRENT_TIMESTAMP),
       (4, 7, 'Friendly staff and great service.', 5, CURRENT_TIMESTAMP),
       (5, 8, 'Convenient location, will come back!', 4, CURRENT_TIMESTAMP),
       (6, 9, 'Spacious room, excellent amenities.', 5, CURRENT_TIMESTAMP),
       (7, 10, 'Loved the balcony and beach access.', 5, CURRENT_TIMESTAMP),
       (8, 1, 'Perfect stay, highly recommended!', 5, CURRENT_TIMESTAMP),
       (9, 2, 'Great experience, will recommend to friends.', 4, CURRENT_TIMESTAMP),
       (10, 3, 'Helpful concierge, enjoyed the city tour.', 5, CURRENT_TIMESTAMP);
