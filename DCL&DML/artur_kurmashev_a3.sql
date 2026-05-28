DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cinema_admin') THEN
        CREATE ROLE cinema_admin;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cinema_readonly') THEN
        CREATE ROLE cinema_readonly;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'db_admin_user') THEN
        CREATE USER db_admin_user WITH PASSWORD 'AdminPass123!';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'db_reader_user') THEN
        CREATE USER db_reader_user WITH PASSWORD 'ReaderPass123!';
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO cinema_admin;
GRANT USAGE ON SCHEMA public TO cinema_readonly;

GRANT cinema_admin TO db_admin_user;
GRANT cinema_readonly TO db_reader_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cinema_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cinema_readonly;

REVOKE UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM cinema_readonly;

--  schema |  name   | type  |     access privileges     | column privileges | policies 
-- --------+---------+-------+---------------------------+-------------------+----------
--  public | ticket  | table | cinema_admin=arwd/postgres |                   | 

SET ROLE db_admin_user;
SELECT current_user;
SELECT count(*) FROM client;
INSERT INTO client (name) VALUES ('Тест Админ') RETURNING *;
UPDATE client SET name = 'Тест Админ Обновлен' WHERE name = 'Тест Админ';
DELETE FROM client WHERE client_id = (SELECT max(client_id) FROM client);
RESET ROLE;

SET ROLE db_reader_user;
SELECT current_user;
SELECT count(*) FROM client;

BEGIN;
INSERT INTO client (name) VALUES ('Тест Ридер') RETURNING *;
-- error: permission denied for table client
ROLLBACK;

BEGIN;
UPDATE client SET name = 'Тест Ридер Обновлен';
-- error: permission denied for table client
ROLLBACK;

BEGIN;
DELETE FROM client WHERE client_id = 1;
-- error: permission denied for table client
ROLLBACK;

RESET ROLE;

TRUNCATE TABLE ticket, screeningseat, filmgenre, screening, seat, hall, genre, film, client RESTART IDENTITY CASCADE;

INSERT INTO film (title, duration, release_date) VALUES
('Дюна 2', 166, '2024-03-01'),
('Аватар 3', 190, '2025-12-18'),
('Интерстеллар', 169, '2014-11-05'),
('Начало', 148, '2010-07-08'),
('Матрица', 136, '1999-03-31');

INSERT INTO genre (name) VALUES
('Фантастика'),
('Боевик'),
('Драма'),
('Триллер'),
('Приключения');

INSERT INTO hall (name, capacity) VALUES
('Зал 1 IMAX', 100),
('Зал 2 3D', 80),
('Зал 3 VIP', 30),
('Зал 4 Comfort', 50),
('Зал 5 Standard', 60);

INSERT INTO client (name) VALUES
('Алиса Селезнева'),
('Иван Иванов'),
('Елена Смирнова'),
('Данияр Омаров'),
('Artur Kurmashev');

