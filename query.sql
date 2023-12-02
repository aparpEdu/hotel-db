--1
SELECT
    r.id AS reservation_number,
    rm.room_number,
    c.first_name || ' ' || c.last_name AS customer_name,
    r.check_in_date,
    r.check_out_date,
    r.number_of_guests,
    p.total_sum AS total_amount,
    pt.payment_type AS payment_method
FROM
    public.reservation r
    JOIN public.room rm ON r.room_id = rm.id
    JOIN public.client c ON r.client_id = c.id
    JOIN public.payment p ON r.payment_id = p.id
    JOIN public.payment_type pt ON p.type_id = pt.id
WHERE
    check_in_date = CURRENT_DATE;

--3
 WITH MostReservedPeriod AS (
     SELECT
         r.check_in_date AS period_start,
         r.check_out_date AS period_end
     FROM
         public.reservation r
     GROUP BY
         r.check_in_date, r.check_out_date
     ORDER BY
         COUNT(r.id) DESC
     LIMIT 1
 )


 SELECT
     r.room_id AS reserved_room,
     m.period_start,
     m.period_end,
     COUNT(r.id) AS number_of_reservations
 FROM
     public.reservation r
 JOIN
     MostReservedPeriod m ON r.check_in_date = m.period_start
                         AND r.check_out_date = m.period_end
 GROUP BY
     r.room_id, m.period_start, m.period_end
 ORDER BY
     number_of_reservations DESC;


--4 terminate reservation
 UPDATE public.reservation
 SET status_id = 2
 WHERE id = 1;