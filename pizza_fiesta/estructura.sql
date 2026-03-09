CREATE DATABASE IF NOT EXISTS pizza_fiesta;
USE pizza_fiesta;

CREATE TABLE clientes (
    id_cliente   INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    telefono     VARCHAR(20)  NOT NULL,
    direccion    VARCHAR(200) NOT NULL
);

CREATE TABLE ingredientes (
    id_ingrediente  INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100)  NOT NULL,
    costo_extra     DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

CREATE TABLE productos (
    id_producto     INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100)  NOT NULL,
    tipo            ENUM('pizza','bebida','combo') NOT NULL,
    tamanio         ENUM('pequeña','mediana','grande') NULL,
    precio          DECIMAL(10,2) NOT NULL,
    disponible      TINYINT(1)    NOT NULL DEFAULT 1
);

CREATE TABLE pizza_ingredientes (
    id_pizza_ing   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_producto    INT NOT NULL,
    id_ingrediente INT NOT NULL,
    FOREIGN KEY (id_producto)    REFERENCES productos(id_producto),
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente)
);

CREATE TABLE combo_detalle (
    id_combo_det INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_combo     INT NOT NULL,
    id_producto  INT NOT NULL,
    FOREIGN KEY (id_combo)    REFERENCES productos(id_producto),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE pedidos (
    id_pedido       INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_cliente      INT           NOT NULL,
    fecha_pedido    DATETIME      NOT NULL DEFAULT NOW(),
    hora_recogida   TIME          NOT NULL,
    estado_pago     ENUM('pendiente','pagado') NOT NULL DEFAULT 'pendiente',
    estado_pedido   ENUM('en espera','en preparacion','listo') NOT NULL DEFAULT 'en espera',
    total           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_pedido (
    id_detalle      INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_pedido       INT           NOT NULL,
    id_producto     INT           NOT NULL,
    cantidad        INT           NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido)   REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE detalle_ingredientes_extra (
    id_extra        INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_detalle      INT           NOT NULL,
    id_ingrediente  INT           NOT NULL,
    cantidad        INT           NOT NULL DEFAULT 1,
    costo_unitario  DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_detalle)     REFERENCES detalle_pedido(id_detalle),
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente)
);

CREATE TABLE pagos (
    id_pago         INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_pedido       INT           NOT NULL,
    fecha_pago      DATETIME      NOT NULL DEFAULT NOW(),
    monto           DECIMAL(10,2) NOT NULL,
    metodo_pago     ENUM('efectivo','tarjeta','transferencia') NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);