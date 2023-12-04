--1 find reservations checking in at current date
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
    DATE(check_in_date) = CURRENT_DATE;


--2 services linked to reservations
SELECT s.name AS service_name,
       rs.quantity,
       (s.price * rs.quantity * r.number_of_guests) AS total_price
FROM public.reservation_service rs
JOIN public.service s ON rs.service_id = s.id
JOIN public.reservation r ON rs.reservation_id = r.id
WHERE rs.reservation_id = 1;



--3 most reserved periods the rooms in the periods and the number of reservations for them
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
      rm.room_number,
      m.period_start,
      m.period_end,
      COUNT(r.id) AS number_of_reservations
  FROM
      public.reservation r
  JOIN
      MostReservedPeriod m ON r.check_in_date = m.period_start
                          AND r.check_out_date = m.period_end
  JOIN public.room rm ON r.room_id = rm.id
  GROUP BY
      rm.room_number, m.period_start, m.period_end
  ORDER BY
      number_of_reservations DESC;


--4 terminate reservation
 UPDATE public.reservation
 SET status_id = 2
 WHERE id = 1;


--5 Select service by reservation ID

 SELECT sv.name, rs.quantity, (rs.quantity*sv.price*rz.number_of_guests),  
 FROM public.service sv
 JOIN public.reservation_service rs ON rs.service_id = sv.id
 JOIN public.reservation rz
 WHERE rz.id = rs.reservation.id
