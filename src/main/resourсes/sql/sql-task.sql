-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса

SELECT
    ad.aircraft_code,
    s.fare_conditions,
    COUNT(s.seat_no)
FROM
    bookings.aircrafts_data ad
        LEFT JOIN bookings.seats s ON ad.aircraft_code = s.aircraft_code
GROUP BY
    ad.aircraft_code,
    s.fare_conditions
ORDER BY
    ad.aircraft_code;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT
    ad.aircraft_code,
    COUNT(s.seat_no)
FROM
    bookings.aircrafts_data ad
        LEFT JOIN bookings.seats s ON ad.aircraft_code = s.aircraft_code
GROUP BY
    ad.aircraft_code
ORDER BY
    count DESC
    LIMIT 3;

-- 3. Найти все рейсы, которые задерживались более 2 часов

SELECT
    flight_id
FROM
    bookings.flights
WHERE
    actual_departure - scheduled_departure > '2 hours';

-- 4. Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных

SELECT
    t.ticket_no,
    t.passenger_name,
    t.contact_data
FROM
    bookings.tickets t
        LEFT JOIN bookings.bookings b ON t.book_ref = b.book_ref
        LEFT JOIN bookings.ticket_flights tf ON t.ticket_no = tf.ticket_no
WHERE
    tf.fare_conditions = 'Business'
GROUP BY
    t.ticket_no,
    book_date
ORDER BY
    b.book_date DESC
    LIMIT 10;

-- 5. Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')

SELECT
    f.flight_id
FROM
    bookings.flights f
        LEFT JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
WHERE
        tf.fare_conditions = 'Business'
GROUP BY
    f.flight_id,
    tf.fare_conditions
HAVING
    COUNT(tf.ticket_no) < 1;

-- 6. Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой

SELECT
    ad.airport_name,
    ad.city
FROM
    bookings.airports_data ad,
    bookings.flights f
WHERE
    (
        ad.airport_code = f.arrival_airport
        AND f.status = 'Delayed'
    )
   OR (
        ad.airport_code = f.departure_airport
        AND f.status = 'Delayed'
    )
GROUP BY
    ad.airport_name,
    ad.city
ORDER BY
    ad.airport_name;

-- 7. Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов

SELECT
    ad.airport_name,
    count(f.flight_no) AS flight_count
FROM
    bookings.airports_data ad
        LEFT JOIN bookings.flights f ON ad.airport_code = f.departure_airport
WHERE
    f.status = 'On Time'
GROUP BY
    ad.airport_name
ORDER BY
    flight_count DESC;

-- 8. Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным

SELECT
    f.flight_id
FROM
    bookings.flights f
WHERE
    f.actual_arrival notnull
  AND f.actual_arrival <> f.scheduled_arrival;

-- 9. Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам

SELECT
    ad.aircraft_code,
    ad.model,
    s.seat_no
FROM
    bookings.aircrafts_data ad
        JOIN bookings.seats s ON ad.aircraft_code = s.aircraft_code
WHERE
    ad.model :: text LIKE '%Аэробус A321-200%'
    AND s.seat_no <> 'Economy'
ORDER BY
    s.seat_no;

-- 10. Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

SELECT
    ad.airport_code,
    ad.airport_name,
    ad.city
FROM
    bookings.airports_data ad
WHERE
    ad.city IN (
    SELECT
        city
    FROM
        bookings.airports_data a_d
    GROUP BY
        a_d.city
    HAVING
        COUNT(a_d.airport_code) > 1
    );

-- 11. Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
--
-- Из demo.pdf:
-- "Ни идентификатор пассажира, ни имя не являются постоянными (можно поменять паспорт,
-- можно сменить фамилию), поэтому однозначно найти все билеты одного и того же пассажира
-- невозможно".
--
-- Поэтому для выполнения задачи группирую по имени пассажира.

SELECT
    t.passenger_name
FROM
    bookings.tickets t
        JOIN bookings.bookings b ON t.book_ref = b.book_ref
GROUP BY
    t.passenger_name
HAVING
    sum(b.total_amount) > avg(b.total_amount);

-- 12. Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

SELECT
    f.flight_id,
    f.scheduled_departure,
    f.status