INSERT INTO seat (hall_id, seat_number) VALUES
((SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX'), 1),
((SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX'), 2),
((SELECT hall_id FROM hall WHERE name = 'Зал 2 3D'), 1),
((SELECT hall_id FROM hall WHERE name = 'Зал 3 VIP'), 1),
((SELECT hall_id FROM hall WHERE name = 'Зал 4 Comfort'), 1);

INSERT INTO screening (film_id, hall_id, screening_date, screening_time) VALUES
((SELECT film_id FROM film WHERE title = 'Дюна 2'), (SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX'), '2026-05-10', '18:00:00'),
((SELECT film_id FROM film WHERE title = 'Аватар 3'), (SELECT hall_id FROM hall WHERE name = 'Зал 2 3D'), '2026-05-11', '19:30:00'),
((SELECT film_id FROM film WHERE title = 'Интерстеллар'), (SELECT hall_id FROM hall WHERE name = 'Зал 3 VIP'), '2026-05-12', '20:00:00'),
((SELECT film_id FROM film WHERE title = 'Начало'), (SELECT hall_id FROM hall WHERE name = 'Зал 4 Comfort'), '2026-05-13', '17:00:00'),
((SELECT film_id FROM film WHERE title = 'Матрица'), (SELECT hall_id FROM hall WHERE name = 'Зал 5 Standard'), '2026-05-14', '21:00:00');

INSERT INTO filmgenre (film_id, genre_id) VALUES
((SELECT film_id FROM film WHERE title = 'Дюна 2'), (SELECT genre_id FROM genre WHERE name = 'Фантастика')),
((SELECT film_id FROM film WHERE title = 'Аватар 3'), (SELECT genre_id FROM genre WHERE name = 'Приключения')),
((SELECT film_id FROM film WHERE title = 'Интерстеллар'), (SELECT genre_id FROM genre WHERE name = 'Драма')),
((SELECT film_id FROM film WHERE title = 'Начало'), (SELECT genre_id FROM genre WHERE name = 'Триллер')),
((SELECT film_id FROM film WHERE title = 'Матрица'), (SELECT genre_id FROM genre WHERE name = 'Боевик'));

INSERT INTO screeningseat (screening_id, seat_id) VALUES
((SELECT screening_id FROM screening WHERE screening_date = '2026-05-10' and screening_time = '18:00:00'), (SELECT seat_id FROM seat WHERE seat_number = 1 and hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX'))),
((SELECT screening_id FROM screening WHERE screening_date = '2026-05-10' and screening_time = '18:00:00'), (SELECT seat_id FROM seat WHERE seat_number = 2 and hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX'))),
((SELECT screening_id FROM screening WHERE screening_date = '2026-05-11' and screening_time = '19:30:00'), (SELECT seat_id FROM seat WHERE seat_number = 1 and hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 2 3D'))),
((SELECT screening_id FROM screening WHERE screening_date = '2026-05-12' and screening_time = '20:00:00'), (SELECT seat_id FROM seat WHERE seat_number = 1 and hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 3 VIP'))),
((SELECT screening_id FROM screening WHERE screening_date = '2026-05-13' and screening_time = '17:00:00'), (SELECT seat_id FROM seat WHERE seat_number = 1 and hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 4 Comfort')));

INSERT INTO ticket (screening_seat_id, client_id, price) VALUES
((SELECT screening_seat_id FROM screeningseat ss JOIN seat s ON ss.seat_id = s.seat_id WHERE s.seat_number = 1 and s.hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX')), (SELECT client_id FROM client WHERE name = 'Алиса Селезнева'), 2500.00),
((SELECT screening_seat_id FROM screeningseat ss JOIN seat s ON ss.seat_id = s.seat_id WHERE s.seat_number = 2 and s.hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 1 IMAX')), (SELECT client_id FROM client WHERE name = 'Иван Иванов'), 2500.00),
((SELECT screening_seat_id FROM screeningseat ss JOIN seat s ON ss.seat_id = s.seat_id WHERE s.seat_number = 1 and s.hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 2 3D')), (SELECT client_id FROM client WHERE name = 'Елена Смирнова'), 2000.00),
((SELECT screening_seat_id FROM screeningseat ss JOIN seat s ON ss.seat_id = s.seat_id WHERE s.seat_number = 1 and s.hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 3 VIP')), (SELECT client_id FROM client WHERE name = 'Данияр Омаров'), 5000.00),
((SELECT screening_seat_id FROM screeningseat ss JOIN seat s ON ss.seat_id = s.seat_id WHERE s.seat_number = 1 and s.hall_id = (SELECT hall_id FROM hall WHERE name = 'Зал 4 Comfort')), (SELECT client_id FROM client WHERE name = 'Artur Kurmashev'), 1800.00);

SELECT count(*) FROM client WHERE name = 'Иван Иванов';
-- count: 1
UPDATE client SET name = 'Иван Смирнов' WHERE name = 'Иван Иванов';

SELECT count(*) FROM ticket WHERE price < 2000;
-- count: 1
UPDATE ticket SET price = 2000 WHERE price < 2000;

SELECT count(*) FROM ticket t JOIN client c ON t.client_id = c.client_id WHERE c.name = 'Artur Kurmashev';
-- count: 1
UPDATE ticket t SET price = price * 0.9 FROM client c WHERE t.client_id = c.client_id and c.name = 'Artur Kurmashev';

-- removal of refunded tickets to free up seats for resale
BEGIN;
DELETE FROM ticket WHERE price < 2500;
SELECT count(*) FROM ticket;
-- count: 3
ROLLBACK;