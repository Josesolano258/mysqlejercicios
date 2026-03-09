USE pizza_fiesta;

-- 1. Registrar un nuevo cliente
INSERT INTO clientes (nombre, telefono, direccion)
VALUES ('Juan Martínez', '555-2001', 'Calle 30 #15-40');

-- 2. Agregar una pizza al menú
INSERT INTO productos (nombre, tipo, tamanio, precio)
VALUES ('Cuatro Quesos Mediana', 'pizza', 'mediana', 115.00);

-- 3. Registrar una bebida
INSERT INTO productos (nombre, tipo, tamanio, precio)
VALUES ('Limonada 500ml', 'bebida', NULL, 28.00);

-- 4. Agregar un ingrediente
INSERT INTO ingredientes (nombre, costo_extra)
VALUES ('Queso Azul', 7.00);

-- 5. Crear un pedido
INSERT INTO pedidos (id_cliente, hora_recogida)
VALUES (1, '15:00:00');

-- 6. Añadir productos al pedido
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
VALUES
    (LAST_INSERT_ID(), 6,  1, 110.00),
    (LAST_INSERT_ID(), 13, 2,  25.00);

-- 7. Añadir ingredientes extra a una pizza
INSERT INTO detalle_ingredientes_extra (id_detalle, id_ingrediente, cantidad, costo_unitario)
VALUES (1, 3, 1, 6.00);

-- 8a. Detalle de productos del pedido 1
SELECT
    dp.id_detalle,
    pr.nombre        AS producto,
    pr.tipo,
    pr.tamanio,
    dp.cantidad,
    dp.precio_unitario,
    (dp.cantidad * dp.precio_unitario) AS subtotal
FROM detalle_pedido dp
INNER JOIN productos pr ON dp.id_producto = pr.id_producto
WHERE dp.id_pedido = 1;

-- 8b. Ingredientes extra del pedido 1
SELECT
    dp.id_detalle,
    pr.nombre                              AS pizza,
    i.nombre                               AS ingrediente_extra,
    die.cantidad,
    die.costo_unitario,
    (die.cantidad * die.costo_unitario)    AS costo_extra_total
FROM detalle_ingredientes_extra die
INNER JOIN detalle_pedido dp ON die.id_detalle     = dp.id_detalle
INNER JOIN productos      pr ON dp.id_producto     = pr.id_producto
INNER JOIN ingredientes   i  ON die.id_ingrediente = i.id_ingrediente
WHERE dp.id_pedido = 1;

-- 9. Actualizar precio de una pizza
UPDATE productos
SET precio = 125.00
WHERE id_producto = 6 AND tipo = 'pizza';

-- 10. Actualizar dirección de un cliente
UPDATE clientes
SET direccion = 'Carrera 20 #55-70'
WHERE id_cliente = 2;

-- 11. Eliminar bebida del menú (eliminación lógica)
UPDATE productos
SET disponible = 0
WHERE id_producto = 14 AND tipo = 'bebida';

-- 12. Eliminar un ingrediente
DELETE FROM pizza_ingredientes WHERE id_ingrediente = 12;
DELETE FROM ingredientes       WHERE id_ingrediente = 12;

-- 13. Todos los pedidos de un cliente
SELECT
    p.id_pedido,
    p.fecha_pedido,
    p.hora_recogida,
    p.estado_pago,
    p.estado_pedido,
    p.total
FROM pedidos p
WHERE p.id_cliente = 1
ORDER BY p.fecha_pedido DESC;

-- 14. Todos los productos disponibles (pizzas y bebidas)
SELECT
    id_producto,
    nombre,
    tipo,
    COALESCE(tamanio, '—') AS tamanio,
    precio
FROM productos
WHERE disponible = 1 AND tipo IN ('pizza', 'bebida')
ORDER BY tipo, tamanio, precio;

-- 15. Ingredientes disponibles
SELECT id_ingrediente, nombre, costo_extra
FROM ingredientes
ORDER BY nombre;

-- 16. Costo total de un pedido
SELECT
    p.id_pedido,
    c.nombre                                              AS cliente,
    SUM(dp.cantidad * dp.precio_unitario)                 AS subtotal_productos,
    COALESCE(SUM(die.cantidad * die.costo_unitario), 0)   AS subtotal_extras,
    SUM(dp.cantidad * dp.precio_unitario)
        + COALESCE(SUM(die.cantidad * die.costo_unitario), 0) AS total_pedido
FROM pedidos p
INNER JOIN clientes   c   ON p.id_cliente  = c.id_cliente
INNER JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
LEFT  JOIN detalle_ingredientes_extra die ON dp.id_detalle = die.id_detalle
WHERE p.id_pedido = 1
GROUP BY p.id_pedido, c.nombre;

-- 17. Clientes con más de 5 pedidos
SELECT
    c.id_cliente,
    c.nombre,
    c.telefono,
    COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
INNER JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre, c.telefono
HAVING total_pedidos > 5
ORDER BY total_pedidos DESC;

-- 18. Pedidos para recoger después de las 12:00
SELECT
    p.id_pedido,
    c.nombre        AS cliente,
    p.fecha_pedido,
    p.hora_recogida,
    p.estado_pedido
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE p.hora_recogida > '12:00:00'
ORDER BY p.hora_recogida;

-- 19. Combos con sus productos incluidos
SELECT
    combo.nombre        AS combo,
    combo.precio        AS precio_combo,
    pr.nombre           AS producto_incluido,
    pr.tipo,
    pr.tamanio,
    pr.precio           AS precio_individual
FROM combo_detalle cd
INNER JOIN productos combo ON cd.id_combo    = combo.id_producto
INNER JOIN productos pr    ON cd.id_producto = pr.id_producto
ORDER BY combo.nombre, pr.tipo;

-- 20. Pizzas con precio mayor a $100
SELECT nombre, tamanio, precio
FROM productos
WHERE tipo = 'pizza' AND precio > 100 AND disponible = 1
ORDER BY precio DESC;

-- 21. Ingresos por día
SELECT
    DATE(pg.fecha_pago)      AS dia,
    SUM(pg.monto)            AS ingresos_dia
FROM pagos pg
INNER JOIN pedidos p ON pg.id_pedido = p.id_pedido
WHERE p.estado_pago = 'pagado'
GROUP BY DATE(pg.fecha_pago)
ORDER BY dia DESC;

-- 21. Ingresos por semana
SELECT
    YEAR(pg.fecha_pago)         AS anio,
    WEEK(pg.fecha_pago, 1)      AS semana,
    MIN(DATE(pg.fecha_pago))    AS inicio_semana,
    SUM(pg.monto)               AS ingresos_semana
FROM pagos pg
INNER JOIN pedidos p ON pg.id_pedido = p.id_pedido
WHERE p.estado_pago = 'pagado'
GROUP BY YEAR(pg.fecha_pago), WEEK(pg.fecha_pago, 1)
ORDER BY anio DESC, semana DESC;

-- 21. Ingresos por mes
SELECT
    YEAR(pg.fecha_pago)         AS anio,
    MONTH(pg.fecha_pago)        AS mes_numero,
    MONTHNAME(pg.fecha_pago)    AS mes_nombre,
    SUM(pg.monto)               AS ingresos_mes
FROM pagos pg
INNER JOIN pedidos p ON pg.id_pedido = p.id_pedido
WHERE p.estado_pago = 'pagado'
GROUP BY YEAR(pg.fecha_pago), MONTH(pg.fecha_pago), MONTHNAME(pg.fecha_pago)
ORDER BY anio DESC, mes_numero DESC;