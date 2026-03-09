USE sakila;

-- 1. Cliente con más alquileres en los últimos 6 meses
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS cliente,
    COUNT(r.rental_id)                   AS total_alquileres
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
WHERE r.rental_date >= NOW() - INTERVAL 6 MONTH
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_alquileres DESC
LIMIT 1;

-- 2. Las 5 películas más alquiladas en el último año
SELECT
    f.film_id,
    f.title,
    COUNT(r.rental_id) AS total_alquileres
FROM film f
INNER JOIN inventory i ON f.film_id      = i.film_id
INNER JOIN rental    r ON i.inventory_id = r.inventory_id
WHERE r.rental_date >= NOW() - INTERVAL 1 YEAR
GROUP BY f.film_id, f.title
ORDER BY total_alquileres DESC
LIMIT 5;

-- 3. Total de ingresos y alquileres por categoría
SELECT
    cat.name               AS categoria,
    COUNT(r.rental_id)     AS total_alquileres,
    SUM(p.amount)          AS total_ingresos
FROM category cat
INNER JOIN film_category fc ON cat.category_id = fc.category_id
INNER JOIN film          f  ON fc.film_id       = f.film_id
INNER JOIN inventory     i  ON f.film_id        = i.film_id
INNER JOIN rental        r  ON i.inventory_id   = r.inventory_id
INNER JOIN payment       p  ON r.rental_id      = p.rental_id
GROUP BY cat.category_id, cat.name
ORDER BY total_ingresos DESC;

-- 4. Clientes por idioma en un mes específico (marzo 2026)
SELECT
    l.name                        AS idioma,
    COUNT(DISTINCT r.customer_id) AS total_clientes
FROM language l
INNER JOIN film      f  ON l.language_id  = f.language_id
INNER JOIN inventory i  ON f.film_id      = i.film_id
INNER JOIN rental    r  ON i.inventory_id = r.inventory_id
WHERE YEAR(r.rental_date)  = 2026
  AND MONTH(r.rental_date) = 3
GROUP BY l.language_id, l.name
ORDER BY total_clientes DESC;

-- 5. Clientes que alquilaron TODAS las películas de una categoría (id=6)
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS cliente
FROM customer c
WHERE NOT EXISTS (
    SELECT fc.film_id
    FROM film_category fc
    WHERE fc.category_id = 6
    AND fc.film_id NOT IN (
        SELECT i.film_id
        FROM rental r
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        WHERE r.customer_id = c.customer_id
    )
);

-- 6. Las 3 ciudades con más clientes activos en el último trimestre
SELECT
    ci.city,
    COUNT(DISTINCT r.customer_id) AS clientes_activos
FROM city ci
INNER JOIN address  a  ON ci.city_id    = a.city_id
INNER JOIN customer c  ON a.address_id  = c.address_id
INNER JOIN rental   r  ON c.customer_id = r.customer_id
WHERE r.rental_date >= NOW() - INTERVAL 3 MONTH
  AND c.active = 1
GROUP BY ci.city_id, ci.city
ORDER BY clientes_activos DESC
LIMIT 3;

-- 7. Las 5 categorías con menos alquileres en el último año
SELECT
    cat.name            AS categoria,
    COUNT(r.rental_id)  AS total_alquileres
FROM category cat
LEFT JOIN film_category fc ON cat.category_id = fc.category_id
LEFT JOIN film          f  ON fc.film_id       = f.film_id
LEFT JOIN inventory     i  ON f.film_id        = i.film_id
LEFT JOIN rental        r  ON i.inventory_id   = r.inventory_id
    AND r.rental_date >= NOW() - INTERVAL 1 YEAR
GROUP BY cat.category_id, cat.name
ORDER BY total_alquileres ASC
LIMIT 5;

-- 8. Promedio de días para devolver películas por cliente
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name)                     AS cliente,
    ROUND(AVG(DATEDIFF(r.return_date, r.rental_date)), 2)    AS promedio_dias
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
WHERE r.return_date IS NOT NULL
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY promedio_dias DESC;

-- 9. Los 5 empleados con más alquileres de Acción
SELECT
    s.staff_id,
    CONCAT(s.first_name,' ',s.last_name) AS empleado,
    COUNT(r.rental_id)                   AS total_accion
FROM staff s
INNER JOIN rental        r   ON s.staff_id     = r.staff_id
INNER JOIN inventory     i   ON r.inventory_id = i.inventory_id
INNER JOIN film_category fc  ON i.film_id      = fc.film_id
INNER JOIN category      cat ON fc.category_id = cat.category_id
WHERE cat.name = 'Action'
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY total_accion DESC
LIMIT 5;

-- 10. Clientes con alquileres más recurrentes (informe)
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS cliente,
    COUNT(r.rental_id)                   AS total_alquileres,
    SUM(p.amount)                        AS total_gastado,
    MAX(r.rental_date)                   AS ultimo_alquiler
