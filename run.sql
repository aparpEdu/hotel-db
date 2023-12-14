--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_current_limited_service(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_current_limited_service() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.service s
        WHERE s.id = NEW.service_id
        AND s.is_limited_time_offer = TRUE
        AND (
            (s.offer_start_month IS NULL AND s.offer_end_month IS NULL) OR
            (
                (s.offer_start_month IS NOT NULL AND s.offer_end_month IS NULL)
                AND EXTRACT(MONTH FROM CURRENT_DATE) >= s.offer_start_month
            )
            OR
            (
                (s.offer_start_month IS NULL AND s.offer_end_month IS NOT NULL)
                AND EXTRACT(MONTH FROM CURRENT_DATE) <= s.offer_end_month
            )
            OR
            (
                EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN s.offer_start_month AND s.offer_end_month
            )
        )
    ) THEN
        RETURN NEW;
    ELSE

        IF NOT EXISTS (
            SELECT 1
            FROM public.service
            WHERE id = NEW.service_id
            AND is_limited_time_offer = FALSE
        ) THEN
            RAISE EXCEPTION 'The service is not in its limited period for the current month!';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_current_limited_service() OWNER TO postgres;

--
-- Name: check_guest_capacity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_guest_capacity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.number_of_guests IS NOT NULL THEN
        IF NEW.number_of_guests > (SELECT room_capacity FROM public.room WHERE id = NEW.room_id) THEN
            RAISE EXCEPTION 'Number of guests exceeds room capacity';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_guest_capacity() OWNER TO postgres;

--
-- Name: check_reservation_client(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_reservation_client() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM reservation r
        WHERE NEW.reservation_id = r.id
          AND NEW.client_id = r.client_id
    ) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'The client leaving the review did not make this reservation!';
    END IF;
END;
$$;


ALTER FUNCTION public.check_reservation_client() OWNER TO postgres;

--
-- Name: check_room_availability(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_room_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM reservation
        WHERE NEW.room_id = room_id
          AND status_id = 1
          AND check_in_date < NEW.check_out_date
          AND check_out_date > NEW.check_in_date
    ) THEN
        RAISE EXCEPTION 'Room is already reserved for the specified dates!';
    ELSE
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.check_room_availability() OWNER TO postgres;

