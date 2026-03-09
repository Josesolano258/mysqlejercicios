# 🗄️ Cheat Sheet — MySQL Examen

> **DDL · DML · JOINs · Subconsultas · Funciones · Triggers · Eventos**

---

## 📑 Tabla de Contenidos

1. [🏗️ DDL — Estructura](#1-️-ddl--estructura)
2. [📥 DML — Datos](#2--dml--datos)
3. [🔍 SELECT + JOINs](#3--select--joins)
4. [📊 GROUP BY + HAVING](#4--group-by--having)
5. [🔎 Subconsultas](#5--subconsultas)
6. [📆 Funciones de Fecha](#6--funciones-de-fecha)
7. [⚙️ Funciones Almacenadas](#7-️-funciones-almacenadas)
8. [⚡ Triggers](#8--triggers)
9. [📅 Eventos](#9--eventos)
10. [🚨 Errores Frecuentes](#10--errores-frecuentes-en-examen)
11. [🔑 Orden de Ejecución + Checklist](#11--orden-de-ejecución-sql--checklist)

---

## 1. 🏗️ DDL — Estructura

```sql
CREATE DATABASE IF NOT EXISTS mi_bd;
USE mi_bd;

CREATE TABLE clientes (
    id         INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre     VARCHAR(100)  NOT NULL,
    email      VARCHAR(150)  NOT NULL UNIQUE,
    telefono   VARCHAR(20),
    activo     TINYINT(1)    NOT NULL DEFAULT 1,
    creado_en  DATETIME      NOT NULL DEFAULT NOW()
);

-- Con FK:
CREATE TABLE pedidos (
    id          INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_cliente  INT           NOT NULL,
    total       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado      ENUM('pendiente','pagado','cancelado') NOT NULL DEFAULT 'pendiente',
    fecha       DATETIME      NOT NULL DEFAULT NOW(),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id)
);
```

> ⚠️ **Orden:** crea la tabla padre primero, la tabla hija después (por las FK).

---

## 2. 📥 DML — Datos

### INSERT

```sql
-- Un registro
INSERT INTO clientes (nombre, email) VALUES ('Ana López', 'ana@mail.com');

-- Varios registros
INSERT INTO clientes (nombre, email) VALUES
    ('Carlos Ruiz',  'carlos@mail.com'),
    ('María Gómez',  'maria@mail.com'),
    ('Luis Torres',  'luis@mail.com');
```

### UPDATE

```sql
-- SIEMPRE con WHERE
UPDATE clientes SET telefono = '3001112233' WHERE id = 1;

-- Eliminación lógica (mejor que DELETE cuando hay FKs)
UPDATE clientes SET activo = 0 WHERE id = 5;

-- UPDATE con JOIN
UPDATE pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id
SET p.estado = 'cancelado'
WHERE c.activo = 0;
```

### DELETE

```sql
-- Borrar hijos antes que el padre (por FK)
DELETE FROM detalle_pedido WHERE id_pedido = 10;
DELETE FROM pedidos        WHERE id = 10;

-- Limpiar registros viejos
DELETE FROM log_auditoria WHERE fecha < NOW() - INTERVAL 3 MONTH;
```

> ⚠️ **UPDATE/DELETE sin WHERE → afecta TODOS los registros.** Siempre filtra.

---

## 3. 🔍 SELECT + JOINs

```sql
-- INNER JOIN: solo coincidencias en AMBAS tablas
SELECT c.nombre, p.total, p.fecha
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id
WHERE p.estado = 'pagado'
ORDER BY p.fecha DESC;

-- LEFT JOIN: TODOS de la izquierda + coincidencias (NULL si no hay)
SELECT c.nombre, COUNT(p.id) AS total_pedidos
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.id_cliente
GROUP BY c.id, c.nombre;

-- LEFT JOIN + IS NULL: clientes SIN pedidos
SELECT c.nombre
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.id_cliente
WHERE p.id IS NULL;

-- 4 tablas encadenadas
SELECT c.nombre, pr.nombre AS producto, d.cantidad, d.precio_unit
FROM detalle_pedido d
INNER JOIN pedidos   p  ON d.id_pedido   = p.id
INNER JOIN clientes  c  ON p.id_cliente  = c.id
INNER JOIN productos pr ON d.id_producto = pr.id;
```

---

## 4. 📊 GROUP BY + HAVING

```sql
SELECT
    c.nombre,
    COUNT(p.id)   AS num_pedidos,
    SUM(p.total)  AS total_gastado,
    AVG(p.total)  AS promedio,
    MAX(p.total)  AS pedido_max,
    MIN(p.total)  AS pedido_min
FROM clientes c
INNER JOIN pedidos p ON c.id = p.id_cliente
WHERE p.fecha >= NOW() - INTERVAL 1 YEAR   -- filtra FILAS (antes de agrupar)
GROUP BY c.id, c.nombre
HAVING COUNT(p.id) >= 3                    -- filtra GRUPOS (después de agrupar)
ORDER BY total_gastado DESC
LIMIT 10;
```

> ⚠️ Toda columna en `SELECT` que **no sea función de agregación** → debe estar en `GROUP BY`.  
> ⚠️ `WHERE` no acepta `SUM/COUNT/AVG` → usa `HAVING` para filtrar sobre agregaciones.

---

## 5. 🔎 Subconsultas

```sql
-- Escalar (retorna 1 valor) → usa =, >, <
SELECT nombre FROM productos
WHERE precio > (SELECT AVG(precio) FROM productos);

-- Lista (retorna varios valores) → usa IN / NOT IN
SELECT nombre FROM clientes
WHERE id IN (SELECT id_cliente FROM pedidos WHERE estado = 'pagado');

-- NOT IN: clientes que NUNCA compraron
SELECT nombre FROM clientes
WHERE id NOT IN (SELECT id_cliente FROM pedidos);

-- EXISTS (más eficiente que IN para grandes volúmenes)
SELECT c.nombre FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.id_cliente = c.id AND p.total > 100
);

-- Tabla derivada (subconsulta en FROM → ALIAS obligatorio)
SELECT sub.nombre, sub.total
FROM (
    SELECT c.nombre, SUM(p.total) AS total
    FROM clientes c INNER JOIN pedidos p ON c.id = p.id_cliente
    GROUP BY c.id, c.nombre
) AS sub
WHERE sub.total > 500;
```

---

## 6. 📆 Funciones de Fecha

| Función | Resultado | Ejemplo |
|---|---|---|
| `NOW()` | Fecha y hora actual | `2026-03-09 14:30:00` |
| `CURDATE()` | Solo la fecha | `2026-03-09` |
| `DATE(datetime)` | Extrae solo la fecha | `DATE(NOW()) → 2026-03-09` |
| `YEAR(fecha)` | Año | `YEAR(NOW()) → 2026` |
| `MONTH(fecha)` | Mes (número) | `MONTH(NOW()) → 3` |
| `DATEDIFF(f1, f2)` | Días entre fechas | `DATEDIFF(NOW(), '2026-01-01') → 67` |
| `NOW() - INTERVAL n UNIT` | Fecha pasada | `NOW() - INTERVAL 1 MONTH` |
| `DATE_FORMAT(f, '%Y-%m-01')` | Primer día del mes | `'2026-03-01'` |
| `COALESCE(valor, 0)` | Si es NULL → devuelve 0 | `COALESCE(total, 0)` |

```sql
WHERE fecha >= NOW() - INTERVAL 30 DAY    -- últimos 30 días
WHERE fecha >= NOW() - INTERVAL 1 MONTH   -- último mes
WHERE fecha >= NOW() - INTERVAL 3 MONTH   -- último trimestre
WHERE fecha >= NOW() - INTERVAL 1 YEAR    -- último año
```

---

## 7. ⚙️ Funciones Almacenadas

```sql
DELIMITER $$
CREATE FUNCTION calcular_descuento(p_total DECIMAL(10,2))
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_descuento DECIMAL(10,2) DEFAULT 0;

    IF p_total >= 500 THEN
        SET v_descuento = p_total * 0.15;   -- 15%
    ELSEIF p_total >= 200 THEN
        SET v_descuento = p_total * 0.10;   -- 10%
    ELSE
        SET v_descuento = p_total * 0.05;   -- 5%
    END IF;

    RETURN v_descuento;
END$$
DELIMITER ;

-- Llamar la función:
SELECT nombre, total, calcular_descuento(total) AS descuento FROM pedidos;
```

> 💡 `READS SQL DATA` si la función consulta tablas.  
> 💡 `DETERMINISTIC` si el mismo input siempre produce el mismo output.

---

## 8. ⚡ Triggers

### NEW y OLD según evento

| | `INSERT` | `UPDATE` | `DELETE` |
|---|---|---|---|
| `NEW` | ✅ disponible | ✅ disponible | ❌ no existe |
| `OLD` | ❌ no existe | ✅ disponible | ✅ disponible |
| `BEFORE` | Validar / modificar | Validar / modificar | Validar |
| `AFTER` | Auditoría / cascada | Auditoría / cascada | Auditoría |

```sql
DELIMITER $$

-- Trigger de validación (BEFORE → puede cancelar la operación)
CREATE TRIGGER validar_stock
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;

    IF NEW.cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: cantidad debe ser mayor a 0';
    END IF;

    SELECT stock INTO v_stock FROM productos WHERE id = NEW.id_producto;
    IF v_stock < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: stock insuficiente';
    END IF;

    -- Guardar snapshot del precio actual
    SET NEW.precio_unit = (SELECT precio FROM productos WHERE id = NEW.id_producto);
END$$

-- Trigger de auditoría (AFTER → registra lo que ya pasó)
CREATE TRIGGER auditoria_clientes
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO log_auditoria (tabla, accion, detalle, fecha)
    VALUES ('clientes', 'UPDATE',
            CONCAT('Cliente ', OLD.id, ': ', OLD.nombre, ' → ', NEW.nombre),
            NOW());
END$$

DELIMITER ;
```

> ⚠️ Para **cancelar** una operación → usa `BEFORE` + `SIGNAL`. Con `AFTER` ya no puedes cancelar.

---

## 9. 📅 Eventos

```sql
-- PRIMERO activar el scheduler
SET GLOBAL event_scheduler = ON;

DELIMITER $$
CREATE EVENT limpieza_mensual
ON SCHEDULE
    EVERY 1 MONTH
    STARTS '2026-04-01 00:00:00'
DO
BEGIN
    DECLARE v_total INT;

    SELECT COUNT(*) INTO v_total
    FROM log_auditoria
    WHERE fecha < NOW() - INTERVAL 6 MONTH;

    DELETE FROM log_auditoria
    WHERE fecha < NOW() - INTERVAL 6 MONTH;

    INSERT INTO informe_eventos (descripcion, fecha)
    VALUES (CONCAT('Limpieza: ', v_total, ' registros eliminados'), NOW());
END$$
DELIMITER ;

-- Evento puntual (una sola vez):
-- ON SCHEDULE AT '2026-12-31 23:59:00'

-- Verificar que está activo:
SHOW EVENTS;
```

> ⚠️ Sin `SET GLOBAL event_scheduler = ON`, los eventos **nunca se ejecutan**.

---

## 10. 🚨 Errores Frecuentes en Examen

| Error | Causa | Fix |
|---|---|---|
| `UPDATE`/`DELETE` sin `WHERE` | Modifica/borra **todos** los registros | Siempre pon `WHERE id = X` |
| `GROUP BY` incompleto | Columna en `SELECT` no está en `GROUP BY` | Agrégala al `GROUP BY` |
| `WHERE` con `SUM`/`COUNT` | Agregaciones no van en `WHERE` | Muévelo a `HAVING` |
| FK constraint al borrar | Tiene registros hijos referenciados | Borra hijos primero |
| `=` con subconsulta de N filas | Subconsulta devuelve más de 1 fila | Cambia `=` por `IN` |
| Trigger no cancela la operación | Usaste `AFTER` en vez de `BEFORE` | Cambia a `BEFORE` + `SIGNAL` |
| Evento no corre | Scheduler apagado | `SET GLOBAL event_scheduler = ON` |
| Error de `DELIMITER` | Ejecutaste línea por línea | Ejecuta el **archivo completo** |
| `NULL` en cálculos da `NULL` | Operaciones con `NULL` son `NULL` | Usa `COALESCE(col, 0)` |
| Precio histórico incorrecto | No usaste snapshot en detalle | Guarda el precio en el `INSERT` con trigger |

---

## 11. 🔑 Orden de Ejecución SQL + Checklist

```
FROM  →  JOIN  →  WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  ORDER BY  →  LIMIT
```

### ✅ Checklist antes de entregar

- [ ] ¿Todas las tablas tienen PK con `AUTO_INCREMENT`?
- [ ] ¿Las FK apuntan a la tabla padre correcta?
- [ ] ¿Los `INSERT` cubren todos los casos de las consultas?
- [ ] ¿Los `UPDATE`/`DELETE` tienen `WHERE`?
- [ ] ¿Las funciones tienen `RETURNS`, `DELIMITER` y `DETERMINISTIC`?
- [ ] ¿Los triggers de validación son `BEFORE` + `SIGNAL`?
- [ ] ¿Los triggers de auditoría son `AFTER`?
- [ ] ¿El archivo de eventos empieza con `SET GLOBAL event_scheduler = ON`?
- [ ] ¿Las subconsultas que pueden retornar varias filas usan `IN`?
- [ ] ¿Se usa `COALESCE` donde puede haber `NULL`s?

---

*💪 Puedes con esto. Tú lo hiciste — Bruma Café, Pizza Fiesta, Sakila.*
