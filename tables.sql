CREATE TABLE IF NOT EXISTS public.client (
    id SERIAL PRIMARY KEY NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number CHAR(13) NOT NULL,
	birthday DATE NOT NULL CHECK (birthday < CURRENT_DATE),
	eu_gdpr BOOLEAN NOT NULL,
	uin CHAR(10) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.service
(
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    season_start_month SMALLINT CHECK(season_start_month >= 1 AND season_start_month <= 12),
    season_end_month SMALLINT CHECK(season_end_month >= 1 AND season_end_month <= 12),
    is_seasonal BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS public.client_service
(
	service_id INTEGER NOT NULL,
	client_id INTEGER NOT NULL,
	FOREIGN KEY (service_id) REFERENCES public.service (id),
    FOREIGN KEY (client_id) REFERENCES public.client (id)
);

CREATE TABLE IF NOT EXISTS public.room_type (
    id SERIAL PRIMARY KEY NOT NULL,
    room_type VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.room (
    id SERIAL PRIMARY KEY,
    room_number VARCHAR(50) NOT NULL UNIQUE,
    room_type_id INT NOT NULL,
    price_per_night NUMERIC(10, 2) NOT NULL,
    room_capacity NUMERIC(2, 0) NOT NULL,
    FOREIGN KEY (room_type_id) REFERENCES public.room_type (id)
);

CREATE TABLE IF NOT EXISTS public.status (
    id SERIAL PRIMARY KEY NOT NULL,
    status_name VARCHAR NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.payment_type (
	id SERIAL PRIMARY KEY NOT NULL,
	payment_type VARCHAR(255) NOT NULL UNIQUE
);
--TODO total sum trigger
CREATE TABLE IF NOT EXISTS public.payment (
    id SERIAL PRIMARY KEY NOT NULL,
    type_id INT NOT NULL,
    status_id INT NOT NULL,
    total_sum NUMERIC(10,2) NOT NULL,
--     payment_date TIMESTAMP NOT NULL CHECK(payment_date >= CURRENT_TIMESTAMP),
	FOREIGN KEY (type_id) REFERENCES public.payment_type (id),
	FOREIGN KEY (status_id) REFERENCES public.status (id)
);


CREATE TABLE IF NOT EXISTS public.reservation (
    id SERIAL PRIMARY KEY NOT NULL,
    room_id INTEGER NOT NULL,
    client_id INTEGER NOT NULL,
    payment_id INTEGER NOT NULL UNIQUE,
    status_id INTEGER NOT NULL,
    reservation_date TIMESTAMP NOT NULL CHECK (reservation_date >= CURRENT_TIMESTAMP),
    check_in_date TIMESTAMP NOT NULL CHECK (check_in_date >= CURRENT_DATE),
    check_out_date TIMESTAMP NOT NULL CHECK (check_out_date >= CURRENT_TIMESTAMP),
    FOREIGN KEY (room_id) REFERENCES public.room (id),
    FOREIGN KEY (client_id) REFERENCES public.client (id),
    FOREIGN KEY (payment_id) REFERENCES public.payment (id),
    FOREIGN KEY (status_id) REFERENCES public.status (id)
);

CREATE TABLE IF NOT EXISTS public.reservation_review (
    id SERIAL PRIMARY KEY NOT NULL,
    reservation_id INTEGER NOT NULL UNIQUE,
    client_id INTEGER NOT NULL,
    comment VARCHAR(500) NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    date_posted TIMESTAMP NOT NULL CHECK (date_posted >= CURRENT_TIMESTAMP),
    FOREIGN KEY (reservation_id) REFERENCES public.reservation (id),
    FOREIGN KEY (client_id) REFERENCES public.client (id)
);

