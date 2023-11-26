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
            (EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN s.season_start_month AND s.season_end_month)
        )
    ) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'The service is not in its seasonal period for the current month!';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_current_seasonal_service
BEFORE INSERT ON public.client_service
FOR EACH ROW
EXECUTE FUNCTION check_current_seasonal_service();

--demo
-- INSERT INTO public.client_service (service_id, client_id)
-- VALUES (1, 1);