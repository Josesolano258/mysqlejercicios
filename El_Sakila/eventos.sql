USE sakila;

SET GLOBAL event_scheduler = ON;
SHOW VARIABLES LIKE 'event_scheduler';

-- 1. InformeAlquileresMensual
DELIMITER $$
CREATE EVENT InformeAlquileresMensual
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-04-01 01:00:00'
DO
BEGIN
    DECLARE v_total_alquileres  INT;
    DECLARE v_total_ingresos    DECIMAL(10,2);
    DECLARE v_categoria_top     VARCHAR(25);
    DECLARE v_mes               TINYINT;
    DECLARE v_anio              YEAR;

    SET v_mes  = MONTH(NOW() - INTERVAL 1 MONTH);
    SET v_anio = YEAR(NOW()  - INTERVAL 1 MONTH);

    SELECT COUNT(rental_id) INTO v_total_alquileres
    FROM rental
    WHERE YEAR(rental_date) = v_anio AND MONTH(rental_date) = v_mes;

    SELECT COALESCE(SUM(amount), 0) INTO v_total_ingresos
    FROM payment
    WHERE YEAR(payment_date) = v_anio AND MONTH(payment_date) = v_mes;

    SELECT cat.name INTO v_categoria_top
    FROM category cat
    INNER JOIN film_category fc ON cat.category_id = fc.category_id
    INNER JOIN inventory     i  ON fc.film_id       = i.film_id
    INNER JOIN rental        r  ON i.inventory_id   = r.inventory_id
    WHERE YEAR(r.rental_date) = v_anio AND MONTH(r.rental_date) = v_mes
    GROUP BY cat.category_id, cat.name
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1;

    INSERT INTO informe_mensual (anio, mes, total_alquileres, total_ingresos, categoria_top)
    VALUES (v_anio, v_mes, v_total_alquileres, v_total_ingresos, v_categoria_top);
END$$
DELIMITER ;

-- 2. ActualizarSaldoPendienteCliente
DELIMITER $$
CREATE EVENT ActualizarSaldoPendienteCliente
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-04-30 23:00:00'
DO
BEGIN
    UPDATE customer c
    SET saldo_pendiente = (
        SELECT COALESCE(SUM(
            f.rental_rate *
            GREATEST(0, DATEDIFF(NOW(), r.rental_date) - f.rental_duration)
        ), 0)
        FROM rental r
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN film      f ON i.film_id       = f.film_id
        WHERE r.customer_id = c.customer_id
          AND r.return_date IS NULL
    )
    WHERE c.customer_id IN (
        SELECT DISTINCT customer_id FROM rental WHERE return_date IS NULL
    );
END$$
DELIMITER ;

-- 3. AlertaPeliculasNoAlquiladas
DELIMITER $$
CREATE EVENT AlertaPeliculasNoAlquiladas
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-04-01 02:00:00'
DO
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(DISTINCT f.film_id) INTO v_total
    FROM film f
    WHERE f.film_id NOT IN (
        SELECT DISTINCT i.film_id
        FROM rental r
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        WHERE r.rental_date >= NOW() - INTERVAL 1 YEAR
    );
    IF v_total > 0 THEN
        INSERT INTO informe_mensual (anio, mes, total_alquileres, total_ingresos, categoria_top)
        VALUES (YEAR(NOW()), MONTH(NOW()), 0, 0.00,
                CONCAT('ALERTA: ', v_total, ' películas sin alquilar en el último año'));
    END IF;
END$$
DELIMITER ;

-- 4. LimpiarAuditoriaCada6Meses
DELIMITER $$
CREATE EVENT LimpiarAuditoriaCada6Meses
ON SCHEDULE EVERY 6 MONTH
STARTS '2026-07-01 03:00:00'
DO
BEGIN
    DELETE FROM auditoria_cliente        WHERE fecha_cambio   < NOW() - INTERVAL 6 MONTH;
    DELETE FROM historial_costo_film     WHERE fecha_cambio   < NOW() - INTERVAL 6 MONTH;
    DELETE FROM notificacion_eliminacion WHERE fecha_registro < NOW() - INTERVAL 6 MONTH;
    INSERT INTO informe_mensual (anio, mes, total_alquileres, total_ingresos, categoria_top)
    VALUES (YEAR(NOW()), MONTH(NOW()), 0, 0.00,
            'Limpieza de auditoría ejecutada cada 6 meses');
END$$
DELIMITER ;

-- 5. ActualizarCategoriasPopulares
DELIMITER $$
CREATE EVENT ActualizarCategoriasPopulares
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-04-30 23:30:00'
DO
BEGIN
    DECLARE v_mes_ref DATE;
    SET v_mes_ref = DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01');

    DELETE FROM categoria_popular WHERE mes_referencia = v_mes_ref;

    INSERT INTO categoria_popular (category_id, nombre, total_alquileres, mes_referencia)
    SELECT
        cat.category_id,
        cat.name,
        COUNT(r.rental_id),
        v_mes_ref
    FROM category    cat
    INNER JOIN film_category fc ON cat.category_id = fc.category_id
    INNER JOIN inventory     i  ON fc.film_id       = i.film_id
    INNER JOIN rental        r  ON i.inventory_id   = r.inventory_id
    WHERE YEAR(r.rental_date)  = YEAR(v_mes_ref)
      AND MONTH(r.rental_date) = MONTH(v_mes_ref)
    GROUP BY cat.category_id, cat.name
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 10;
END$$
DELIMITER ;

SHOW EVENTS FROM sakila;

-- Simulación manual del informe de marzo 2026:
INSERT INTO informe_mensual (anio, mes, total_alquileres, total_ingresos, categoria_top)
SELECT
    2026, 3,
    COUNT(r.rental_id),
    COALESCE((SELECT SUM(amount) FROM payment
              WHERE YEAR(payment_date)=2026 AND MONTH(payment_date)=3), 0),
    (SELECT cat.name FROM category cat
     INNER JOIN film_category fc ON cat.category_id = fc.category_id
     INNER JOIN inventory     i  ON fc.film_id       = i.film_id
     INNER JOIN rental        rr ON i.inventory_id   = rr.inventory_id
     WHERE YEAR(rr.rental_date)=2026 AND MONTH(rr.rental_date)=3
     GROUP BY cat.category_id ORDER BY COUNT(rr.rental_id) DESC LIMIT 1)
FROM rental r
WHERE YEAR(r.rental_date)=2026 AND MONTH(r.rental_date)=3;

SELECT * FROM informe_mensual  ORDER BY fecha_generado DESC;
SELECT * FROM categoria_popular ORDER BY total_alquileres DESC;
SELECT * FROM auditoria_cliente ORDER BY fecha_cambio DESC;