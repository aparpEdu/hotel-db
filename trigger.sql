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
--example
-- INSERT INTO public.reservation_review (reservation_id, client_id, comment, rating)
-- VALUES (2, 4, 'Beautiful view from the room!', 5);


