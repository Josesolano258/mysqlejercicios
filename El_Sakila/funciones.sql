USE sakila;

-- 1. TotalIngresosCliente
DELIMITER $$
CREATE FUNCTION TotalIngresosCliente(p_customer_id SMALLINT, p_anio INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT COALESCE(SUM(p.amount), 0.00) INTO total
    FROM payment p
    WHERE p.customer_id = p_customer_id
      AND YEAR(p.payment_date) = p_anio;
    RETURN total;
END$$
DELIMITER ;
-- SELECT TotalIngresosCliente(1, 2026);

-- 2. PromedioDuracionAlquiler
DELIMITER $$
CREATE FUNCTION PromedioDuracionAlquiler(p_film_id SMALLINT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE promedio DECIMAL(5,2);
    SELECT ROUND(AVG(DATEDIFF(r.return_date, r.rental_date)), 2) INTO promedio
    FROM rental r
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    WHERE i.film_id     = p_film_id
      AND r.return_date IS NOT NULL;
    RETURN COALESCE(promedio, 0.00);
END$$
DELIMITER ;
-- SELECT PromedioDuracionAlquiler(1);

-- 3. IngresosPorCategoria
DELIMITER $$
CREATE FUNCTION IngresosPorCategoria(p_category_id TINYINT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT COALESCE(SUM(p.amount), 0.00) INTO total
    FROM payment       p
    INNER JOIN rental        r  ON p.rental_id    = r.rental_id
    INNER JOIN inventory     i  ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id      = fc.film_id
    WHERE fc.category_id = p_category_id;
    RETURN total;
END$$
DELIMITER ;
-- SELECT IngresosPorCategoria(1);

-- 4. DescuentoFrecuenciaCliente
DELIMITER $$
CREATE FUNCTION DescuentoFrecuenciaCliente(p_customer_id SMALLINT)
RETURNS DECIMAL(4,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_alquileres INT;
    DECLARE descuento        DECIMAL(4,2);
    SELECT COUNT(rental_id) INTO total_alquileres
    FROM rental WHERE customer_id = p_customer_id;
    IF total_alquileres >= 20 THEN
        SET descuento = 0.15;
    ELSEIF total_alquileres >= 10 THEN
        SET descuento = 0.10;
    ELSEIF total_alquileres >= 5 THEN
        SET descuento = 0.05;
    ELSE
        SET descuento = 0.00;
    END IF;
    RETURN descuento;
END$$
DELIMITER ;
-- SELECT DescuentoFrecuenciaCliente(1);

-- 5. EsClienteVIP
DELIMITER $$
CREATE FUNCTION EsClienteVIP(p_customer_id SMALLINT)
RETURNS VARCHAR(10)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_alquileres INT;
    DECLARE total_ingresos   DECIMAL(10,2);
    SELECT COUNT(rental_id) INTO total_alquileres
    FROM rental WHERE customer_id = p_customer_id;
    SELECT COALESCE(SUM(amount), 0) INTO total_ingresos
    FROM payment WHERE customer_id = p_customer_id;
    IF total_alquileres > 15 AND total_ingresos > 30.00 THEN
        RETURN 'VIP';
    ELSE
        RETURN 'Regular';
    END IF;
END$$
DELIMITER ;
-- SELECT EsClienteVIP(1);

SHOW FUNCTION STATUS WHERE Db = 'sakila';