FROM customer c
INNER JOIN rental   r ON c.customer_id = r.customer_id
INNER JOIN payment  p ON r.rental_id   = p.rental_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_alquileres DESC
LIMIT 10;

-- 11. Costo promedio de alquiler por idioma
SELECT
    l.name                      AS idioma,
    ROUND(AVG(f.rental_rate),2) AS costo_promedio,
    COUNT(f.film_id)            AS total_peliculas
FROM language l
INNER JOIN film f ON l.language_id = f.language_id
GROUP BY l.language_id, l.name
ORDER BY costo_promedio DESC;

-- 12. Las 5 películas con mayor duración alquiladas en el último año
SELECT
    f.film_id,
    f.title,
    f.length             AS duracion_minutos,
    COUNT(r.rental_id)   AS veces_alquilada
FROM film f
INNER JOIN inventory i ON f.film_id      = i.film_id
INNER JOIN rental    r ON i.inventory_id = r.inventory_id
WHERE r.rental_date >= NOW() - INTERVAL 1 YEAR
GROUP BY f.film_id, f.title, f.length
ORDER BY f.length DESC
LIMIT 5;

-- 13. Clientes que más alquilaron Comedia
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS cliente,
    COUNT(r.rental_id)                   AS alquileres_comedia
FROM customer c
INNER JOIN rental        r   ON c.customer_id  = r.customer_id
INNER JOIN inventory     i   ON r.inventory_id = i.inventory_id
INNER JOIN film_category fc  ON i.film_id      = fc.film_id
INNER JOIN category      cat ON fc.category_id = cat.category_id
WHERE cat.name = 'Comedy'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY alquileres_comedia DESC
LIMIT 10;

-- 14. Total de días alquilados por cliente en el último mes
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name)           AS cliente,
    SUM(DATEDIFF(COALESCE(r.return_date, NOW()), r.rental_date)) AS total_dias
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
WHERE r.rental_date >= NOW() - INTERVAL 1 MONTH
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_dias DESC;

-- 15. Alquileres diarios por almacén en el último trimestre
SELECT
    DATE(r.rental_date)   AS dia,
    i.store_id,
    COUNT(r.rental_id)    AS total_alquileres
FROM rental r
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE r.rental_date >= NOW() - INTERVAL 3 MONTH
GROUP BY DATE(r.rental_date), i.store_id
ORDER BY dia DESC, i.store_id;

-- 16. Ingresos totales por almacén en el último semestre
SELECT
    i.store_id,
    SUM(p.amount) AS total_ingresos
FROM payment p
INNER JOIN rental    r ON p.rental_id    = r.rental_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE p.payment_date >= NOW() - INTERVAL 6 MONTH
GROUP BY i.store_id
ORDER BY total_ingresos DESC;

-- 17. Cliente con el alquiler más caro en el último año
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS cliente,
    p.amount                             AS monto,
    f.title                              AS pelicula,
    r.rental_date
FROM customer c
INNER JOIN payment   p ON c.customer_id  = p.customer_id
INNER JOIN rental    r ON p.rental_id    = r.rental_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN film      f ON i.film_id      = f.film_id
WHERE r.rental_date >= NOW() - INTERVAL 1 YEAR
ORDER BY p.amount DESC
LIMIT 1;

-- 18. Las 5 categorías con más ingresos en los últimos 3 meses
SELECT
    cat.name         AS categoria,
    SUM(p.amount)    AS total_ingresos
FROM category cat
INNER JOIN film_category fc ON cat.category_id = fc.category_id
INNER JOIN film          f  ON fc.film_id       = f.film_id
INNER JOIN inventory     i  ON f.film_id        = i.film_id
INNER JOIN rental        r  ON i.inventory_id   = r.inventory_id
INNER JOIN payment       p  ON r.rental_id      = p.rental_id
WHERE p.payment_date >= NOW() - INTERVAL 3 MONTH
GROUP BY cat.category_id, cat.name
ORDER BY total_ingresos DESC
LIMIT 5;

-- 19. Películas alquiladas por idioma en el último mes
SELECT
    l.name                 AS idioma,
    COUNT(r.rental_id)     AS total_alquileres
FROM language l
INNER JOIN film      f  ON l.language_id  = f.language_id
INNER JOIN inventory i  ON f.film_id      = i.film_id
INNER JOIN rental    r  ON i.inventory_id = r.inventory_id
WHERE r.rental_date >= NOW() - INTERVAL 1 MONTH
GROUP BY l.language_id, l.name
ORDER BY total_alquileres DESC;

-- 20. Clientes sin ningún alquiler en el último año
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS cliente,
    c.email,
    c.active
FROM customer c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT r.customer_id
    FROM rental r
    WHERE r.rental_date >= NOW() - INTERVAL 1 YEAR
)
ORDER BY c.customer_id;