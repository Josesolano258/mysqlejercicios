USE bruma_cafe;

-- =============================================
-- DEL EXAMEN
-- =============================================

-- FUNCIÓN: 1 punto por cada $1000 gastados
DELIMITER $$
CREATE FUNCTION calcular_puntos(monto DECIMAL(10,2))
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN FLOOR(monto / 1000);
END$$
DELIMITER ;

-- Pruebas rápidas:
-- SELECT calcular_puntos(13500); → 13
-- SELECT calcular_puntos(999);   → 0
-- SELECT calcular_puntos(5500);  → 5

-- Uso real — puntos por cliente:
SELECT c.nombre_cliente,
       SUM(p.precio * d.cantidad)                  AS total_gastado,
       calcular_puntos(SUM(p.precio * d.cantidad)) AS puntos
FROM detalle_ticket d
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente
INNER JOIN productos p ON d.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente;

-- TRIGGER: validar cantidad > 0 antes de insertar
DELIMITER $$
CREATE TRIGGER before_detalle_insert
BEFORE INSERT ON detalle_ticket
FOR EACH ROW
BEGIN
    IF NEW.cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La cantidad debe ser mayor a 0.';
    END IF;
END$$
DELIMITER ;

-- Prueba (debe lanzar error):
-- INSERT INTO detalle_ticket (id_ticket, id_producto, cantidad) VALUES (101, 'P10', 0);

-- =============================================
-- EXTRAS
-- =============================================

-- FUNCIÓN: clasificar gasto en Alto / Medio / Bajo
DELIMITER $$
CREATE FUNCTION clasificar_gasto(total DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF total >= 15000 THEN RETURN 'Alto';
    ELSEIF total >= 8000 THEN RETURN 'Medio';
    ELSE RETURN 'Bajo';
    END IF;
END$$
DELIMITER ;

-- FUNCIÓN: precio con descuento según nivel de fidelidad
DELIMITER $$
CREATE FUNCTION precio_con_descuento(precio DECIMAL(10,2), nivel VARCHAR(10))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    IF nivel = 'Oro'   THEN RETURN precio * 0.85;
    ELSEIF nivel = 'Plata' THEN RETURN precio * 0.90;
    ELSE RETURN precio;
    END IF;
END$$
DELIMITER ;

-- TRIGGER AFTER INSERT: registrar en auditoría cada nueva línea de detalle
DELIMITER $$
CREATE TRIGGER after_detalle_insert
AFTER INSERT ON detalle_ticket
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (descripcion)
    VALUES (CONCAT('Nueva compra — Ticket #', NEW.id_ticket,
                   ' | Producto: ', NEW.id_producto,
                   ' | Cantidad: ', NEW.cantidad));
END$$
DELIMITER ;

-- TRIGGER BEFORE UPDATE: no permitir actualizar cantidad a 0 o negativo
DELIMITER $$
CREATE TRIGGER before_detalle_update
BEFORE UPDATE ON detalle_ticket
FOR EACH ROW
BEGIN
    IF NEW.cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No puedes dejar la cantidad en 0 o negativo.';
    END IF;
END$$
DELIMITER ;

-- Ver lo creado:
SHOW FUNCTION STATUS WHERE Db = 'bruma_cafe';
SHOW TRIGGERS FROM bruma_cafe;