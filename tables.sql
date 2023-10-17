CREATE TABLE IF NOT EXISTS public.client (
    id SERIAL PRIMARY KEY NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.service
(
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(50) NOT NULL,
    price numeric(10,2) NOT NULL,
    season_start_date date,
    season_end_date date,
    is_seasonal boolean NOT NULL
);

CREATE TABLE IF NOT EXISTS public.client_service
(
	service_id INTEGER NOT NULL,
	client_id INTEGER NOT NULL,
	FOREIGN KEY (service_id) REFERENCES public.service (id),
    FOREIGN KEY (client_id) REFERENCES public.client (id)
);


CREATE TABLE IF NOT EXISTS public.room_type (
    room_type_id SERIAL PRIMARY KEY NOT NULL,
    room_type VARCHAR(255) NOT NULL UNIQUE
);


CREATE TABLE IF NOT EXISTS public.room (
    room_id SERIAL PRIMARY KEY,
    room_type_id INT NOT NULL,
    price_per_night NUMERIC(10, 2) NOT NULL,
    room_capacity NUMERIC(2, 0) NOT NULL,
    FOREIGN KEY (room_type_id) REFERENCES public.room_type (room_type_id)
);

CREATE TABLE IF NOT EXISTS public.payment_type (
	id SERIAL PRIMARY KEY NOT NULL,
	payment_type VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.payment (
    payment_id SERIAL PRIMARY KEY NOT NULL,
    type_id INT NOT NULL,
    total_sum NUMERIC(10,2) NOT NULL,
	FOREIGN KEY (type_id) REFERENCES public.payment_type (id)
);



CREATE TABLE IF NOT EXISTS public.reservation (
    id SERIAL PRIMARY KEY NOT NULL,
    room_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    payment_id INTEGER NOT NULL UNIQUE,
    reservation_date DATE NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    FOREIGN KEY (room_id) REFERENCES public.room (room_id),
    FOREIGN KEY (client_id) REFERENCES public.client (id),
    FOREIGN KEY (payment_id) REFERENCES public.payment (payment_id)
);

CREATE TABLE IF NOT EXISTS public.reservation_review (
	id SERIAL PRIMARY KEY NOT NULL,
	reservation_id INTEGER NOT NULL UNIQUE,
	client_id INTEGER NOT NULL,
	comment VARCHAR(500) NOT NULL,
	rating INTEGER NOT NULL,
	FOREIGN KEY (reservation_id) REFERENCES public.reservation (id),
	FOREIGN KEY (client_id) REFERENCES public.client (id)
);

