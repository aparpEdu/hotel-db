-- check if reservation belongs to client
CREATE OR REPLACE FUNCTION check_reservation_client()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_reservation_client
BEFORE INSERT ON reservation_review
FOR EACH ROW
EXECUTE FUNCTION check_reservation_client();
--demo
-- INSERT INTO public.reservation_review (reservation_id, client_id, comment, rating)
-- VALUES (2, 4, 'Beautiful view from the room!', 5);

--check if the room is available before reservation
CREATE OR REPLACE FUNCTION check_room_availability()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_room_availability
BEFORE INSERT ON reservation
FOR EACH ROW
EXECUTE FUNCTION check_room_availability();

--demo
-- INSERT INTO public.reservation (room_id, client_id, payment_id, status_id, reservation_date, check_in_date, check_out_date)
-- VALUES (4, 4, 10, 1, '2024-10-18', '2024-11-17', '2024-11-25');

-- check if the current months align with the seasonal months of the service before inserting
CREATE OR REPLACE FUNCTION check_current_seasonal_service()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.service s
        WHERE s.id = NEW.service_id
        AND s.is_seasonal = TRUE
        AND (
            (s.season_start_month IS NULL AND s.season_end_month IS NULL) OR
            (
                (s.season_start_month IS NOT NULL AND s.season_end_month IS NULL)
                AND EXTRACT(MONTH FROM CURRENT_DATE) >= s.season_start_month
            )
            OR
            (
                (s.season_start_month IS NULL AND s.season_end_month IS NOT NULL)
                AND EXTRACT(MONTH FROM CURRENT_DATE) <= s.season_end_month
            )
            OR
            (
                EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN s.season_start_month AND s.season_end_month
            )
        )
    ) THEN
        RETURN NEW;
    ELSE

        IF NOT EXISTS (
            SELECT 1
            FROM public.service
            WHERE id = NEW.service_id
            AND is_seasonal = FALSE
        ) THEN
            RAISE EXCEPTION 'The service is not in its seasonal period for the current month!';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-enable the trigger function
CREATE TRIGGER trigger_check_current_seasonal_service
BEFORE INSERT ON public.reservation_service
FOR EACH ROW
EXECUTE FUNCTION check_current_seasonal_service();


--demo
-- INSERT INTO public.client_service (service_id, client_id)
-- VALUES (1, 1);

--trigger for updating total_sum after new service inserts
CREATE OR REPLACE FUNCTION update_payment_total_sum()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_update_payment_total_sum
AFTER INSERT ON public.reservation_service
FOR EACH ROW
EXECUTE FUNCTION update_payment_total_sum();

--demo
-- INSERT INTO public.reservation_service (service_id, reservation_id, quantity)
-- VALUES (1,8,3);

--trigger for checking if the guest number is withing range of the room capacity
CREATE OR REPLACE FUNCTION check_guest_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.number_of_guests IS NOT NULL THEN
        IF NEW.number_of_guests > (SELECT room_capacity FROM public.room WHERE id = NEW.room_id) THEN
            RAISE EXCEPTION 'Number of guests exceeds room capacity';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_guest_capacity
BEFORE INSERT OR UPDATE OF number_of_guests ON public.reservation
FOR EACH ROW EXECUTE FUNCTION check_guest_capacity();


--demo
-- INSERT INTO public.reservation (room_id, client_id, payment_id, status_id, number_of_guests, reservation_date, check_in_date, check_out_date)
-- VALUES (4, 4, 10, 1, 3, '2024-10-18', '2024-11-17', '2024-11-25');