CREATE DATABASE IF NOT EXISTS bruma_cafe;
USE bruma_cafe;

CREATE TABLE IF NOT EXISTS auditoria_log (
    id_log      INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(255),
    fecha_log   DATETIME DEFAULT NOW()
);

CREATE TABLE clientes (
    id_cliente      VARCHAR(5)    NOT NULL PRIMARY KEY,
    nombre_cliente  VARCHAR(100)  NOT NULL,
    nivel_fidelidad ENUM('Bronce','Plata','Oro') NOT NULL
);

CREATE TABLE productos (
    id_producto     VARCHAR(5)    NOT NULL PRIMARY KEY,
    nombre_producto VARCHAR(100)  NOT NULL,
    precio          DECIMAL(10,2) NOT NULL
);

CREATE TABLE tickets (
    id_ticket  INT        NOT NULL PRIMARY KEY,
    fecha      DATE       NOT NULL,
    id_cliente VARCHAR(5) NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_ticket (
    id_detalle  INT AUTO_INCREMENT PRIMARY KEY,
    id_ticket   INT        NOT NULL,
    id_producto VARCHAR(5) NOT NULL,
    cantidad    INT        NOT NULL,
    FOREIGN KEY (id_ticket)   REFERENCES tickets(id_ticket),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

INSERT INTO clientes VALUES
('C01', 'Ana López',   'Oro'),
('C02', 'Luis Pérez',  'Bronce'),
('C03', 'María Paz',   'Plata'),
('C04', 'Carlos Ruiz', 'Bronce'),
('C05', 'Sofía Mora',  'Oro');

INSERT INTO productos VALUES
('P10', 'Capuccino', 4500.00),
('P11', 'Croissant', 3000.00),
('P12', 'Espresso',  2500.00),
('P13', 'Latte',     4800.00),
('P14', 'Muffin',    2800.00);

INSERT INTO tickets VALUES
(101, '2026-03-04', 'C01'),
(102, '2026-03-04', 'C02'),
(103, '2026-03-05', 'C03');

INSERT INTO detalle_ticket (id_ticket, id_producto, cantidad) VALUES
(101, 'P10', 2),
(101, 'P11', 1),
(102, 'P10', 1),
(103, 'P12', 1),
(103, 'P11', 2);

-- Verificación
SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM clientes
UNION ALL SELECT 'productos',      COUNT(*) FROM productos
UNION ALL SELECT 'tickets',        COUNT(*) FROM tickets
UNION ALL SELECT 'detalle_ticket', COUNT(*) FROM detalle_ticket;