--
-- Name: update_payment_total_sum(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_payment_total_sum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    payment_id_to_update INTEGER;
    service_price NUMERIC(10,2);
    guest_number INTEGER;
BEGIN

    SELECT price INTO service_price
    FROM public.service
    WHERE id = NEW.service_id;

    SELECT payment_id INTO payment_id_to_update
    FROM public.reservation
    WHERE id = NEW.reservation_id;

    SELECT number_of_guests INTO guest_number
    FROM public.reservation
    WHERE id = NEW.reservation_id;

    UPDATE public.payment
    SET total_sum = total_sum + (service_price * NEW.quantity * guest_number)
    WHERE id = payment_id_to_update;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_payment_total_sum() OWNER TO postgres;

--
-- Name: update_payment_total_sum_initial(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_payment_total_sum_initial() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    room_price NUMERIC(10,2);
BEGIN

    SELECT price_per_night INTO room_price
    FROM public.room
    WHERE id = NEW.room_id;


    UPDATE public.payment
    SET total_sum = total_sum + room_price
    WHERE id = NEW.payment_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_payment_total_sum_initial() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    id integer NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone_number character(13) NOT NULL,
    birthday date NOT NULL,
    eu_gdpr boolean NOT NULL,
    uin character(10) NOT NULL,
    CONSTRAINT client_birthday_check CHECK ((birthday < CURRENT_DATE))
);


ALTER TABLE public.client OWNER TO postgres;

--
-- Name: client_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_id_seq OWNER TO postgres;

--
-- Name: client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_id_seq OWNED BY public.client.id;


--
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    id integer NOT NULL,
    type_id integer NOT NULL,
    status_id integer NOT NULL,
    total_sum numeric(10,2) DEFAULT 0,
    CONSTRAINT payment_total_sum_check CHECK ((total_sum >= (0)::numeric))
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- Name: payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_id_seq OWNER TO postgres;

--
-- Name: payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_id_seq OWNED BY public.payment.id;


--
-- Name: payment_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_type (
    id integer NOT NULL,
    payment_type character varying(255) NOT NULL
);


ALTER TABLE public.payment_type OWNER TO postgres;

--
-- Name: payment_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_type_id_seq OWNER TO postgres;

--
-- Name: payment_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_type_id_seq OWNED BY public.payment_type.id;


--
-- Name: reservation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation (
    id integer NOT NULL,
    room_id integer NOT NULL,
    client_id integer NOT NULL,
    payment_id integer NOT NULL,
    number_of_guests integer,
    status_id integer NOT NULL,
    reservation_date timestamp without time zone NOT NULL,
    check_in_date timestamp without time zone NOT NULL,
    check_out_date timestamp without time zone NOT NULL,
    CONSTRAINT reservation_check_in_date_check CHECK ((check_in_date >= CURRENT_DATE)),
    CONSTRAINT reservation_check_out_date_check CHECK ((check_out_date >= CURRENT_TIMESTAMP)),
    CONSTRAINT reservation_number_of_guests_check CHECK ((number_of_guests > 0)),
    CONSTRAINT reservation_reservation_date_check CHECK ((reservation_date >= CURRENT_DATE))
);


ALTER TABLE public.reservation OWNER TO postgres;

--
-- Name: reservation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reservation_id_seq OWNER TO postgres;

--
-- Name: reservation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservation_id_seq OWNED BY public.reservation.id;


--
-- Name: reservation_review; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation_review (
    id integer NOT NULL,
    reservation_id integer NOT NULL,
    client_id integer NOT NULL,
    comment character varying(500) NOT NULL,
    rating integer NOT NULL,
    date_posted timestamp without time zone NOT NULL,
    CONSTRAINT reservation_review_date_posted_check CHECK ((date_posted >= CURRENT_TIMESTAMP)),
    CONSTRAINT reservation_review_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reservation_review OWNER TO postgres;

--
-- Name: reservation_review_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservation_review_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reservation_review_id_seq OWNER TO postgres;

--
-- Name: reservation_review_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservation_review_id_seq OWNED BY public.reservation_review.id;


--
-- Name: reservation_service; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation_service (
    service_id integer NOT NULL,
    reservation_id integer NOT NULL,
    quantity integer DEFAULT 1,
    date_requested timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reservation_service_date_requested_check CHECK ((date_requested >= CURRENT_TIMESTAMP)),
    CONSTRAINT reservation_service_quantity_check CHECK ((quantity >= 1))
);


ALTER TABLE public.reservation_service OWNER TO postgres;

--
-- Name: room; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.room (
    id integer NOT NULL,
    room_number character varying(50) NOT NULL,
    room_type_id integer NOT NULL,
    price_per_night numeric(10,2) NOT NULL,
    room_capacity numeric(2,0) NOT NULL
);


ALTER TABLE public.room OWNER TO postgres;

--
-- Name: room_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.room_id_seq OWNER TO postgres;

--
-- Name: room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_id_seq OWNED BY public.room.id;


--
-- Name: room_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.room_type (
    id integer NOT NULL,
    room_type character varying(255) NOT NULL
);


ALTER TABLE public.room_type OWNER TO postgres;

--
-- Name: room_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.room_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.room_type_id_seq OWNER TO postgres;

--
-- Name: room_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_type_id_seq OWNED BY public.room_type.id;


--
-- Name: service; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    price numeric(10,2) NOT NULL,
    offer_start_month smallint,
    offer_end_month smallint,
    is_limited_time_offer boolean NOT NULL,
    CONSTRAINT service_offer_end_month_check CHECK (((offer_end_month >= 1) AND (offer_end_month <= 12))),
    CONSTRAINT service_offer_start_month_check CHECK (((offer_start_month >= 1) AND (offer_start_month <= 12)))
);


ALTER TABLE public.service OWNER TO postgres;

--
-- Name: service_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.service_id_seq OWNER TO postgres;

--
-- Name: service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_id_seq OWNED BY public.service.id;


--
-- Name: status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status (
    id integer NOT NULL,
    status_name character varying NOT NULL
);


ALTER TABLE public.status OWNER TO postgres;

--
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.status_id_seq OWNER TO postgres;

--
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_id_seq OWNED BY public.status.id;


--
-- Name: client id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client ALTER COLUMN id SET DEFAULT nextval('public.client_id_seq'::regclass);


--
-- Name: payment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);


