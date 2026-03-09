USE bruma_cafe;

-- PASO 1 — Activar el scheduler (obligatorio)
SET GLOBAL event_scheduler = ON;
SHOW VARIABLES LIKE 'event_scheduler';

-- =============================================
-- DEL EXAMEN
-- =============================================

-- EVENTO mensual: borrar logs viejos y registrar ejecución
DELIMITER $$
CREATE EVENT limpieza_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-04-01 00:00:00'
DO
BEGIN
    DELETE FROM auditoria_log WHERE fecha_log < NOW() - INTERVAL 30 DAY;
    INSERT INTO auditoria_log (descripcion)
    VALUES ('Limpieza mensual ejecutada automáticamente.');
END$$
DELIMITER ;

-- =============================================
-- EXTRAS
-- =============================================

-- EVENTO diario: reporte de tickets del día anterior (6 AM)
DELIMITER $$
CREATE EVENT reporte_ventas_diario
ON SCHEDULE EVERY 1 DAY
STARTS '2026-04-01 06:00:00'
DO
BEGIN
    DECLARE total_tickets INT;
    SELECT COUNT(*) INTO total_tickets
    FROM tickets WHERE fecha = CURDATE() - INTERVAL 1 DAY;
    INSERT INTO auditoria_log (descripcion)
    VALUES (CONCAT('Reporte diario: ', total_tickets, ' tickets el ',
                   DATE(NOW() - INTERVAL 1 DAY)));
END$$
DELIMITER ;

-- EVENTO único: activar promo en fecha específica
DELIMITER $$
CREATE EVENT promo_verano_2026
ON SCHEDULE AT '2026-12-01 08:00:00'
DO
BEGIN
    INSERT INTO auditoria_log (descripcion)
    VALUES ('Promoción de verano 2026 activada.');
END$$
DELIMITER ;

-- =============================================
-- GESTIÓN
-- =============================================
SHOW EVENTS FROM bruma_cafe;
ALTER EVENT limpieza_mensual DISABLE;   -- pausar
ALTER EVENT limpieza_mensual ENABLE;    -- reactivar
DROP EVENT IF EXISTS limpieza_mensual;  -- eliminar

-- Simular manualmente (para probar sin esperar):
DELETE FROM auditoria_log WHERE fecha_log < NOW() - INTERVAL 30 DAY;
INSERT INTO auditoria_log (descripcion) VALUES ('Limpieza manual de prueba.');
SELECT * FROM auditoria_log ORDER BY fecha_log DESC;