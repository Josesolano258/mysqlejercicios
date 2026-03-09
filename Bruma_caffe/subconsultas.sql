USE bruma_cafe;

-- =============================================
-- DEL EXAMEN
-- =============================================

-- 3.1 Productos con precio mayor al promedio
SELECT nombre_producto, precio
FROM productos
WHERE precio > (SELECT AVG(precio) FROM productos);

-- 3.2 Clientes que compraron el 2026-03-05 (IN)
SELECT nombre_cliente
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente FROM tickets WHERE fecha = '2026-03-05'
);

-- =============================================
-- EXTRAS
-- =============================================

-- NOT IN — Clientes que nunca han comprado
SELECT nombre_cliente, nivel_fidelidad
FROM clientes
WHERE id_cliente NOT IN (SELECT id_cliente FROM tickets);

-- MAX escalar — Producto más caro
SELECT nombre_producto, precio
FROM productos
WHERE precio = (SELECT MAX(precio) FROM productos);

-- MIN escalar — Producto más barato
SELECT nombre_producto, precio
FROM productos
WHERE precio = (SELECT MIN(precio) FROM productos);

-- EXISTS — Clientes con al menos un ticket
SELECT c.nombre_cliente
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM tickets t WHERE t.id_cliente = c.id_cliente
);

-- NOT EXISTS — Clientes sin ningún ticket
SELECT c.nombre_cliente
FROM clientes c
WHERE NOT EXISTS (
    SELECT 1 FROM tickets t WHERE t.id_cliente = c.id_cliente
);

-- Subconsulta en FROM — Tickets con total > $5000
SELECT id_ticket, total_ticket
FROM (
    SELECT d.id_ticket, SUM(p.precio * d.cantidad) AS total_ticket
    FROM detalle_ticket d
    INNER JOIN productos p ON d.id_producto = p.id_producto
    GROUP BY d.id_ticket
) AS totales
WHERE total_ticket > 5000;

-- Subconsulta + JOIN — Productos vendidos sobre el precio promedio
SELECT DISTINCT p.nombre_producto, p.precio
FROM detalle_ticket d
INNER JOIN productos p ON d.id_producto = p.id_producto
WHERE p.precio > (SELECT AVG(precio) FROM productos)
ORDER BY p.precio DESC;

-- Clientes Oro que compraron en marzo 2026
SELECT nombre_cliente
FROM clientes
WHERE nivel_fidelidad = 'Oro'
  AND id_cliente IN (
      SELECT id_cliente FROM tickets
      WHERE fecha BETWEEN '2026-03-01' AND '2026-03-31'
  );