--
-- Name: payment_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_type ALTER COLUMN id SET DEFAULT nextval('public.payment_type_id_seq'::regclass);


--
-- Name: reservation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation ALTER COLUMN id SET DEFAULT nextval('public.reservation_id_seq'::regclass);


--
-- Name: reservation_review id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_review ALTER COLUMN id SET DEFAULT nextval('public.reservation_review_id_seq'::regclass);


--
-- Name: room id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room ALTER COLUMN id SET DEFAULT nextval('public.room_id_seq'::regclass);


--
-- Name: room_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type ALTER COLUMN id SET DEFAULT nextval('public.room_type_id_seq'::regclass);


--
-- Name: service id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service ALTER COLUMN id SET DEFAULT nextval('public.service_id_seq'::regclass);


--
-- Name: status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status ALTER COLUMN id SET DEFAULT nextval('public.status_id_seq'::regclass);


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (id, first_name, last_name, email, phone_number, birthday, eu_gdpr, uin) FROM stdin;
1	Emily	Johnson	emily.j@example.com	555-123-4567 	1990-05-15	t	ABC1234567
2	Michael	Davis	michael.d@example.com	555-987-6543 	1985-08-22	t	DEF9876543
3	Sara	Brown	sara.b@example.com	555-234-5678 	1992-11-10	t	GHI2345678
4	Daniel	White	daniel.w@example.com	555-876-5432 	1980-04-30	t	JKL8765432
5	Laura	Lee	laura.l@example.com	555-345-6789 	1988-09-02	t	MNO3456789
6	Matthew	Young	matthew.y@example.com	555-654-3210 	1995-02-18	t	PQR6543210
7	Olivia	Moore	olivia.m@example.com	555-432-1098 	1991-07-25	t	STU4321098
8	James	Williams	james.w@example.com	555-210-9876 	1983-12-07	t	VWX2109876
9	Ava	Martinez	ava.m@example.com	555-789-0123 	1993-03-14	t	YZA7890123
10	Ethan	Garcia	ethan.g@example.com	555-901-2345 	1987-06-29	t	BCD9012345
\.


--
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (id, type_id, status_id, total_sum) FROM stdin;
5	8	1	300.00
6	9	1	280.00
7	10	1	650.00
10	3	1	780.00
9	2	1	350.00
8	1	1	440.00
1	4	1	430.00
2	5	1	630.00
3	6	1	520.00
4	7	1	660.00
\.


--
-- Data for Name: payment_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_type (id, payment_type) FROM stdin;
1	Cash
2	Debit Card
3	Credit Card
4	Bitcoin
5	Apple Pay
6	Google Pay
7	Venmo
8	Cryptocurrency
9	Ethereum
10	Litecoin
11	Dogecoin
12	Zelle
13	Stripe
\.


--
-- Data for Name: reservation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservation (id, room_id, client_id, payment_id, number_of_guests, status_id, reservation_date, check_in_date, check_out_date) FROM stdin;
1	4	4	10	2	1	2024-10-18 00:00:00	2024-11-17 00:00:00	2024-11-25 00:00:00
2	5	5	9	2	1	2024-10-18 00:00:00	2024-11-17 00:00:00	2024-11-30 00:00:00
3	6	6	8	2	1	2024-10-18 00:00:00	2024-11-01 00:00:00	2024-11-03 00:00:00
4	7	7	1	2	1	2023-12-15 00:00:00	2023-12-15 00:00:00	2024-01-15 00:00:00
5	8	8	2	2	1	2023-12-14 17:39:55.788121	2023-12-14 17:39:55.788121	2023-12-15 17:39:55.788121
6	9	9	3	2	1	2023-12-14 17:39:55.788121	2023-12-14 17:39:55.788121	2023-12-16 17:39:55.788121
7	10	10	4	2	1	2023-12-14 17:39:55.788121	2023-12-14 17:39:55.788121	2023-12-17 17:39:55.788121
8	1	1	5	2	1	2023-12-14 17:39:55.788121	2023-12-14 17:39:55.788121	2023-12-21 17:39:55.788121
9	2	2	6	1	1	2023-12-14 17:39:55.788121	2023-12-14 17:39:55.788121	2023-12-19 17:39:55.788121
10	3	3	7	2	1	2023-12-14 17:39:55.788121	2023-12-14 17:39:55.788121	2023-12-16 17:39:55.788121
\.