FROM
    bookings.flights f
        JOIN bookings.airports_data ad_dep ON f.departure_airport = ad_dep.airport_code
        JOIN bookings.airports_data ad_arr ON f.arrival_airport = ad_arr.airport_code
WHERE
    (
        ad_dep.city :: text LIKE '%Екатеринбург%'
    AND ad_arr :: text LIKE '%Москва%'
    )
  AND (
            f.status = 'Delayed'
        OR f.status = 'On Time'
        OR f.status = 'Scheduled'
    )
ORDER BY
    f.scheduled_departure DESC
    limit 1;

-- 13. Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)

(
    SELECT
        'Самый дорогой билет' AS ticket_type,
        t.ticket_no,
        tf.amount
    FROM
        bookings.tickets t
            JOIN bookings.ticket_flights tf  ON t.ticket_no = tf.ticket_no
    GROUP BY
        t.ticket_no,
        tf.amount
    ORDER BY
        tf.amount DESC
        limit 1
)
UNION ALL
(
    SELECT
        'Самый дешевый билет' AS ticket_type,
        t.ticket_no,
        tf.amount
    FROM
        bookings.tickets t
            JOIN bookings.ticket_flights tf  ON t.ticket_no = tf.ticket_no
    GROUP BY
        t.ticket_no,
        tf.amount
    ORDER BY
        tf.amount
        limit 1
);

-- 14. Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)

CREATE TABLE IF NOT EXISTS bookings.customers
(
    id BIGINT,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    email varchar(25) NOT NULL UNIQUE,
    phone varchar(15) NOT NULL UNIQUE
    );

CREATE SEQUENCE bookings.customers_id_seq;

ALTER TABLE
    bookings.customers
ADD
    PRIMARY KEY (id),
ADD
    CONSTRAINT check_email CHECK (email LIKE '%@%.%'),
ADD
    CONSTRAINT check_phone CHECK (phone ~ '\+[0-9]{12}');

ALTER TABLE
    bookings.customers ALTER COLUMN id
SET
    DEFAULT nextval('bookings.customers_id_seq');

-- 15. Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints

CREATE TABLE IF NOT EXISTS bookings.orders (
    id BIGINT, customer_id BIGINT NOT NULL,
    quantity BIGINT NOT NULL
);

CREATE SEQUENCE bookings.orders_id_seq;

ALTER TABLE
    bookings.orders
ADD
    PRIMARY KEY (id),
ADD
    CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES bookings.customers (id);

ALTER TABLE
    bookings.orders ALTER COLUMN id
    SET
    DEFAULT nextval('bookings.orders_id_seq');

-- 16. Написать 5 insert в эти таблицы

INSERT INTO bookings.customers (
    first_name, last_name, email, phone
)
VALUES
    (
        'First Name', 'Last Name', 'asb@gmail.com',
        '+375292120100'
    );

INSERT INTO bookings.customers (
    first_name, last_name, email, phone
)
VALUES
    (
        'First Name1', 'Last Name1', 'asb1@gmail.com',
        '+375292120101'
    );

INSERT INTO bookings.customers (
    first_name, last_name, email, phone
)
VALUES
    (
        'First Name2', 'Last Name2', 'asb2@gmail.com',
        '+375292120102'
    );

INSERT INTO bookings.customers (
    first_name, last_name, email, phone
)
VALUES
    (
        'First Name3', 'Last Name3', 'asb3@gmail.com',
        '+375292120103'
    );

INSERT INTO bookings.customers (
    first_name, last_name, email, phone
)
VALUES
    (
        'First Name4', 'Last Name4', 'asb4@gmail.com',
        '+375292120104'
    );

INSERT INTO bookings.orders (
    customer_id, quantity
)
VALUES
    (
        1, 100
    );

INSERT INTO bookings.orders (
    customer_id, quantity
)
VALUES
    (
        2, 200
    );

INSERT INTO bookings.orders (
    customer_id, quantity
)
VALUES
    (
        3, 300
    );

INSERT INTO bookings.orders (
    customer_id, quantity
)
VALUES
    (
        4, 400
    );

-- 17. Удалить таблицы

DROP TABLE IF EXISTS bookings.orders, bookings.customers;
DROP SEQUENCE IF EXISTS customers_id_seq, orders_id_seq;