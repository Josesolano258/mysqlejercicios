USE sakila;

-- 1. ActualizarTotalAlquileresEmpleado
DELIMITER $$
CREATE TRIGGER ActualizarTotalAlquileresEmpleado
AFTER INSERT ON rental
FOR EACH ROW
BEGIN
    UPDATE staff
    SET total_rentals = total_rentals + 1
    WHERE staff_id = NEW.staff_id;
END$$
DELIMITER ;

-- 2. AuditarActualizacionCliente
DELIMITER $$
CREATE TRIGGER AuditarActualizacionCliente
AFTER UPDATE ON customer
FOR EACH ROW
BEGIN
    IF OLD.email != NEW.email OR (OLD.email IS NULL AND NEW.email IS NOT NULL) THEN
        INSERT INTO auditoria_cliente (customer_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.customer_id, 'email', OLD.email, NEW.email);
    END IF;
    IF OLD.address_id != NEW.address_id THEN
        INSERT INTO auditoria_cliente (customer_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.customer_id, 'address_id',
                CAST(OLD.address_id AS CHAR), CAST(NEW.address_id AS CHAR));
    END IF;
    IF OLD.active != NEW.active THEN
        INSERT INTO auditoria_cliente (customer_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.customer_id, 'active',
                CAST(OLD.active AS CHAR), CAST(NEW.active AS CHAR));
    END IF;
    IF OLD.saldo_pendiente != NEW.saldo_pendiente THEN
        INSERT INTO auditoria_cliente (customer_id, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.customer_id, 'saldo_pendiente',
                CAST(OLD.saldo_pendiente AS CHAR), CAST(NEW.saldo_pendiente AS CHAR));
    END IF;
END$$
DELIMITER ;

-- 3. RegistrarHistorialDeCosto
DELIMITER $$
CREATE TRIGGER RegistrarHistorialDeCosto
BEFORE UPDATE ON film
FOR EACH ROW
BEGIN
    IF OLD.rental_rate != NEW.rental_rate THEN
        INSERT INTO historial_costo_film (film_id, rental_rate_anterior, rental_rate_nuevo)
        VALUES (OLD.film_id, OLD.rental_rate, NEW.rental_rate);
    END IF;
END$$
DELIMITER ;

-- 4. NotificarEliminacionAlquiler
DELIMITER $$
CREATE TRIGGER NotificarEliminacionAlquiler
BEFORE DELETE ON rental
FOR EACH ROW
BEGIN
    INSERT INTO notificacion_eliminacion
        (rental_id, customer_id, fecha_alquiler, mensaje)
    VALUES (
        OLD.rental_id,
        OLD.customer_id,
        OLD.rental_date,
        CONCAT('Alquiler #', OLD.rental_id,
               ' del cliente #', OLD.customer_id,
               ' eliminado. Fecha: ', OLD.rental_date)
    );
END$$
DELIMITER ;

-- 5. RestringirAlquilerConSaldoPendiente
DELIMITER $$
CREATE TRIGGER RestringirAlquilerConSaldoPendiente
BEFORE INSERT ON rental
FOR EACH ROW
BEGIN
    DECLARE saldo DECIMAL(5,2);
    SELECT saldo_pendiente INTO saldo
    FROM customer WHERE customer_id = NEW.customer_id;
    IF saldo > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El cliente tiene saldo pendiente. Regularice su cuenta antes de alquilar.';
    END IF;
END$$
DELIMITER ;

SHOW TRIGGERS FROM sakila;