--
-- Data for Name: reservation_review; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservation_review (id, reservation_id, client_id, comment, rating, date_posted) FROM stdin;
1	1	4	Beautiful view from the room!	5	2023-12-14 17:39:55.788121
2	2	5	Very clean and comfortable.	4	2023-12-14 17:39:55.788121
3	3	6	Enjoyed the spa services.	4	2023-12-14 17:39:55.788121
4	4	7	Friendly staff and great service.	5	2023-12-14 17:39:55.788121
5	5	8	Convenient location, will come back!	4	2023-12-14 17:39:55.788121
6	6	9	Spacious room, excellent amenities.	5	2023-12-14 17:39:55.788121
7	7	10	Loved the balcony and beach access.	5	2023-12-14 17:39:55.788121
8	8	1	Perfect stay, highly recommended!	5	2023-12-14 17:39:55.788121
9	9	2	Great experience, will recommend to friends.	4	2023-12-14 17:39:55.788121
10	10	3	Helpful concierge, enjoyed the city tour.	5	2023-12-14 17:39:55.788121
\.


--
-- Data for Name: reservation_service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservation_service (service_id, reservation_id, quantity, date_requested) FROM stdin;
2	9	1	2023-12-14 17:39:55.788121
3	10	1	2023-12-14 17:39:55.788121
4	1	1	2023-12-14 17:39:55.788121
5	2	1	2023-12-14 17:39:55.788121
6	3	1	2023-12-14 17:39:55.788121
7	4	1	2023-12-14 17:39:55.788121
8	5	1	2023-12-14 17:39:55.788121
9	6	1	2023-12-14 17:39:55.788121
10	7	1	2023-12-14 17:39:55.788121
\.


--
-- Data for Name: room; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.room (id, room_number, room_type_id, price_per_night, room_capacity) FROM stdin;
1	101A	4	300.00	2
2	101B	5	100.00	1
3	102A	6	150.00	2
4	102B	7	180.00	2
5	103A	8	250.00	2
6	103B	9	200.00	2
7	104A	10	280.00	2
8	104B	1	450.00	2
9	201A	2	120.00	2
10	201B	3	600.00	2
\.


--
-- Data for Name: room_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.room_type (id, room_type) FROM stdin;
1	King Suite
2	Twin Room
3	Presidential Suite
4	VIP Suite
5	Accessible Room
6	Adjoining Rooms
7	Balcony Room
8	Cabana
9	Studio Suite
10	Bungalow
\.


--
-- Data for Name: service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service (id, name, price, offer_start_month, offer_end_month, is_limited_time_offer) FROM stdin;
1	Penthouse Suite	500.00	1	10	t
2	Executive Room	180.00	\N	\N	f
3	Honeymoon Package	250.00	\N	\N	f
4	Meeting Room Rental	300.00	\N	\N	f
5	Airport Shuttle	50.00	\N	\N	f
6	Spa Package	120.00	\N	\N	f
7	Gym Access	75.00	\N	\N	f
8	City Tour	90.00	\N	\N	f
9	Car Rental	200.00	\N	\N	f
10	Concierge Service	30.00	\N	\N	f
\.


--
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.status (id, status_name) FROM stdin;
1	ACTIVE
2	CANCELLED
3	COMPLETED
4	FAILED
\.


--
-- Name: client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_id_seq', 10, true);


--
-- Name: payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_id_seq', 10, true);


--
-- Name: payment_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_type_id_seq', 13, true);


--
-- Name: reservation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservation_id_seq', 10, true);


--
-- Name: reservation_review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservation_review_id_seq', 10, true);


--
-- Name: room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_id_seq', 10, true);


