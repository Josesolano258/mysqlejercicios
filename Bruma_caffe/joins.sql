USE bruma_cafe;

-- =============================================
-- DEL EXAMEN
-- =============================================

-- 2.1 Tickets con nombre del cliente y fecha
SELECT t.id_ticket, c.nombre_cliente, t.fecha
FROM tickets t
INNER JOIN clientes c ON t.id_cliente = c.id_cliente
ORDER BY t.id_ticket;

-- 2.2 Detalle completo del Ticket 101
SELECT p.nombre_producto, p.precio, d.cantidad,
       (p.precio * d.cantidad) AS subtotal
FROM detalle_ticket d
INNER JOIN productos p ON d.id_producto = p.id_producto
WHERE d.id_ticket = 101;

-- 2.3 Total gastado por cliente (mayor a menor)
SELECT c.nombre_cliente, SUM(p.precio * d.cantidad) AS total_gastado
FROM detalle_ticket d
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente
INNER JOIN productos p ON d.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente
ORDER BY total_gastado DESC;

-- 2.4 Productos por unidades vendidas
SELECT p.nombre_producto, SUM(d.cantidad) AS unidades_vendidas
FROM detalle_ticket d
INNER JOIN productos p ON d.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre_producto
ORDER BY unidades_vendidas DESC;

-- 2.5 Clientes Oro/Plata que compraron Capuccino
SELECT DISTINCT c.nombre_cliente, c.nivel_fidelidad
FROM clientes c
INNER JOIN tickets        t ON c.id_cliente  = t.id_cliente
INNER JOIN detalle_ticket d ON t.id_ticket   = d.id_ticket
INNER JOIN productos      p ON d.id_producto = p.id_producto
WHERE c.nivel_fidelidad IN ('Oro', 'Plata')
  AND p.nombre_producto = 'Capuccino';

-- =============================================
-- EXTRAS
-- =============================================

-- Clientes sin ninguna compra (LEFT JOIN + IS NULL)
SELECT c.id_cliente, c.nombre_cliente, t.id_ticket
FROM clientes c
LEFT JOIN tickets t ON c.id_cliente = t.id_cliente
WHERE t.id_ticket IS NULL;

-- Todos los clientes con total gastado (incluyendo $0 con COALESCE)
SELECT c.nombre_cliente,
       COALESCE(SUM(p.precio * d.cantidad), 0) AS total_gastado
FROM clientes c
LEFT JOIN tickets        t ON c.id_cliente  = t.id_cliente
LEFT JOIN detalle_ticket d ON t.id_ticket   = d.id_ticket
LEFT JOIN productos      p ON d.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente
ORDER BY total_gastado DESC;

-- Productos que nunca se vendieron
SELECT p.id_producto, p.nombre_producto, p.precio
FROM productos p
LEFT JOIN detalle_ticket d ON p.id_producto = d.id_producto
WHERE d.id_detalle IS NULL;

-- Clientes que gastaron más de $10.000 (HAVING)
SELECT c.nombre_cliente, c.nivel_fidelidad,
       SUM(p.precio * d.cantidad) AS total_gastado
FROM detalle_ticket d
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente
INNER JOIN productos p ON d.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente, c.nivel_fidelidad
HAVING total_gastado > 10000
ORDER BY total_gastado DESC;

-- Cantidad de tickets por cliente (con o sin compras)
SELECT c.nombre_cliente, COUNT(t.id_ticket) AS cantidad_tickets
FROM clientes c
LEFT JOIN tickets t ON c.id_cliente = t.id_cliente
GROUP BY c.id_cliente, c.nombre_cliente
ORDER BY cantidad_tickets DESC;