USE pizza_fiesta;

INSERT INTO clientes (nombre, telefono, direccion) VALUES
('Ana López',      '555-1001', 'Calle 10 #23-45'),
('Luis Pérez',     '555-1002', 'Carrera 5 #12-30'),
('María Gómez',    '555-1003', 'Av. Siempre Viva 742'),
('Carlos Ruiz',    '555-1004', 'Calle 8 #7-20'),
('Sofía Torres',   '555-1005', 'Carrera 15 #88-10'),
('Pedro Ramírez',  '555-1006', 'Calle 22 #4-55'),
('Laura Díaz',     '555-1007', 'Av. Las Palmas #300');

INSERT INTO ingredientes (nombre, costo_extra) VALUES
('Mozzarella',      5.00),
('Pepperoni',       8.00),
('Champiñones',     6.00),
('Pimientos',       5.00),
('Cebolla',         4.00),
('Aceitunas',       5.00),
('Salsa de tomate', 3.00),
('Albahaca',        3.00),
('Pollo',           9.00),
('Tocino',          8.00),
('Jalapeños',       5.00),
('Pineapple',       6.00);

INSERT INTO productos (nombre, tipo, tamanio, precio) VALUES
('Margherita Pequeña',  'pizza', 'pequeña',  65.00),
('Pepperoni Pequeña',   'pizza', 'pequeña',  75.00),
('Hawaiana Pequeña',    'pizza', 'pequeña',  70.00),
('BBQ Pollo Pequeña',   'pizza', 'pequeña',  80.00),
('Margherita Mediana',  'pizza', 'mediana',  95.00),
('Pepperoni Mediana',   'pizza', 'mediana', 110.00),
('Hawaiana Mediana',    'pizza', 'mediana', 100.00),
('BBQ Pollo Mediana',   'pizza', 'mediana', 120.00),
('Margherita Grande',   'pizza', 'grande',  130.00),
('Pepperoni Grande',    'pizza', 'grande',  150.00),
('Hawaiana Grande',     'pizza', 'grande',  140.00),
('BBQ Pollo Grande',    'pizza', 'grande',  160.00),
('Coca-Cola 500ml',     'bebida', NULL,      25.00),
('Sprite 500ml',        'bebida', NULL,      25.00),
('Agua 500ml',          'bebida', NULL,      15.00),
('Jugo de Naranja',     'bebida', NULL,      30.00),
('Combo Familiar',      'combo',  NULL,     200.00),
('Combo Pareja',        'combo',  NULL,     150.00);

-- Recetas base de las pizzas
INSERT INTO pizza_ingredientes (id_producto, id_ingrediente) VALUES
(1,7),(1,1),(1,8),
(5,7),(5,1),(5,8),
(9,7),(9,1),(9,8),
(2,7),(2,1),(2,2),
(6,7),(6,1),(6,2),
(10,7),(10,1),(10,2),
(3,7),(3,1),(3,9),(3,12),
(7,7),(7,1),(7,9),(7,12),
(11,7),(11,1),(11,9),(11,12),
(4,1),(4,9),(4,10),(4,5),
(8,1),(8,9),(8,10),(8,5),
(12,1),(12,9),(12,10),(12,5);

-- Combos
INSERT INTO combo_detalle (id_combo, id_producto) VALUES
(17,10),(17,12),(17,13),(17,13),
(18,5),(18,7),(18,14),(18,14);

INSERT INTO pedidos (id_cliente, fecha_pedido, hora_recogida, estado_pago, estado_pedido, total) VALUES
(1, '2026-03-01 10:00:00', '12:00:00', 'pagado',    'listo',           215.00),
(2, '2026-03-01 11:30:00', '13:00:00', 'pagado',    'en preparacion',  110.00),
(3, '2026-03-02 09:00:00', '11:00:00', 'pendiente', 'en espera',        95.00),
(1, '2026-03-02 14:00:00', '16:30:00', 'pagado',    'listo',           175.00),
(4, '2026-03-03 10:00:00', '12:00:00', 'pagado',    'listo',           160.00),
(2, '2026-03-03 12:00:00', '14:00:00', 'pagado',    'listo',           200.00),
(5, '2026-03-04 09:30:00', '11:30:00', 'pendiente', 'en espera',       150.00),
(1, '2026-03-04 11:00:00', '13:00:00', 'pagado',    'listo',           140.00),
(6, '2026-03-05 10:00:00', '12:30:00', 'pagado',    'en preparacion',  130.00),
(3, '2026-03-05 14:00:00', '16:00:00', 'pagado',    'listo',            75.00),
(1, '2026-03-06 09:00:00', '11:00:00', 'pagado',    'listo',           230.00),
(2, '2026-03-06 12:30:00', '14:30:00', 'pendiente', 'en espera',        95.00),
(1, '2026-03-07 10:00:00', '12:00:00', 'pagado',    'listo',           110.00),
(4, '2026-03-07 11:00:00', '13:30:00', 'pagado',    'listo',           160.00),
(1, '2026-03-08 09:00:00', '11:30:00', 'pagado',    'listo',           200.00);

INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) VALUES
(1,  10, 1, 150.00),
(1,  13, 1,  25.00),
(1,  15, 1,  15.00),
(2,   6, 1, 110.00),
(3,   5, 1,  95.00),
(4,   8, 1, 120.00),
(4,  13, 1,  25.00),
(5,  12, 1, 160.00),
(6,  17, 1, 200.00),
(7,  18, 1, 150.00),
(8,  11, 1, 140.00),
(9,   9, 1, 130.00),
(10,  2, 1,  75.00),
(11, 10, 1, 150.00),
(11, 12, 1, 160.00),
(12,  5, 1,  95.00),
(13,  6, 1, 110.00),
(14, 12, 1, 160.00),
(15, 17, 1, 200.00);

INSERT INTO detalle_ingredientes_extra (id_detalle, id_ingrediente, cantidad, costo_unitario) VALUES
(1,  3, 1, 6.00),
(1, 11, 1, 5.00),
(4,  6, 1, 5.00),
(8,  4, 1, 5.00),
(13, 1, 1, 5.00),
(15,11, 1, 5.00);

INSERT INTO pagos (id_pedido, fecha_pago, monto, metodo_pago) VALUES
(1,  '2026-03-01 10:05:00', 215.00, 'efectivo'),
(2,  '2026-03-01 11:35:00', 110.00, 'tarjeta'),
(4,  '2026-03-02 14:05:00', 175.00, 'efectivo'),
(5,  '2026-03-03 10:05:00', 160.00, 'tarjeta'),
(6,  '2026-03-03 12:05:00', 200.00, 'transferencia'),
(8,  '2026-03-04 11:05:00', 140.00, 'efectivo'),
(9,  '2026-03-05 10:05:00', 130.00, 'tarjeta'),
(10, '2026-03-05 14:05:00',  75.00, 'efectivo'),
(11, '2026-03-06 09:05:00', 230.00, 'tarjeta'),
(13, '2026-03-07 10:05:00', 110.00, 'efectivo'),
(14, '2026-03-07 11:05:00', 160.00, 'tarjeta'),
(15, '2026-03-08 09:05:00', 200.00, 'transferencia');