--
-- Name: room_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_type_id_seq', 10, true);


--
-- Name: service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_id_seq', 10, true);


--
-- Name: status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.status_id_seq', 4, true);


--
-- Name: client client_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_email_key UNIQUE (email);


--
-- Name: client client_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_phone_number_key UNIQUE (phone_number);


--
-- Name: client client_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (id);


--
-- Name: client client_uin_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_uin_key UNIQUE (uin);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);


--
-- Name: payment_type payment_type_payment_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_type
    ADD CONSTRAINT payment_type_payment_type_key UNIQUE (payment_type);


--
-- Name: payment_type payment_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_type
    ADD CONSTRAINT payment_type_pkey PRIMARY KEY (id);


--
-- Name: reservation reservation_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_payment_id_key UNIQUE (payment_id);


--
-- Name: reservation reservation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id);


--
-- Name: reservation_review reservation_review_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_review
    ADD CONSTRAINT reservation_review_pkey PRIMARY KEY (id);


--
-- Name: reservation_review reservation_review_reservation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_review
    ADD CONSTRAINT reservation_review_reservation_id_key UNIQUE (reservation_id);


--
-- Name: room room_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (id);


--
-- Name: room room_room_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_room_number_key UNIQUE (room_number);


--
-- Name: room_type room_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type
    ADD CONSTRAINT room_type_pkey PRIMARY KEY (id);


--
-- Name: room_type room_type_room_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type
    ADD CONSTRAINT room_type_room_type_key UNIQUE (room_type);


--
-- Name: service service_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_name_key UNIQUE (name);


--
-- Name: service service_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- Name: status status_status_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_status_name_key UNIQUE (status_name);


--
-- Name: index_room; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_room ON public.room USING btree (room_number);


--
-- Name: index_service; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_service ON public.service USING btree (name);


--
-- Name: reservation_service trigger_check_current_limited_service; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_current_limited_service BEFORE INSERT ON public.reservation_service FOR EACH ROW EXECUTE FUNCTION public.check_current_limited_service();


--
-- Name: reservation trigger_check_guest_capacity; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_guest_capacity BEFORE INSERT OR UPDATE OF number_of_guests ON public.reservation FOR EACH ROW EXECUTE FUNCTION public.check_guest_capacity();


--
-- Name: reservation_review trigger_check_reservation_client; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_reservation_client BEFORE INSERT ON public.reservation_review FOR EACH ROW EXECUTE FUNCTION public.check_reservation_client();


--
-- Name: reservation trigger_check_room_availability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_room_availability BEFORE INSERT ON public.reservation FOR EACH ROW EXECUTE FUNCTION public.check_room_availability();


--
-- Name: reservation_service trigger_update_payment_total_sum; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_payment_total_sum AFTER INSERT ON public.reservation_service FOR EACH ROW EXECUTE FUNCTION public.update_payment_total_sum();


--
-- Name: reservation update_payment_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_payment_trigger AFTER INSERT ON public.reservation FOR EACH ROW EXECUTE FUNCTION public.update_payment_total_sum_initial();


--
-- Name: payment payment_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.status(id);


--
-- Name: payment payment_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.payment_type(id);


--
-- Name: reservation reservation_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: reservation reservation_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment(id);


--
-- Name: reservation_review reservation_review_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_review
    ADD CONSTRAINT reservation_review_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: reservation_review reservation_review_reservation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_review
    ADD CONSTRAINT reservation_review_reservation_id_fkey FOREIGN KEY (reservation_id) REFERENCES public.reservation(id);


--
-- Name: reservation reservation_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.room(id);


--
-- Name: reservation_service reservation_service_reservation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_service
    ADD CONSTRAINT reservation_service_reservation_id_fkey FOREIGN KEY (reservation_id) REFERENCES public.reservation(id);


--
-- Name: reservation_service reservation_service_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation_service
    ADD CONSTRAINT reservation_service_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id);


--
-- Name: reservation reservation_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.status(id);


--
-- Name: room room_room_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_room_type_id_fkey FOREIGN KEY (room_type_id) REFERENCES public.room_type(id);


--
-- PostgreSQL database dump complete
--

