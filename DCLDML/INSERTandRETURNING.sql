INSERT INTO film (title, language_id, rental_duration, rental_rate, replacement_cost, rating)
VALUES ('The Matrix Reloaded', 1, 7, 4.99, 19.99, 'R')
RETURNING film_id, title;
