SELECT f.film_id, f.title, f.rental_rate
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE c.name = 'Action' AND f.rental_rate = 3.99;
UPDATE film f
SET rental_rate = 3.99
FROM film_category fc
JOIN category c ON fc.category_id = c.category_id
WHERE f.film_id = fc.film_id AND c.name = 'Action' AND f.rental_rate < 3.00;
