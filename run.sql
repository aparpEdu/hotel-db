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
    CONSTRAINT reservation_check_in_date_check CHECK ((check_in_date >= CURRENT_TIMESTAMP)),
    CONSTRAINT reservation_check_out_date_check CHECK ((check_out_date >= CURRENT_TIMESTAMP)),
    CONSTRAINT reservation_number_of_guests_check CHECK ((number_of_guests > 0)),
    CONSTRAINT reservation_reservation_date_check CHECK ((reservation_date >= CURRENT_TIMESTAMP))
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

