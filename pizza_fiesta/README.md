# 🍕 Pizza Fiesta — README Completo

> Base de datos MySQL para gestión de pedidos, productos, ingredientes y pagos de una pizzería.

---

## 📌 Índice

1. [Cómo ejecutar el proyecto](#1-cómo-ejecutar-el-proyecto)
2. [Diagrama de la base de datos](#2-diagrama-de-la-base-de-datos)
3. [Qué hace cada tabla](#3-qué-hace-cada-tabla)
4. [Explicación de cada consulta](#4-explicación-de-cada-consulta)
5. [Conceptos clave que debes saber](#5-conceptos-clave-que-debes-saber)
6. [Errores comunes y cómo evitarlos](#6-errores-comunes-y-cómo-evitarlos)

---

## 1. Cómo ejecutar el proyecto

Tienes 3 archivos SQL. Deben ejecutarse **en este orden exacto**:

```
1. pizza_fiesta_estructura.sql  → Crea la BD y todas las tablas
2. pizza_fiesta_datos.sql       → Inserta los datos de prueba
3. pizza_fiesta_consultas.sql   → Las 21 consultas para probar
```

### En MySQL Workbench:
1. Abre el archivo con `File → Open SQL Script`
2. Selecciona todo con `Ctrl + A`
3. Ejecuta con `Ctrl + Shift + Enter`

### En consola:
```bash
mysql -u root -p < pizza_fiesta_estructura.sql
mysql -u root -p < pizza_fiesta_datos.sql
```

> ⚠️ Si ejecutas `datos.sql` antes que `estructura.sql` vas a obtener error porque las tablas no existen todavía.

---

## 2. Diagrama de la base de datos

```
┌─────────────┐
│   clientes  │
│─────────────│
│ id_cliente  │◄──────────────────────────────┐
│ nombre      │                               │
│ telefono    │                               │
│ direccion   │                               │
└─────────────┘                               │
                                              │
┌────────────────────────────────────────┐    │
│               pedidos                  │    │
│────────────────────────────────────────│    │
│ id_pedido      (PK)                    │    │
│ id_cliente     (FK) ───────────────────┼────┘
│ fecha_pedido                           │
│ hora_recogida                          │
│ estado_pago  (pendiente | pagado)      │
│ estado_pedido (en espera | en prep..) │
│ total                                  │
└──────────┬─────────────────────────────┘
           │ 1:N
           ▼
┌────────────────────┐      ┌─────────────────┐
│   detalle_pedido   │      │    productos     │
│────────────────────│      │─────────────────│
│ id_detalle  (PK)   │      │ id_producto (PK)│
│ id_pedido   (FK)   │      │ nombre          │
│ id_producto (FK) ─────────►tipo             │
│ cantidad           │      │ tamanio         │
│ precio_unitario    │      │ precio          │
└──────────┬─────────┘      │ disponible      │
           │ 1:N            └────────┬────────┘
           ▼                        │ N:M
┌──────────────────────────┐        ▼
│ detalle_ingredientes_ext │  ┌──────────────────────┐
│──────────────────────────│  │  pizza_ingredientes  │
│ id_extra       (PK)      │  │──────────────────────│
│ id_detalle     (FK)      │  │ id_pizza_ing  (PK)   │
│ id_ingrediente (FK) ──┐  │  │ id_producto   (FK)   │
│ cantidad              │  │  │ id_ingrediente(FK) ──┐
│ costo_unitario        │  │  └──────────────────────┘│
└───────────────────────┼──┘                          │
                        │   ┌──────────────────┐      │
                        └──►│   ingredientes   │◄─────┘
                            │──────────────────│
                            │ id_ingrediente(PK│
                            │ nombre           │
                            │ costo_extra      │
                            └──────────────────┘

┌──────────────────────┐
│        pagos         │
│──────────────────────│
│ id_pago    (PK)      │
│ id_pedido  (FK) ─────►pedidos
│ fecha_pago           │
│ monto                │
│ metodo_pago          │
└──────────────────────┘

┌──────────────────────────────┐
│        combo_detalle         │
│──────────────────────────────│
│ id_combo_det (PK)            │
│ id_combo     (FK) ───────────►productos (tipo='combo')
│ id_producto  (FK) ───────────►productos (pizza/bebida)
└──────────────────────────────┘
```

### Flujo completo de un pedido

```
cliente hace pedido
       ↓
   pedidos  →  cabecera: quién, cuándo, hora de recogida
       ↓
detalle_pedido  →  qué productos pidió y a qué precio
       ↓
detalle_ingredientes_extra  →  personalizaciones de cada pizza
       ↓
pagos  →  al pagar, el pedido pasa a preparación
```

---

## 3. Qué hace cada tabla

### `clientes`
Guarda la info de cada cliente. No se relaciona directamente con productos — los clientes se vinculan a través de los pedidos.

```
id_cliente  → número único autoincremental (PK)
nombre      → nombre completo
telefono    → número de contacto
direccion   → dirección de referencia
```

---

### `ingredientes`
Catálogo de todos los ingredientes disponibles en la pizzería.

```
id_ingrediente → número único (PK)
nombre         → nombre del ingrediente  ej: "Champiñones"
costo_extra    → cuánto se le cobra al cliente si lo añade como personalización
                 ej: añadir Pepperoni = $8.00 adicional
```

---

### `productos`
Tabla unificada para **pizzas, bebidas y combos**. Todo está en una sola tabla para simplificar los JOINs.

```
id_producto  → número único (PK)
nombre       → ej: "Pepperoni Mediana", "Coca-Cola 500ml"
tipo         → ENUM: 'pizza' | 'bebida' | 'combo'
tamanio      → ENUM: 'pequeña' | 'mediana' | 'grande' | NULL
               NULL para bebidas y combos porque no tienen tamaño
precio       → precio base del producto
disponible   → 1 = activo en el menú, 0 = retirado del menú
               flag de eliminación lógica
```

**¿Por qué todo en una sola tabla?**
Porque en `detalle_pedido` siempre se referencia con `id_producto`, sin importar si es pizza, bebida o combo. Si estuvieran en tablas separadas habría que hacer UNION o múltiples JOINs para cada tipo.

---

### `pizza_ingredientes`
Define la **receta base** de cada pizza — los ingredientes que trae incluidos por defecto, sin costo extra.

```
id_pizza_ing   → PK
id_producto    → la pizza (FK a productos)
id_ingrediente → el ingrediente incluido (FK a ingredientes)
```

Ejemplo: la Margherita lleva Salsa de tomate + Mozzarella + Albahaca.
Esos tres ingredientes tienen una fila cada uno en esta tabla apuntando a la Margherita.

---

### `combo_detalle`
Define **qué productos incluye cada combo**. Un combo tiene varias filas, una por producto incluido.

```
id_combo_det → PK
id_combo     → el combo (FK a productos donde tipo='combo')
id_producto  → pizza o bebida dentro del combo (FK a productos)
```

Ejemplo: el Combo Familiar incluye Pepperoni Grande + BBQ Pollo Grande + 2x Coca-Cola → 4 filas en esta tabla.

---

### `pedidos`
La **cabecera del pedido**. Un pedido por cliente con su estado actual.

```
id_pedido     → PK
id_cliente    → quién hizo el pedido (FK a clientes)
fecha_pedido  → fecha y hora del pedido (DEFAULT NOW())
hora_recogida → hora que el cliente indicó para recoger
estado_pago   → 'pendiente' (recién creado) | 'pagado' (ya canceló)
estado_pedido → 'en espera' → 'en preparacion' → 'listo'
total         → total del pedido
```

**Regla de negocio clave:**
`estado_pedido` solo cambia a `'en preparacion'` cuando `estado_pago = 'pagado'`.
Los pedidos NO se preparan si no se ha confirmado el pago.

---

### `detalle_pedido`
Una fila por cada **producto dentro del pedido**.

```
id_detalle      → PK
id_pedido       → a qué pedido pertenece (FK)
id_producto     → qué producto se pidió (FK)
cantidad        → cuántas unidades
precio_unitario → precio al momento de hacer el pedido (SNAPSHOT HISTÓRICO)
```

**¿Por qué guardar `precio_unitario` aquí?**
Si mañana el precio de la Pepperoni Mediana sube de $110 a $125, los pedidos de hoy deben seguir mostrando $110 (lo que realmente se cobró). Si usáramos `productos.precio` directamente, el historial cambiaría con cada actualización.

---

### `detalle_ingredientes_extra`
Los **ingredientes adicionales** que el cliente añadió a una pizza específica.

```
id_extra       → PK
id_detalle     → a qué línea del pedido pertenece (FK a detalle_pedido)
id_ingrediente → qué ingrediente añadió (FK)
cantidad       → cuántas unidades del ingrediente extra
costo_unitario → precio del extra al momento del pedido (snapshot histórico)
```

**¿Por qué referencia `id_detalle` y no `id_pedido`?**
Porque si un pedido tiene dos pizzas distintas, cada una puede tener extras diferentes. Necesitamos saber exactamente a cuál pizza se le añadió cada extra.

---

### `pagos`
Registra el pago de cada pedido.

```
id_pago     → PK
id_pedido   → qué pedido se pagó (FK)
fecha_pago  → cuándo se realizó el pago
monto       → cuánto pagó
metodo_pago → ENUM: 'efectivo' | 'tarjeta' | 'transferencia'
```

Los pedidos 3, 7 y 12 están `pendiente` y no tienen registro en pagos — correcto, aún no han pagado.

---

## 4. Explicación de cada consulta

### Consulta 1 — Registrar un nuevo cliente

```sql
INSERT INTO clientes (nombre, telefono, direccion)
VALUES ('Juan Martínez', '555-2001', 'Calle 30 #15-40');
```

`INSERT INTO tabla (columnas) VALUES (valores)` agrega una nueva fila.
No se especifica `id_cliente` porque es `AUTO_INCREMENT` — MySQL le asigna el siguiente número solo.

---

### Consulta 2 — Agregar una pizza al menú

```sql
INSERT INTO productos (nombre, tipo, tamanio, precio)
VALUES ('Cuatro Quesos Mediana', 'pizza', 'mediana', 115.00);
```

No se pone `disponible` porque su `DEFAULT` es `1` — queda activa automáticamente.
`tamanio` debe ser uno de los valores del ENUM: `'pequeña'`, `'mediana'` o `'grande'`.

---

### Consulta 3 — Registrar una bebida

```sql
INSERT INTO productos (nombre, tipo, tamanio, precio)
VALUES ('Limonada 500ml', 'bebida', NULL, 28.00);
```

`tamanio` va como `NULL` porque las bebidas no tienen tamaño. El campo está definido como nullable en la tabla.

---

### Consulta 4 — Agregar un ingrediente

```sql
INSERT INTO ingredientes (nombre, costo_extra)
VALUES ('Queso Azul', 7.00);
```

`costo_extra` es lo que se cobra al cliente por personalización. Si fuera un ingrediente sin costo adicional, iría `0.00`.

---

### Consulta 5 — Crear un pedido

```sql
INSERT INTO pedidos (id_cliente, hora_recogida)
VALUES (1, '15:00:00');
```

Solo se necesita el `id_cliente` y la `hora_recogida` porque:
- `fecha_pedido` toma `NOW()` automáticamente
- `estado_pago` empieza en `'pendiente'` por DEFAULT
- `estado_pedido` empieza en `'en espera'` por DEFAULT
- `total` empieza en `0.00`

---

### Consulta 6 — Añadir productos al pedido

```sql
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
VALUES
    (LAST_INSERT_ID(), 6,  1, 110.00),
    (LAST_INSERT_ID(), 13, 2,  25.00);
```

`LAST_INSERT_ID()` devuelve el ID generado por el último INSERT — así no necesitas saber de memoria qué número le tocó al pedido recién creado.

Se insertan múltiples filas en un solo INSERT separando los `VALUES` con coma.

---

### Consulta 7 — Añadir ingredientes extra

```sql
INSERT INTO detalle_ingredientes_extra (id_detalle, id_ingrediente, cantidad, costo_unitario)
VALUES (1, 3, 1, 6.00);
```

`id_detalle = 1` → la línea 1 del pedido (la pizza específica que recibe el extra).
`id_ingrediente = 3` → Champiñones.
`costo_unitario = 6.00` → se guarda el precio actual como snapshot.

---

### Consulta 8a — Detalle de productos de un pedido

```sql
SELECT dp.id_detalle, pr.nombre AS producto, pr.tipo, pr.tamanio,
       dp.cantidad, dp.precio_unitario,
       (dp.cantidad * dp.precio_unitario) AS subtotal
FROM detalle_pedido dp
INNER JOIN productos pr ON dp.id_producto = pr.id_producto
WHERE dp.id_pedido = 1;
```

JOIN entre `detalle_pedido` y `productos` para obtener nombre y tipo del producto.
Columna calculada: `cantidad * precio_unitario` = subtotal de esa línea.

---

### Consulta 8b — Ingredientes extra de un pedido

```sql
SELECT dp.id_detalle, pr.nombre AS pizza,
       i.nombre AS ingrediente_extra, die.cantidad,
       die.costo_unitario,
       (die.cantidad * die.costo_unitario) AS costo_extra_total
FROM detalle_ingredientes_extra die
INNER JOIN detalle_pedido dp ON die.id_detalle     = dp.id_detalle
INNER JOIN productos      pr ON dp.id_producto     = pr.id_producto
INNER JOIN ingredientes   i  ON die.id_ingrediente = i.id_ingrediente
WHERE dp.id_pedido = 1;
```

3 JOINs encadenados:
1. `die → dp` para saber a qué línea del pedido pertenece el extra
2. `dp → pr` para saber el nombre de la pizza que tiene el extra
3. `die → i` para saber el nombre del ingrediente añadido

---

### Consulta 9 — Actualizar precio de una pizza

```sql
UPDATE productos
SET precio = 125.00
WHERE id_producto = 6 AND tipo = 'pizza';
```

`UPDATE tabla SET columna = valor WHERE condicion`.
El `AND tipo = 'pizza'` es doble validación por seguridad.
Los pedidos anteriores NO se ven afectados porque `precio_unitario` fue guardado como snapshot.

---

### Consulta 10 — Actualizar dirección de un cliente

```sql
UPDATE clientes
SET direccion = 'Carrera 20 #55-70'
WHERE id_cliente = 2;
```

**Nunca hagas UPDATE sin WHERE** — sin él, se actualizarían TODOS los registros de la tabla.

---

### Consulta 11 — Eliminar una bebida del menú

```sql
UPDATE productos
SET disponible = 0
WHERE id_producto = 14 AND tipo = 'bebida';
```

**Eliminación lógica** — se marca `disponible = 0` en lugar de borrar físicamente.

¿Por qué no un DELETE directo?
Porque si ese producto ya fue usado en pedidos anteriores, MySQL lanzaría error de FK: no puedes borrar un registro padre si tiene hijos apuntándole. Con `disponible = 0` el producto desaparece del menú pero el historial queda intacto.

---

### Consulta 12 — Eliminar un ingrediente

```sql
DELETE FROM pizza_ingredientes WHERE id_ingrediente = 12;
DELETE FROM ingredientes       WHERE id_ingrediente = 12;
```

Dos pasos en orden obligatorio:
1. Primero se eliminan las referencias en `pizza_ingredientes` (tabla hija)
2. Luego se elimina el ingrediente en `ingredientes` (tabla padre)

Si lo haces al revés, MySQL lanza error: "no puedes borrar el padre si tiene hijos".

---

### Consulta 13 — Todos los pedidos de un cliente

```sql
SELECT p.id_pedido, p.fecha_pedido, p.hora_recogida,
       p.estado_pago, p.estado_pedido, p.total
FROM pedidos p
WHERE p.id_cliente = 1
ORDER BY p.fecha_pedido DESC;
```

No necesita JOIN porque `pedidos` ya tiene `id_cliente` directamente.
`ORDER BY fecha_pedido DESC` → el más reciente aparece primero.

---

### Consulta 14 — Productos disponibles en el menú

```sql
SELECT id_producto, nombre, tipo, COALESCE(tamanio, '—') AS tamanio, precio
FROM productos
WHERE disponible = 1 AND tipo IN ('pizza', 'bebida')
ORDER BY tipo, tamanio, precio;
```

`COALESCE(tamanio, '—')` → si `tamanio` es NULL (bebidas), muestra un guion en vez de NULL.
`tipo IN ('pizza', 'bebida')` → excluye los combos (se listan aparte en la consulta 19).
`disponible = 1` → solo los activos.

---

### Consulta 15 — Ingredientes disponibles

```sql
SELECT id_ingrediente, nombre, costo_extra
FROM ingredientes
ORDER BY nombre;
```

Lista simple del catálogo de ingredientes ordenado alfabéticamente, con su costo de personalización.

---

### Consulta 16 — Costo total de un pedido

```sql
SELECT
    p.id_pedido,
    c.nombre AS cliente,
    SUM(dp.cantidad * dp.precio_unitario)                      AS subtotal_productos,
    COALESCE(SUM(die.cantidad * die.costo_unitario), 0)        AS subtotal_extras,
    SUM(dp.cantidad * dp.precio_unitario)
        + COALESCE(SUM(die.cantidad * die.costo_unitario), 0)  AS total_pedido
FROM pedidos p
INNER JOIN clientes               c   ON p.id_cliente  = c.id_cliente
INNER JOIN detalle_pedido         dp  ON p.id_pedido   = dp.id_pedido
LEFT  JOIN detalle_ingredientes_extra die ON dp.id_detalle = die.id_detalle
WHERE p.id_pedido = 1
GROUP BY p.id_pedido, c.nombre;
```

**¿Por qué LEFT JOIN en los extras?**
Porque puede que el pedido no tenga ningún extra. Con INNER JOIN, si no hay extras ese pedido desaparecería del resultado. Con LEFT JOIN aparece igual, pero con NULL en los campos de extras.

**¿Por qué COALESCE(..., 0)?**
Porque `SUM(NULL)` devuelve NULL, no 0. COALESCE convierte ese NULL en 0 para que la suma total no quede en NULL.

---

### Consulta 17 — Clientes con más de 5 pedidos

```sql
SELECT c.id_cliente, c.nombre, c.telefono,
       COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
INNER JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre, c.telefono
HAVING total_pedidos > 5
ORDER BY total_pedidos DESC;
```

**¿Por qué HAVING y no WHERE?**
Porque `total_pedidos` es el resultado de `COUNT()`, una función de agregación. Las funciones de agregación no se pueden usar en WHERE — el WHERE se evalúa antes de agrupar, HAVING se evalúa después.

```
Orden de ejecución SQL:
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
```

---

### Consulta 18 — Pedidos para recoger después de cierta hora

```sql
SELECT p.id_pedido, c.nombre AS cliente,
       p.fecha_pedido, p.hora_recogida, p.estado_pedido
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE p.hora_recogida > '12:00:00'
ORDER BY p.hora_recogida;
```

`hora_recogida` es tipo `TIME` → se puede comparar directamente con `'HH:MM:SS'`.
Para cambiar la hora del filtro, simplemente cambia `'12:00:00'` por la que necesites.

---

### Consulta 19 — Combos con sus productos incluidos

```sql
SELECT combo.nombre AS combo, combo.precio AS precio_combo,
       pr.nombre AS producto_incluido, pr.tipo, pr.tamanio, pr.precio
FROM combo_detalle cd
INNER JOIN productos combo ON cd.id_combo    = combo.id_producto
INNER JOIN productos pr    ON cd.id_producto = pr.id_producto
ORDER BY combo.nombre, pr.tipo;
```

**Dos JOINs a la misma tabla `productos`** usando alias distintos:
- `combo` → trae el nombre y precio del combo
- `pr` → trae el nombre del producto incluido en el combo

Esto es necesario porque `combo_detalle` tiene dos FK que apuntan a la misma tabla `productos`.

---

### Consulta 20 — Pizzas con precio mayor a $100

```sql
SELECT nombre, tamanio, precio
FROM productos
WHERE tipo = 'pizza' AND precio > 100 AND disponible = 1
ORDER BY precio DESC;
```

Tres condiciones con AND:
- `tipo = 'pizza'` → solo pizzas
- `precio > 100` → el filtro del enunciado
- `disponible = 1` → solo las activas en el menú

---

### Consulta 21 — Ingresos por día, semana y mes

Las tres consultas usan la misma lógica — solo cambia cómo se agrupa la fecha.

**Por día:**
```sql
SELECT DATE(pg.fecha_pago) AS dia, SUM(pg.monto) AS ingresos_dia
FROM pagos pg
INNER JOIN pedidos p ON pg.id_pedido = p.id_pedido
WHERE p.estado_pago = 'pagado'
GROUP BY DATE(pg.fecha_pago)
ORDER BY dia DESC;
```
`DATE()` extrae solo la fecha de un DATETIME (quita la hora). Se agrupa por fecha para sumar todo lo cobrado en el día.

**Por semana:**
```sql
SELECT YEAR(pg.fecha_pago) AS anio, WEEK(pg.fecha_pago, 1) AS semana,
       MIN(DATE(pg.fecha_pago)) AS inicio_semana,
       SUM(pg.monto) AS ingresos_semana
FROM pagos pg
INNER JOIN pedidos p ON pg.id_pedido = p.id_pedido
WHERE p.estado_pago = 'pagado'
GROUP BY YEAR(pg.fecha_pago), WEEK(pg.fecha_pago, 1)
ORDER BY anio DESC, semana DESC;
```
`WEEK(fecha, 1)` → número de semana del año. El `1` indica que la semana empieza el lunes (modo ISO).
Se agrupa por `YEAR + WEEK` para no mezclar semana 10 del 2025 con semana 10 del 2026.

**Por mes:**
```sql
SELECT YEAR(pg.fecha_pago) AS anio, MONTH(pg.fecha_pago) AS mes_numero,
       MONTHNAME(pg.fecha_pago) AS mes_nombre,
       SUM(pg.monto) AS ingresos_mes
FROM pagos pg
INNER JOIN pedidos p ON pg.id_pedido = p.id_pedido
WHERE p.estado_pago = 'pagado'
GROUP BY YEAR(pg.fecha_pago), MONTH(pg.fecha_pago), MONTHNAME(pg.fecha_pago)
ORDER BY anio DESC, mes_numero DESC;
```
`MONTHNAME()` → nombre del mes en texto.
`MONTH()` → número del mes (1-12), necesario para el ORDER BY correcto.
`MONTHNAME()` va en el GROUP BY porque está en el SELECT y no es función de agregación.

---

## 5. Conceptos clave que debes saber

### PRIMARY KEY (PK)
Identifica de forma única cada fila. No puede repetirse ni ser NULL.
```sql
id_cliente INT NOT NULL AUTO_INCREMENT PRIMARY KEY
-- AUTO_INCREMENT: MySQL asigna el número automáticamente
```

---

### FOREIGN KEY (FK)
Vincula una columna con la PK de otra tabla. Garantiza integridad referencial — no puedes insertar un valor que no exista en la tabla referenciada.
```sql
FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
-- No puedes crear un pedido con un id_cliente inexistente
```

---

### ENUM
Limita los valores posibles a una lista fija. Cualquier otro valor lanza error.
```sql
estado_pago ENUM('pendiente','pagado') DEFAULT 'pendiente'
tipo        ENUM('pizza','bebida','combo')
```

---

### DEFAULT
Valor asignado automáticamente si no se especifica al insertar.
```sql
fecha_pedido DATETIME  DEFAULT NOW()  -- fecha y hora actual
disponible   TINYINT   DEFAULT 1      -- activo por defecto
total        DECIMAL   DEFAULT 0.00
```

---

### JOIN — resumen

| Tipo | Devuelve |
|------|----------|
| `INNER JOIN` | Solo filas con coincidencia en AMBAS tablas |
| `LEFT JOIN` | Todas las filas de la izquierda + coincidencias de la derecha (NULL si no hay) |
| `RIGHT JOIN` | Todas las filas de la derecha + coincidencias de la izquierda |

Patrón con 4 tablas (el más usado en este proyecto):
```sql
FROM detalle_pedido dp
INNER JOIN pedidos   p  ON dp.id_pedido   = p.id_pedido
INNER JOIN clientes  c  ON p.id_cliente   = c.id_cliente
INNER JOIN productos pr ON dp.id_producto = pr.id_producto
```

---

### GROUP BY + Funciones de agregación

Regla de oro: toda columna en el SELECT que **NO** sea función de agregación, debe estar en el GROUP BY.

| Función | Qué hace |
|---------|----------|
| `SUM(col)` | Suma todos los valores del grupo |
| `COUNT(*)` | Cuenta todas las filas del grupo |
| `COUNT(col)` | Cuenta filas no nulas |
| `AVG(col)` | Promedio del grupo |
| `MAX(col)` | Valor máximo del grupo |
| `MIN(col)` | Valor mínimo del grupo |

---

### WHERE vs HAVING

| | WHERE | HAVING |
|---|---|---|
| Cuándo filtra | Antes del GROUP BY | Después del GROUP BY |
| Qué filtra | Filas individuales | Grupos |
| Acepta funciones de agregación | ❌ No | ✅ Sí |

```sql
WHERE tipo = 'pizza'            -- filtra filas antes de agrupar
HAVING COUNT(pedidos) > 5       -- filtra grupos después de agrupar
```

---

### Funciones de fecha

| Función | Devuelve | Ejemplo |
|---------|----------|---------|
| `NOW()` | Fecha y hora actual | `2026-03-09 14:30:00` |
| `CURDATE()` | Solo fecha actual | `2026-03-09` |
| `DATE(datetime)` | Solo la fecha | `2026-03-09` |
| `YEAR(fecha)` | Año | `2026` |
| `MONTH(fecha)` | Número de mes | `3` |
| `MONTHNAME(fecha)` | Nombre del mes | `March` |
| `WEEK(fecha, 1)` | Número de semana ISO | `10` |

---

### COALESCE
Devuelve el primer valor no NULL de la lista.
```sql
COALESCE(tamanio, '—')         -- si tamanio es NULL → muestra '—'
COALESCE(SUM(extras), 0)       -- si SUM devuelve NULL → muestra 0
```

---

### Eliminación lógica vs física

| | Lógica | Física |
|---|---|---|
| Cómo | `UPDATE SET disponible = 0` | `DELETE FROM` |
| El registro desaparece | ❌ Sigue en BD | ✅ Se borra |
| Historial | ✅ Se preserva | ❌ Se pierde |
| Riesgo con FK | ✅ Sin riesgo | ❌ Error si tiene hijos |
| Cuándo usarla | Productos, usuarios | Datos sin dependencias |

---

## 6. Errores comunes y cómo evitarlos

| Error | Causa | Solución |
|-------|-------|----------|
| `a foreign key constraint fails` al insertar | FK que no existe en tabla padre | Verifica que el ID referenciado exista antes de insertar |
| `a foreign key constraint fails` al borrar | Intentas borrar un padre que tiene hijos | Borra primero los hijos, luego el padre |
| `Data truncated for column X` | Valor fuera del ENUM | Usa exactamente uno de los valores definidos en el ENUM |
| `Subquery returns more than 1 row` | `=` con subconsulta que devuelve varias filas | Cambia `=` por `IN` |
| `Unknown column in HAVING` | Alias del SELECT usado en HAVING | Repite la expresión: `HAVING SUM(...) > 100` |
| UPDATE sin WHERE | Actualizas todos los registros | Siempre poner WHERE en UPDATE y DELETE |
| GROUP BY incompleto | Columna en SELECT no está en GROUP BY | Agrega todas las columnas no-agregadas al GROUP BY |
| Eventos no se ejecutan | Event Scheduler apagado | `SET GLOBAL event_scheduler = ON` |

---

> 💡 **Orden de ejecución de un SELECT** — importante para entender por qué cada cláusula va donde va:
>
> `FROM` → `JOIN` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`
>
> Por eso WHERE no puede usar alias del SELECT (el WHERE se evalúa antes del SELECT),
> y HAVING sí puede usar funciones de agregación (se evalúa después del GROUP BY).
