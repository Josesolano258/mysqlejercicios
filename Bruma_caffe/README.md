# ☕ Bruma Café — Guía Completa MySQL para el Examen

> Base de datos: `bruma_cafe` | Tablas: `clientes`, `productos`, `tickets`, `detalle_ticket`, `auditoria_log`

---

## 📌 Índice

1. [Estructura de la base de datos](#1-estructura-de-la-base-de-datos)
2. [JOINs](#2-joins)
3. [Subconsultas](#3-subconsultas)
4. [Funciones Almacenadas](#4-funciones-almacenadas)
5. [Triggers](#5-triggers)
6. [Eventos](#6-eventos)
7. [Cheatsheet rápido para el examen](#7-cheatsheet-rápido-para-el-examen)

---

## 1. Estructura de la base de datos

### Diagrama de relaciones

```
clientes                tickets               detalle_ticket          productos
─────────────           ─────────────         ──────────────────      ─────────────────
id_cliente  ◄────────── id_cliente            id_detalle (PK)         id_producto (PK)
nombre_cliente          id_ticket (PK) ──────► id_ticket (FK)         nombre_producto
nivel_fidelidad         fecha                 id_producto (FK) ──────► precio
                                              cantidad
```

### ¿Cómo se relacionan?

- Un **cliente** puede tener muchos **tickets** (1:N)
- Un **ticket** puede tener muchos **detalles** (1:N)
- Cada **detalle** apunta a un **producto** (N:1)
- Para saber cuánto gastó un cliente hay que recorrer: `detalle_ticket → tickets → clientes` y `detalle_ticket → productos`

### Normalización 3FN (por si preguntan)

La base está en **Tercera Forma Normal**:
- Cada tabla tiene una PK
- No hay columnas que dependan de otra columna que no sea la PK
- No hay datos repetidos entre tablas (el nombre del cliente solo vive en `clientes`, no en `tickets`)

---

## 2. JOINs

### ¿Qué es un JOIN?

Un JOIN **combina filas de dos o más tablas** usando una columna en común (generalmente FK → PK).
Sin JOIN tendrías que hacer múltiples consultas y cruzar los datos a mano.

### Sintaxis base

```sql
SELECT columnas
FROM tabla_A alias_a
[TIPO] JOIN tabla_B alias_b ON alias_a.columna = alias_b.columna
[WHERE ...]
[GROUP BY ...]
[ORDER BY ...];
```

---

### INNER JOIN

Devuelve **solo las filas que tienen coincidencia en AMBAS tablas**.
Si un cliente no tiene tickets, no aparece. Si un ticket no tiene cliente válido, no aparece.

```
Clientes    Tickets
   C01  ────  101   ✅ aparece
   C02  ────  102   ✅ aparece
   C04         ✗    ❌ C04 no tiene ticket → no aparece
```

```sql
SELECT t.id_ticket, c.nombre_cliente, t.fecha
FROM tickets t
INNER JOIN clientes c ON t.id_cliente = c.id_cliente;
```

**Resultado:**
| id_ticket | nombre_cliente | fecha |
|-----------|---------------|-------|
| 101 | Ana López | 2026-03-04 |
| 102 | Luis Pérez | 2026-03-04 |
| 103 | María Paz | 2026-03-05 |

---

### LEFT JOIN

Devuelve **TODAS las filas de la tabla izquierda** (la que está antes del JOIN) y las coincidencias de la derecha.
Si no hay coincidencia, los campos de la tabla derecha salen como `NULL`.

```
Clientes    Tickets
   C01  ────  101   ✅ aparece normal
   C02  ────  102   ✅ aparece normal
   C04   ──── NULL  ✅ aparece, pero con ticket = NULL
```

```sql
SELECT c.nombre_cliente, t.id_ticket
FROM clientes c
LEFT JOIN tickets t ON c.id_cliente = t.id_cliente;
```

**Resultado:**
| nombre_cliente | id_ticket |
|---------------|-----------|
| Ana López | 101 |
| Luis Pérez | 102 |
| María Paz | 103 |
| Carlos Ruiz | NULL |
| Sofía Mora | NULL |

**Truco — buscar los que NO tienen par:**
Filtrar por `IS NULL` después del LEFT JOIN para encontrar registros sin relación.

```sql
-- Clientes que NUNCA han comprado:
SELECT c.nombre_cliente
FROM clientes c
LEFT JOIN tickets t ON c.id_cliente = t.id_cliente
WHERE t.id_ticket IS NULL;
```

---

### RIGHT JOIN

Es el espejo del LEFT JOIN. Devuelve **TODAS las filas de la tabla derecha**.
En la práctica casi siempre se reescribe como LEFT JOIN invirtiendo el orden.

```sql
-- Estos dos son equivalentes:
SELECT * FROM clientes c RIGHT JOIN tickets t ON c.id_cliente = t.id_cliente;
SELECT * FROM tickets t LEFT JOIN clientes c ON t.id_cliente = c.id_cliente;
```

---

### INNER JOIN con 4 tablas (el más importante del examen)

Para calcular totales necesitas cruzar las 4 tablas principales:

```sql
-- Total gastado por cada cliente
SELECT
    c.nombre_cliente,
    SUM(p.precio * d.cantidad) AS total_gastado
FROM detalle_ticket d                                  -- tabla base (la del medio)
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket  -- detalle → ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente -- ticket → cliente
INNER JOIN productos p ON d.id_producto = p.id_producto -- detalle → producto
GROUP BY c.id_cliente, c.nombre_cliente
ORDER BY total_gastado DESC;
```

**¿Por qué `detalle_ticket` va primero?**
Porque es la tabla que conecta todo. Tiene FK tanto hacia `tickets` como hacia `productos`.

---

### GROUP BY y HAVING (van de la mano con JOINs)

- `GROUP BY` agrupa filas con el mismo valor
- `HAVING` filtra grupos (es el `WHERE` de las funciones de agregación)

```sql
-- WHERE filtra filas individuales → va ANTES del GROUP BY
-- HAVING filtra grupos → va DESPUÉS del GROUP BY

SELECT c.nombre_cliente, SUM(p.precio * d.cantidad) AS total
FROM detalle_ticket d
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente
INNER JOIN productos p ON d.id_producto = p.id_producto
WHERE c.nivel_fidelidad != 'Bronce'   -- filtra clientes individuales
GROUP BY c.id_cliente, c.nombre_cliente
HAVING total > 5000                   -- filtra los grupos por su total
ORDER BY total DESC;
```

> ⚠️ **Regla de oro del GROUP BY:** toda columna del SELECT que NO sea una función de agregación (`SUM`, `COUNT`, `AVG`, `MAX`, `MIN`) **debe estar en el GROUP BY**.

---

### DISTINCT — evitar duplicados

Se usa cuando el JOIN puede generar filas repetidas (por ejemplo, un cliente que compró Capuccino en dos tickets diferentes).

```sql
SELECT DISTINCT c.nombre_cliente, c.nivel_fidelidad
FROM clientes c
INNER JOIN tickets        t ON c.id_cliente  = t.id_cliente
INNER JOIN detalle_ticket d ON t.id_ticket   = d.id_ticket
INNER JOIN productos      p ON d.id_producto = p.id_producto
WHERE c.nivel_fidelidad IN ('Oro', 'Plata')
  AND p.nombre_producto = 'Capuccino';
```

---

### COALESCE — reemplazar NULL por un valor

Cuando usas LEFT JOIN y hay NULLs, `COALESCE(valor, reemplazo)` pone el reemplazo si el valor es NULL.

```sql
SELECT c.nombre_cliente,
       COALESCE(SUM(p.precio * d.cantidad), 0) AS total_gastado
FROM clientes c
LEFT JOIN tickets        t ON c.id_cliente  = t.id_cliente
LEFT JOIN detalle_ticket d ON t.id_ticket   = d.id_ticket
LEFT JOIN productos      p ON d.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente;
-- Carlos Ruiz y Sofía Mora aparecen con 0 en vez de NULL
```

---

## 3. Subconsultas

### ¿Qué es una subconsulta?

Una consulta **anidada dentro de otra**. La interior se ejecuta primero y su resultado lo usa la exterior.

```sql
SELECT nombre_producto, precio
FROM productos
WHERE precio > ( SELECT AVG(precio) FROM productos );
--               ↑ esto se ejecuta primero → devuelve 3520
--               luego filtra productos con precio > 3520
```

---

### Tipo 1 — Subconsulta escalar (devuelve UN solo valor)

Se usa con operadores de comparación: `=` `>` `<` `>=` `<=`
La subconsulta debe devolver exactamente **1 fila y 1 columna**.

```sql
-- Productos más caros que el promedio
WHERE precio > (SELECT AVG(precio) FROM productos)

-- El producto más caro
WHERE precio = (SELECT MAX(precio) FROM productos)

-- El producto más barato
WHERE precio = (SELECT MIN(precio) FROM productos)
```

> ⚠️ Si usas `=` y la subconsulta devuelve más de una fila → **ERROR: Subquery returns more than 1 row**
> Solución: cambia `=` por `IN`

---

### Tipo 2 — Subconsulta con IN (devuelve una lista)

La subconsulta devuelve múltiples filas. `IN` verifica si el valor está en esa lista.

```sql
-- Clientes que compraron el 2026-03-05
SELECT nombre_cliente
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente FROM tickets WHERE fecha = '2026-03-05'
);
```

---

### Tipo 3 — NOT IN (exclusión)

Lo opuesto: devuelve los registros cuyo valor **NO está** en la lista.

```sql
-- Clientes que NUNCA han comprado
SELECT nombre_cliente
FROM clientes
WHERE id_cliente NOT IN (SELECT id_cliente FROM tickets);
```

> ⚠️ **Cuidado con NULL y NOT IN:** si la subconsulta devuelve algún NULL, el NOT IN no funciona como esperas. En ese caso usa NOT EXISTS.

---

### Tipo 4 — EXISTS / NOT EXISTS

Devuelve `TRUE` si la subconsulta encuentra **al menos una fila**. No importa qué devuelve, solo si existe.
Se usa `SELECT 1` adentro porque no importa el valor, solo la existencia.

```sql
-- Clientes que SÍ tienen ticket (EXISTS)
SELECT c.nombre_cliente
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM tickets t WHERE t.id_cliente = c.id_cliente
);

-- Clientes que NO tienen ticket (NOT EXISTS)
SELECT c.nombre_cliente
FROM clientes c
WHERE NOT EXISTS (
    SELECT 1 FROM tickets t WHERE t.id_cliente = c.id_cliente
);
```

---

### Tipo 5 — Subconsulta en el FROM (tabla derivada)

La subconsulta actúa como una tabla temporal. **Obligatorio ponerle alias**.

```sql
-- Tickets cuyo total supera $5000
SELECT id_ticket, total_ticket
FROM (
    SELECT d.id_ticket, SUM(p.precio * d.cantidad) AS total_ticket
    FROM detalle_ticket d
    INNER JOIN productos p ON d.id_producto = p.id_producto
    GROUP BY d.id_ticket
) AS totales               -- ← alias OBLIGATORIO
WHERE total_ticket > 5000;
```

---

### ¿Cuándo usar JOIN vs Subconsulta?

| Situación | Usar |
|-----------|------|
| Necesitas columnas de ambas tablas | JOIN |
| Solo filtrás por existencia | Subconsulta con EXISTS |
| Comparas contra un valor calculado (AVG, MAX) | Subconsulta escalar |
| Necesitas una lista de IDs para filtrar | Subconsulta con IN |

---

## 4. Funciones Almacenadas

### ¿Qué es una función almacenada?

Un bloque de código SQL guardado en la BD que **recibe parámetros** y **devuelve un valor**.
Se llama igual que cualquier función nativa de MySQL: `SELECT mi_funcion(valor)`.

---

### ¿Para qué sirve DELIMITER?

MySQL usa `;` para saber cuándo termina una sentencia. Pero dentro de una función también hay `;`.
Si no cambias el delimitador, MySQL corta la función a la mitad al encontrar el primer `;`.

```sql
DELIMITER $$      -- ahora MySQL espera $$ para terminar, ignora los ; internos

CREATE FUNCTION ... 
BEGIN
    ...;          -- este ; ya no corta nada
    RETURN valor;
END$$             -- aquí termina de verdad

DELIMITER ;       -- restaurar el delimitador normal
```

---

### Estructura completa

```sql
DELIMITER $$
CREATE FUNCTION nombre_funcion(parametro TIPO_DATO)
RETURNS TIPO_RETORNO
DETERMINISTIC
BEGIN
    DECLARE variable TIPO;        -- declarar variables locales (opcional)
    SET variable = valor;         -- asignar valor
    RETURN resultado;             -- devolver el valor
END$$
DELIMITER ;
```

**¿Qué es DETERMINISTIC?**
Le dice a MySQL que para los mismos parámetros siempre devolverá el mismo resultado.
Ejemplo: `calcular_puntos(1000)` siempre devuelve `1`. Eso es determinístico.
Si la función usara `NOW()` o `RAND()`, sería `NOT DETERMINISTIC`.

---

### Función del examen: calcular_puntos

```sql
DELIMITER $$
CREATE FUNCTION calcular_puntos(monto DECIMAL(10,2))
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN FLOOR(monto / 1000);
    -- FLOOR() redondea hacia abajo
    -- 1999 → FLOOR(1.999) → 1 punto (no 2)
    -- 13500 → FLOOR(13.5) → 13 puntos
END$$
DELIMITER ;
```

**Cómo usarla:**
```sql
SELECT calcular_puntos(13500);   -- → 13

-- En una consulta real:
SELECT c.nombre_cliente,
       SUM(p.precio * d.cantidad)                  AS total,
       calcular_puntos(SUM(p.precio * d.cantidad)) AS puntos
FROM detalle_ticket d
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente
INNER JOIN productos p ON d.id_producto = p.id_producto
GROUP BY c.id_cliente, c.nombre_cliente;
```

---

### Función extra: condicional con IF / ELSEIF / ELSE

```sql
DELIMITER $$
CREATE FUNCTION clasificar_gasto(total DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF total >= 15000 THEN
        RETURN 'Alto';
    ELSEIF total >= 8000 THEN
        RETURN 'Medio';
    ELSE
        RETURN 'Bajo';
    END IF;
END$$
DELIMITER ;
```

**Estructura del IF en funciones:**
```sql
IF condicion THEN
    -- código
ELSEIF otra_condicion THEN
    -- código
ELSE
    -- código por defecto
END IF;   -- ← el END IF es OBLIGATORIO
```

---

### Cómo ver las funciones creadas

```sql
SHOW FUNCTION STATUS WHERE Db = 'bruma_cafe';

-- Borrar una función:
DROP FUNCTION IF EXISTS calcular_puntos;
```

---

## 5. Triggers

### ¿Qué es un Trigger?

Un bloque de código que **se ejecuta automáticamente** cuando ocurre un evento (`INSERT`, `UPDATE`, `DELETE`) sobre una tabla específica. No se llama manualmente, MySQL lo dispara solo.

---

### Cuándo se ejecuta

| Momento | Descripción | Uso típico |
|---------|-------------|------------|
| `BEFORE` | Justo antes del evento | Validaciones, cancelar operación |
| `AFTER` | Justo después del evento | Auditoría, registrar cambios |

| Evento | Cuándo |
|--------|--------|
| `INSERT` | Al insertar una fila |
| `UPDATE` | Al modificar una fila |
| `DELETE` | Al eliminar una fila |

---

### NEW y OLD — acceder a los valores

| | `NEW` | `OLD` |
|--|-------|-------|
| `INSERT` | ✅ valor que se va a insertar | ❌ no existe |
| `UPDATE` | ✅ valor nuevo | ✅ valor anterior |
| `DELETE` | ❌ no existe | ✅ valor que se va a borrar |

```sql
-- En un trigger de INSERT:
NEW.cantidad   -- el valor que el usuario quiere insertar

-- En un trigger de UPDATE:
OLD.precio     -- precio antes del cambio
NEW.precio     -- precio después del cambio
```

---

### Estructura completa

```sql
DELIMITER $$
CREATE TRIGGER nombre_trigger
BEFORE INSERT ON nombre_tabla    -- BEFORE/AFTER + INSERT/UPDATE/DELETE
FOR EACH ROW                     -- se ejecuta por cada fila afectada
BEGIN
    -- lógica aquí
    -- puede usar NEW y/o OLD según el tipo
END$$
DELIMITER ;
```

---

### Trigger del examen: validar cantidad

```sql
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
```

**¿Qué hace `SIGNAL SQLSTATE '45000'`?**
Lanza un error personalizado y **cancela la operación** por completo.
`'45000'` es el código estándar de MySQL para errores definidos por el usuario.
Si el trigger es `BEFORE`, cancela el INSERT/UPDATE/DELETE antes de que ocurra.

**Prueba:**
```sql
-- Esto falla con el trigger activo:
INSERT INTO detalle_ticket (id_ticket, id_producto, cantidad) VALUES (101, 'P10', 0);
-- Error Code: 1644. Error: La cantidad debe ser mayor a 0.

-- Esto funciona bien:
INSERT INTO detalle_ticket (id_ticket, id_producto, cantidad) VALUES (101, 'P10', 3);
```

---

### Trigger extra: AFTER INSERT para auditoría

```sql
DELIMITER $$
CREATE TRIGGER after_detalle_insert
AFTER INSERT ON detalle_ticket
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (descripcion)
    VALUES (CONCAT(
        'Nueva compra — Ticket #', NEW.id_ticket,
        ' | Producto: ', NEW.id_producto,
        ' | Cantidad: ', NEW.cantidad
    ));
END$$
DELIMITER ;
```

`CONCAT()` une strings. Si alguno de los valores es NULL, el resultado completo es NULL.
Alternativa segura: `CONCAT_WS(' | ', val1, val2, val3)` ignora los NULLs.

---

### Trigger extra: BEFORE UPDATE

```sql
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
```

---

### Cómo ver y borrar triggers

```sql
-- Ver todos los triggers de la BD:
SHOW TRIGGERS FROM bruma_cafe;

-- Ver triggers de una tabla específica:
SHOW TRIGGERS FROM bruma_cafe LIKE 'detalle_ticket';

-- Borrar un trigger:
DROP TRIGGER IF EXISTS before_detalle_insert;
```

> ⚠️ Solo puede existir **un trigger por combinación** de momento + evento + tabla.
> No puedes tener dos `BEFORE INSERT` sobre `detalle_ticket`.

---

## 6. Eventos

### ¿Qué es un Evento?

Una tarea programada que MySQL ejecuta **automáticamente** en un momento específico o de forma periódica, sin que nadie la llame manualmente. Como un cron job dentro de la base de datos.

---

### Requisito obligatorio: activar el Event Scheduler

El scheduler está **apagado por defecto**. Sin activarlo, los eventos existen pero nunca corren.

```sql
-- Activar:
SET GLOBAL event_scheduler = ON;

-- Verificar:
SHOW VARIABLES LIKE 'event_scheduler';
-- Debe mostrar: event_scheduler | ON
```

---

### Estructura completa

```sql
DELIMITER $$
CREATE EVENT nombre_evento
ON SCHEDULE
    EVERY 1 MONTH                       -- frecuencia
    STARTS '2026-04-01 00:00:00'        -- cuándo empieza
    -- ENDS '2027-04-01 00:00:00'       -- cuándo termina (opcional)
DO
BEGIN
    -- lógica del evento
    DELETE FROM tabla WHERE condicion;
    INSERT INTO auditoria_log (descripcion) VALUES ('texto');
END$$
DELIMITER ;
```

---

### Tipos de programación

**Ejecución única — AT**
```sql
ON SCHEDULE AT '2026-12-31 23:59:59'
-- Se ejecuta una sola vez en esa fecha/hora exacta
```

**Ejecución periódica — EVERY**
```sql
ON SCHEDULE EVERY 1 MINUTE
ON SCHEDULE EVERY 30 MINUTE
ON SCHEDULE EVERY 6 HOUR
ON SCHEDULE EVERY 1 DAY
ON SCHEDULE EVERY 1 WEEK
ON SCHEDULE EVERY 1 MONTH
ON SCHEDULE EVERY 1 YEAR
```

**Con STARTS y ENDS**
```sql
ON SCHEDULE EVERY 1 DAY
STARTS '2026-04-01 06:00:00'   -- empieza el 1 de abril a las 6 AM
ENDS   '2026-12-31 06:00:00'   -- termina el 31 de diciembre
```

---

### Evento del examen: limpieza mensual

```sql
DELIMITER $$
CREATE EVENT limpieza_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-04-01 00:00:00'
DO
BEGIN
    -- Borra logs con más de 30 días
    DELETE FROM auditoria_log
    WHERE fecha_log < NOW() - INTERVAL 30 DAY;

    -- Registra que se ejecutó
    INSERT INTO auditoria_log (descripcion)
    VALUES ('Limpieza mensual ejecutada automáticamente.');
END$$
DELIMITER ;
```

**`NOW() - INTERVAL 30 DAY`** — resta 30 días a la fecha actual.
Otras variantes: `INTERVAL 1 MONTH`, `INTERVAL 7 DAY`, `INTERVAL 1 YEAR`

---

### Evento extra: diario con DECLARE

```sql
DELIMITER $$
CREATE EVENT reporte_ventas_diario
ON SCHEDULE EVERY 1 DAY
STARTS '2026-04-01 06:00:00'
DO
BEGIN
    DECLARE total_tickets INT;    -- variable local

    SELECT COUNT(*) INTO total_tickets   -- guardar resultado en variable
    FROM tickets
    WHERE fecha = CURDATE() - INTERVAL 1 DAY;

    INSERT INTO auditoria_log (descripcion)
    VALUES (CONCAT('Reporte: ', total_tickets, ' tickets el ',
                   DATE(NOW() - INTERVAL 1 DAY)));
END$$
DELIMITER ;
```

**`SELECT ... INTO variable`** — guarda el resultado de un SELECT en una variable local.
Solo funciona si el SELECT devuelve exactamente 1 fila y 1 columna.

---

### Gestión de eventos

```sql
-- Ver todos los eventos:
SHOW EVENTS FROM bruma_cafe;

-- Pausar sin borrar:
ALTER EVENT limpieza_mensual DISABLE;

-- Reactivar:
ALTER EVENT limpieza_mensual ENABLE;

-- Borrar:
DROP EVENT IF EXISTS limpieza_mensual;
```

---

### Simular un evento manualmente (para probar)

Los eventos no tienen botón de "ejecutar ahora". Para probar, copia el cuerpo del evento y córrelo directamente:

```sql
-- Simulación manual de limpieza_mensual:
DELETE FROM auditoria_log WHERE fecha_log < NOW() - INTERVAL 30 DAY;
INSERT INTO auditoria_log (descripcion) VALUES ('Limpieza manual de prueba.');
SELECT * FROM auditoria_log ORDER BY fecha_log DESC;
```

---

## 7. Cheatsheet rápido para el examen

### JOINs

```sql
-- INNER JOIN → solo coincidencias en ambas tablas
FROM tabla_a a INNER JOIN tabla_b b ON a.id = b.id_a

-- LEFT JOIN → todos de la izquierda + coincidencias
FROM tabla_a a LEFT JOIN tabla_b b ON a.id = b.id_a

-- LEFT JOIN + IS NULL → los que NO tienen par
FROM tabla_a a LEFT JOIN tabla_b b ON a.id = b.id_a WHERE b.id IS NULL

-- 4 tablas (patrón del examen):
FROM detalle_ticket d
INNER JOIN tickets   t ON d.id_ticket   = t.id_ticket
INNER JOIN clientes  c ON t.id_cliente  = c.id_cliente
INNER JOIN productos p ON d.id_producto = p.id_producto
```

### Subconsultas

```sql
-- Escalar (1 valor) → =, >, <
WHERE precio > (SELECT AVG(precio) FROM productos)

-- Lista → IN / NOT IN
WHERE id IN (SELECT id FROM tabla WHERE condicion)

-- Existencia → EXISTS / NOT EXISTS
WHERE EXISTS (SELECT 1 FROM tabla WHERE tabla.fk = principal.pk)

-- Tabla derivada → en el FROM con alias
FROM (SELECT ...) AS alias_obligatorio
```

### Funciones

```sql
DELIMITER $$
CREATE FUNCTION nombre(param TIPO) RETURNS TIPO DETERMINISTIC
BEGIN
    RETURN valor;
END$$
DELIMITER ;

-- Llamar:
SELECT nombre(argumento);
SELECT nombre(columna) FROM tabla;
```

### Triggers

```sql
DELIMITER $$
CREATE TRIGGER nombre
BEFORE INSERT ON tabla          -- BEFORE/AFTER + INSERT/UPDATE/DELETE
FOR EACH ROW
BEGIN
    IF NEW.campo <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'mensaje de error';
    END IF;
END$$
DELIMITER ;

-- NEW → valor nuevo (INSERT/UPDATE)
-- OLD → valor anterior (UPDATE/DELETE)
-- SIGNAL → lanza error y cancela la operación
```

### Eventos

```sql
SET GLOBAL event_scheduler = ON;   -- SIEMPRE primero

DELIMITER $$
CREATE EVENT nombre
ON SCHEDULE EVERY 1 MONTH STARTS 'YYYY-MM-DD HH:MM:SS'
DO BEGIN
    -- lógica
END$$
DELIMITER ;

-- AT para una sola vez:
ON SCHEDULE AT 'YYYY-MM-DD HH:MM:SS'
```

### Funciones de agregación

| Función | Qué hace |
|---------|----------|
| `SUM(col)` | Suma todos los valores |
| `COUNT(col)` | Cuenta filas no nulas |
| `COUNT(*)` | Cuenta todas las filas |
| `AVG(col)` | Promedio |
| `MAX(col)` | Valor máximo |
| `MIN(col)` | Valor mínimo |

### Errores más comunes en examen

| Error | Causa | Solución |
|-------|-------|----------|
| `Subquery returns more than 1 row` | Usaste `=` con subconsulta que devuelve varias filas | Cambia `=` por `IN` |
| `Unknown column in HAVING` | Usaste alias del SELECT en HAVING | Repite la expresión: `HAVING SUM(...) > 1000` |
| `GROUP BY incompatible` | Columna en SELECT no está en GROUP BY | Agrega todas las columnas no-agregadas al GROUP BY |
| `SIGNAL` no cancela | Trigger es AFTER | Cambia a BEFORE para poder cancelar |
| Eventos no se ejecutan | Scheduler apagado | `SET GLOBAL event_scheduler = ON` |

---

> 💡 **Orden de ejecución de un SELECT:**
> `FROM` → `JOIN` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`
> Por eso no puedes usar alias del SELECT en el WHERE (el WHERE se evalúa antes).
