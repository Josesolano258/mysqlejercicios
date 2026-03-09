# 🎬 Sakila — Sistema de Alquiler de Películas

> Base de datos MySQL para gestión de alquileres, clientes, películas, empleados y almacenes.

---

## 📌 Índice

1. [Descripción del Proyecto](#1-descripción-del-proyecto)
2. [Requisitos del Sistema](#2-requisitos-del-sistema)
3. [Instalación y Configuración](#3-instalación-y-configuración)
4. [Estructura del Repositorio](#4-estructura-del-repositorio)
5. [Diagrama de la Base de Datos](#5-diagrama-de-la-base-de-datos)
6. [Qué hace cada tabla](#6-qué-hace-cada-tabla)
7. [Explicación de las Consultas](#7-explicación-de-las-consultas)
8. [Explicación de las Funciones](#8-explicación-de-las-funciones)
9. [Explicación de los Triggers](#9-explicación-de-los-triggers)
10. [Explicación de los Eventos](#10-explicación-de-los-eventos)
11. [Conceptos Clave](#11-conceptos-clave)
12. [Errores Comunes](#12-errores-comunes)

---

## 1. Descripción del Proyecto

**Sakila** es una base de datos diseñada para gestionar las operaciones completas de una cadena de alquiler de películas. El sistema cubre:

- Registro de clientes, empleados y almacenes
- Catálogo de películas con categorías, actores e idiomas
- Control de inventario por almacén
- Gestión completa del ciclo de alquiler: registro, pago y devolución
- Automatización de tareas periódicas mediante eventos programados
- Auditoría de cambios y validaciones de negocio mediante triggers
- Lógica de negocio reutilizable mediante funciones almacenadas

**Datos de prueba incluidos:**
- 6 idiomas, 16 categorías, 20 actores, 30 películas
- 25 clientes, 5 empleados, 2 almacenes, 50 unidades de inventario
- ~70 alquileres distribuidos entre septiembre 2025 y marzo 2026
- El cliente 20 tiene `saldo_pendiente = 2.50` para probar el trigger de restricción

---

## 2. Requisitos del Sistema

| Componente | Versión recomendada |
|---|---|
| MySQL Server | 8.0 o superior |
| MySQL Workbench | 8.0 (opcional, para interfaz gráfica) |
| DBeaver | Cualquier versión reciente (alternativa) |
| Sistema Operativo | Windows, macOS o Linux |

> ⚠️ MySQL 5.7 también es compatible pero se recomienda 8.0 por mejor soporte de `DEFAULT NOW()` y manejo de expresiones en columnas.

---

## 3. Instalación y Configuración

Los archivos deben ejecutarse **en este orden exacto**. Si se ejecutan en otro orden, fallará por dependencias entre tablas (claves foráneas).

### Paso 1 — Crear la estructura de la BD
```bash
mysql -u root -p < ddl.sql
```
O en MySQL Workbench: `File → Open SQL Script → ddl.sql → Ctrl+A → Ctrl+Shift+Enter`

Esto crea la base de datos `sakila` con todas sus tablas, claves primarias, foráneas y las tablas auxiliares necesarias para triggers y eventos.

### Paso 2 — Cargar los datos de prueba
```bash
mysql -u root -p < dml.sql
```
Inserta todos los datos en el orden correcto respetando las dependencias de FK:
`language → category → actor → film → film_category → film_actor → country → city → address → store → staff → customer → inventory → rental → payment`

### Paso 3 — Ejecutar las consultas
```bash
mysql -u root -p sakila < dql_select.sql
```
Ejecuta las 20 consultas. Se puede correr todo el archivo o abrir en Workbench y ejecutar cada consulta individualmente seleccionándola.

### Paso 4 — Crear las funciones
```bash
mysql -u root -p sakila < dql_funciones.sql
```
> ⚠️ **Importante:** Las funciones usan `DELIMITER $$`. Siempre ejecuta el archivo **completo**, nunca línea por línea. Si lo copias a Workbench, asegúrate de seleccionar todo antes de ejecutar.

### Paso 5 — Crear los triggers
```bash
mysql -u root -p sakila < dql_triggers.sql
```
Los triggers se activan automáticamente desde el momento en que se crean. No requieren llamada manual.

### Paso 6 — Crear los eventos
```bash
# Primero activar el Event Scheduler (obligatorio):
mysql -u root -p sakila -e "SET GLOBAL event_scheduler = ON;"

# Luego crear los eventos:
mysql -u root -p sakila < dql_eventos.sql
```
> ⚠️ Sin `event_scheduler = ON` los eventos existen pero **nunca se ejecutan**. Al final del archivo hay una simulación manual para probar sin esperar a la fecha programada.

---

## 4. Estructura del Repositorio

```
sakila/
├── ddl.sql              → Creación de la BD, tablas y relaciones
├── dml.sql              → Inserción de datos de prueba
├── dql_select.sql       → 20 consultas SQL
├── dql_funciones.sql    → 5 funciones almacenadas
├── dql_triggers.sql     → 5 triggers
├── dql_eventos.sql      → 5 eventos programados
├── README.md            → Este archivo
└── Diagrama.jpg         → Modelo de datos (diagrama ER)
```

---

## 5. Diagrama de la Base de Datos

```
┌──────────────┐         ┌─────────────────────────────────────┐
│   language   │         │               film                  │
│──────────────│         │─────────────────────────────────────│
│ language_id  │◄────────│ film_id (PK)                        │
│ name         │         │ title                               │
└──────────────┘         │ language_id (FK)                    │
                         │ rental_rate                         │
                         │ rental_duration                     │
                         │ length / rating                     │
                         └──────────┬──────────────────────────┘
                                    │
               ┌────────────────────┼────────────────────┐
               ▼                    ▼                     ▼
      film_category            film_actor            inventory
      ─────────────            ──────────            ─────────────────
      film_id (FK)             actor_id (FK)         inventory_id (PK)
      category_id (FK)         film_id (FK)          film_id (FK)
            │                       │                store_id (FK)
            ▼                       ▼                     │
        category               actor                      │
        ────────               ──────                     │
        category_id (PK)       actor_id (PK)              ▼
        name                   first_name             rental
                               last_name              ──────────────────
                                                      rental_id (PK)
                                                      inventory_id (FK)
                                                      customer_id (FK)──►customer
                                                      staff_id (FK)────►staff
                                                      rental_date
                                                      return_date
                                                           │
                                                           ▼
                                                       payment
                                                       ──────────────────
                                                       payment_id (PK)
                                                       rental_id (FK)
                                                       customer_id (FK)
                                                       staff_id (FK)
                                                       amount

┌──────────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────────┐
│   country    │───►│   city   │───►│ address  │───►│ customer / staff │
└──────────────┘    └──────────┘    └──────────┘    └──────────────────┘
                                         │
                                         ▼
                                       store
                                    ──────────
                                    store_id (PK)
                                    address_id (FK)

Tablas auxiliares (para triggers y eventos):
────────────────────────────────────────────
auditoria_cliente         → registra cambios en customer
historial_costo_film      → registra cambios en rental_rate de film
notificacion_eliminacion  → registra alquileres eliminados
informe_mensual           → almacena informes y alertas generados por eventos
categoria_popular         → top categorías por mes generado por evento
```

### Flujo completo de un alquiler:

```
cliente solicita película
         ↓
    rental  →  se registra rental_date, inventory_id, customer_id, staff_id
         ↓
    payment →  se registra el pago (amount, payment_date)
         ↓
    rental.return_date  →  se actualiza cuando el cliente devuelve
```

---

## 6. Qué hace cada tabla

### `language`
Catálogo de idiomas disponibles para las películas. Una película tiene un solo idioma.

### `category`
Catálogo de géneros/categorías: Action, Comedy, Drama, Horror, etc.

### `actor`
Catálogo de actores. Se relaciona con películas a través de `film_actor` (relación N:M).

### `film`
Catálogo de películas. Contiene precio de alquiler (`rental_rate`), duración permitida de alquiler (`rental_duration` en días) y duración de la película en minutos (`length`).

### `film_category`
Tabla pivot N:M entre `film` y `category`. Una película puede tener varias categorías.

### `film_actor`
Tabla pivot N:M entre `film` y `actor`. Una película puede tener varios actores.

### `country → city → address`
Jerarquía geográfica. Se usa para la dirección de clientes, empleados y almacenes.

### `store`
Representa cada sucursal/almacén de la cadena. Tiene su propia dirección.

### `staff`
Empleados de la cadena. Cada empleado pertenece a un almacén. Tiene la columna `total_rentals` que se actualiza automáticamente con el trigger `ActualizarTotalAlquileresEmpleado`.

### `customer`
Clientes registrados. Tiene `saldo_pendiente` que se actualiza con el evento `ActualizarSaldoPendienteCliente` y es revisado por el trigger `RestringirAlquilerConSaldoPendiente`.

### `inventory`
Copias físicas de cada película en cada almacén. Una película puede tener varias copias en varios almacenes.

### `rental`
Registro de cada alquiler. Une inventario + cliente + empleado. `return_date` es NULL mientras el cliente no devuelve.

### `payment`
Registro del pago asociado a cada alquiler. `amount` es el monto cobrado.

### Tablas auxiliares

| Tabla | Para qué sirve |
|---|---|
| `auditoria_cliente` | Guarda cada cambio detectado en `customer` |
| `historial_costo_film` | Guarda cada cambio en `rental_rate` de una película |
| `notificacion_eliminacion` | Guarda datos de alquileres antes de ser eliminados |
| `informe_mensual` | Recibe los informes y alertas generados automáticamente por eventos |
| `categoria_popular` | Guarda el top 10 de categorías más alquiladas por mes |

---

## 7. Explicación de las Consultas

### Q1 — Cliente con más alquileres en los últimos 6 meses
```sql
WHERE r.rental_date >= NOW() - INTERVAL 6 MONTH
GROUP BY c.customer_id
ORDER BY COUNT(r.rental_id) DESC
LIMIT 1;
```
`NOW() - INTERVAL 6 MONTH` calcula la fecha exacta de hace 6 meses de forma dinámica, sin necesidad de hardcodear una fecha. `LIMIT 1` devuelve solo el top.

---

### Q2 — 5 películas más alquiladas en el último año
Necesita unir `film → inventory → rental` porque una película tiene múltiples copias en inventario. Para saber cuántas veces fue alquilada una película hay que contar desde `rental` y llegar a `film` pasando por `inventory`.

---

### Q3 — Ingresos y alquileres por categoría
La cadena de JOINs es:
```
category → film_category → film → inventory → rental → payment
```
6 tablas unidas. Se agrupa por `category_id` y se calculan `COUNT(rental_id)` y `SUM(amount)`.

---

### Q4 — Clientes por idioma en un mes específico
Filtra con `YEAR()` y `MONTH()` para aislar un mes. `COUNT(DISTINCT customer_id)` evita contar el mismo cliente dos veces si alquiló varias películas del mismo idioma en ese mes.

---

### Q5 — Clientes que alquilaron TODAS las películas de una categoría
Usa doble `NOT EXISTS`:
```sql
WHERE NOT EXISTS (
    -- película de la categoría que el cliente NO alquiló
    SELECT film_id FROM film_category WHERE category_id = 6
    AND film_id NOT IN (
        -- películas que el cliente SÍ alquiló
        SELECT film_id FROM rental JOIN inventory ...
        WHERE customer_id = c.customer_id
    )
)
```
Lógica: "no existe ninguna película de la categoría que no haya alquilado". Si no hay ningún hueco, alquiló todas.

---

### Q6 — 3 ciudades con más clientes activos en el último trimestre
Une la jerarquía geográfica: `city → address → customer → rental`. Filtra `c.active = 1` para clientes activos y `INTERVAL 3 MONTH` para el trimestre.

---

### Q7 — 5 categorías con menos alquileres en el último año
Usa `LEFT JOIN` en lugar de `INNER JOIN` para incluir categorías que tuvieron **cero** alquileres en el período. El filtro de fecha va en la cláusula `ON` del LEFT JOIN, no en `WHERE`, para no excluir las categorías sin alquileres.

```sql
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
    AND r.rental_date >= NOW() - INTERVAL 1 YEAR
-- Si fuera WHERE, las categorías sin alquileres desaparecerían del resultado
```

---

### Q8 — Promedio de días para devolver películas
`DATEDIFF(return_date, rental_date)` calcula los días entre las dos fechas. Solo incluye registros con `return_date IS NOT NULL` para no contar alquileres que aún no fueron devueltos.

---

### Q9 — 5 empleados con más alquileres de Acción
Misma cadena de JOINs que Q3 pero partiendo desde `staff`. Filtra `cat.name = 'Action'` antes de agrupar.

---

### Q10 — Clientes más recurrentes (informe completo)
Consolida tres métricas en una sola consulta: `COUNT` de alquileres, `SUM` del monto pagado y `MAX` de la fecha más reciente. Muestra los 10 clientes con más alquileres históricos.

---

### Q11 — Costo promedio de alquiler por idioma
`AVG(rental_rate)` agrupa directamente desde `film` sin necesitar pasar por `inventory` o `rental`, porque `rental_rate` es un atributo de la película, no del alquiler.

---

### Q12 — 5 películas más largas alquiladas en el último año
Ordena por `f.length DESC` para obtener las de mayor duración, pero solo entre las que tuvieron al menos un alquiler en el período. Sin el filtro de fecha, traería películas del catálogo que nadie alquiló.

---

### Q13 — Clientes que más alquilaron Comedia
Igual que Q9 pero para clientes y categoría `Comedy`. Incluye `LIMIT 10` para el top de clientes.

---

### Q14 — Total de días alquilados por cliente en el último mes
`COALESCE(r.return_date, NOW())` maneja los alquileres sin devolver: si `return_date` es NULL, usa la fecha actual para que esos alquileres no se pierdan del conteo.

---

### Q15 — Alquileres diarios por almacén en el último trimestre
`DATE(r.rental_date)` extrae solo la fecha de un DATETIME, quitando la hora. Agrupa por `día + store_id` para mostrar el comparativo entre los dos almacenes día a día.

---

### Q16 — Ingresos por almacén en el último semestre
La tabla `payment` no tiene `store_id` directamente. Hay que ir `payment → rental → inventory` para llegar al `store_id`.

---

### Q17 — Cliente con el alquiler más caro en el último año
Ordena por `p.amount DESC LIMIT 1`. Incluye el título de la película como contexto para el informe.

---

### Q18 — 5 categorías con más ingresos en los últimos 3 meses
Misma estructura que Q3 pero filtrada por `INTERVAL 3 MONTH` y ordenada por `SUM(amount)` en lugar de `COUNT`.

---

### Q19 — Películas alquiladas por idioma en el último mes
Agrupa por idioma contando alquileres del último mes. Útil para ver cuál idioma tiene más demanda reciente.

---

### Q20 — Clientes sin alquileres en el último año
```sql
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM rental
    WHERE rental_date >= NOW() - INTERVAL 1 YEAR
)
```
La subconsulta devuelve los IDs de clientes que SÍ alquilaron. Los que no están en esa lista, no han alquilado en el período. Útil para campañas de reactivación.

---

## 8. Explicación de las Funciones

### TotalIngresosCliente(ClienteID, Año)
```sql
SELECT COALESCE(SUM(p.amount), 0.00) INTO total
FROM payment p
WHERE p.customer_id = p_customer_id
  AND YEAR(p.payment_date) = p_anio;
```
- `COALESCE(..., 0.00)` maneja el caso donde el cliente no tiene pagos ese año — `SUM` de un conjunto vacío devuelve `NULL`, no `0`.
- `READS SQL DATA` indica que la función solo hace `SELECT`, no modifica datos.
- `DETERMINISTIC` indica que el mismo cliente + año siempre producirá el mismo resultado.

**Uso:**
```sql
SELECT TotalIngresosCliente(1, 2026);        -- ingresos del cliente 1 en 2026
SELECT TotalIngresosCliente(1, 2025);        -- ingresos del cliente 1 en 2025
```

---

### PromedioDuracionAlquiler(PeliculaID)
```sql
AVG(DATEDIFF(r.return_date, r.rental_date))
```
- `DATEDIFF(fecha_mayor, fecha_menor)` devuelve días entre dos fechas.
- Solo incluye alquileres con `return_date IS NOT NULL` (ya devueltos).
- `COALESCE(promedio, 0.00)` devuelve 0 si la película nunca fue alquilada.

**Uso:**
```sql
SELECT PromedioDuracionAlquiler(1);    -- promedio de días que se alquila la película 1
```

---

### IngresosPorCategoria(CategoriaID)
Necesita unir 4 tablas para llegar desde una categoría hasta los pagos:
```
payment → rental → inventory → film_category (filtra por category_id)
```

**Uso:**
```sql
SELECT IngresosPorCategoria(1);    -- ingresos totales de Action (id=1)
SELECT IngresosPorCategoria(5);    -- ingresos totales de Comedy (id=5)
```

---

### DescuentoFrecuenciaCliente(ClienteID)
Lógica escalonada con `IF / ELSEIF / ELSE`:

| Alquileres | Descuento |
|---|---|
| 20 o más | 15% |
| 10 a 19 | 10% |
| 5 a 9 | 5% |
| Menos de 5 | 0% |

Retorna un decimal (0.15, 0.10, etc.) para multiplicarlo por el precio:
```sql
SELECT rental_rate * (1 - DescuentoFrecuenciaCliente(customer_id)) AS precio_final
FROM film, customer WHERE film_id = 1 AND customer_id = 1;
```

---

### EsClienteVIP(ClienteID)
Criterio doble con `AND` — deben cumplirse **ambas** condiciones:
- Más de 15 alquileres totales
- Más de $30 gastados en total

```sql
IF total_alquileres > 15 AND total_ingresos > 30.00 THEN
    RETURN 'VIP';
ELSE
    RETURN 'Regular';
END IF;
```

**Uso:**
```sql
-- Ver estado de todos los clientes:
SELECT customer_id, CONCAT(first_name,' ',last_name) AS cliente,
       EsClienteVIP(customer_id) AS estado
FROM customer;
```

---

## 9. Explicación de los Triggers

### ActualizarTotalAlquileresEmpleado — AFTER INSERT en rental
```sql
UPDATE staff SET total_rentals = total_rentals + 1
WHERE staff_id = NEW.staff_id;
```
Usa `AFTER INSERT` porque necesita que el alquiler ya esté guardado. `NEW.staff_id` accede al empleado asignado en el registro recién insertado.

**Para verificar:**
```sql
SELECT staff_id, first_name, total_rentals FROM staff;
-- Inserta un alquiler y verifica que total_rentals aumentó en 1
```

---

### AuditarActualizacionCliente — AFTER UPDATE en customer
Compara `OLD.campo` con `NEW.campo` para cada columna relevante. Solo inserta en `auditoria_cliente` si el valor **realmente cambió**, evitando registros innecesarios.

```sql
IF OLD.email != NEW.email THEN
    INSERT INTO auditoria_cliente (...) VALUES (...);
END IF;
```

`CAST(valor AS CHAR)` convierte cualquier tipo de dato a texto para poder guardarlo en la columna `VARCHAR(200)` de auditoría.

**Para verificar:**
```sql
UPDATE customer SET email = 'nuevo@email.com' WHERE customer_id = 1;
SELECT * FROM auditoria_cliente;
```

---

### RegistrarHistorialDeCosto — BEFORE UPDATE en film
Usa `BEFORE UPDATE` porque quiere capturar el valor **anterior** (`OLD.rental_rate`) antes de que se modifique. Si usara `AFTER UPDATE`, el valor anterior ya estaría sobreescrito.

Solo actúa si `OLD.rental_rate != NEW.rental_rate` — si el precio no cambió, no hace nada.

**Para verificar:**
```sql
UPDATE film SET rental_rate = 5.99 WHERE film_id = 1;
SELECT * FROM historial_costo_film;
```

---

### NotificarEliminacionAlquiler — BEFORE DELETE en rental
Usa `BEFORE DELETE` porque después de ejecutarse el `DELETE`, los datos de `OLD` ya no existen en la base de datos. Con `BEFORE` puede leer `OLD.rental_id`, `OLD.customer_id`, etc. antes de que desaparezcan.

`CONCAT` construye el mensaje descriptivo de la notificación.

**Para verificar:**
```sql
DELETE FROM rental WHERE rental_id = 69;   -- el que no tiene payment
SELECT * FROM notificacion_eliminacion;
```

---

### RestringirAlquilerConSaldoPendiente — BEFORE INSERT en rental
```sql
SELECT saldo_pendiente INTO saldo
FROM customer WHERE customer_id = NEW.customer_id;

IF saldo > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error: El cliente tiene saldo pendiente...';
END IF;
```

- `SELECT ... INTO variable` guarda el resultado en una variable local.
- `SIGNAL SQLSTATE '45000'` lanza un error personalizado que **cancela el INSERT**.
- El código `'45000'` es el estándar de MySQL para errores definidos por el usuario.

**Para verificar** (el cliente 20 tiene saldo_pendiente = 2.50):
```sql
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (NOW(), 1, 20, 1);
-- → Error: El cliente tiene saldo pendiente. Regularice su cuenta antes de alquilar.
```

---

## 10. Explicación de los Eventos

### InformeAlquileresMensual — EVERY 1 MONTH (día 1, 1 AM)
Corre el primer día de cada mes a la 1 AM. Calcula automáticamente el mes anterior con `NOW() - INTERVAL 1 MONTH`. Usa `DECLARE` para variables locales y tres `SELECT ... INTO` para recolectar los datos antes de insertar en `informe_mensual`.

---

### ActualizarSaldoPendienteCliente — EVERY 1 MONTH (último día, 11 PM)
Recorre todos los clientes con alquileres sin devolver y calcula el saldo:
```sql
rental_rate * GREATEST(0, dias_transcurridos - rental_duration)
```
`GREATEST(0, ...)` evita que salga un número negativo para alquileres devueltos a tiempo. El saldo representa los días extras de demora multiplicados por la tarifa diaria.

---

### AlertaPeliculasNoAlquiladas — EVERY 1 MONTH (día 1, 2 AM)
Usa `NOT IN` con subconsulta para encontrar películas del catálogo que no aparecen en ningún alquiler del último año. Si hay películas sin alquilar, inserta una alerta en `informe_mensual` con el conteo.

---

### LimpiarAuditoriaCada6Meses — EVERY 6 MONTH
Corre cada 6 meses y borra registros de las 3 tablas de auditoría con más de 6 meses de antigüedad. Mantiene las tablas livianas sin acumular datos históricos indefinidamente.

---

### ActualizarCategoriasPopulares — EVERY 1 MONTH (último día, 11:30 PM)
```sql
SET v_mes_ref = DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01');
```
`DATE_FORMAT(..., '%Y-%m-01')` siempre devuelve el primer día del mes anterior (ej: `2026-02-01`). Borra el registro anterior del mismo mes antes de reinsertar — esto lo hace **idempotente** (se puede correr más de una vez sin duplicar datos). Guarda el top 10 de categorías.

---

## 11. Conceptos Clave

### Intervalos de tiempo dinámicos

| Expresión | Cuándo se usa |
|---|---|
| `NOW() - INTERVAL 1 MONTH` | Último mes |
| `NOW() - INTERVAL 3 MONTH` | Último trimestre |
| `NOW() - INTERVAL 6 MONTH` | Último semestre |
| `NOW() - INTERVAL 1 YEAR` | Último año |

La ventaja de estos intervalos es que **no necesitas actualizar la consulta** con fechas fijas — siempre calculan relativo al momento actual.

---

### LEFT JOIN vs INNER JOIN en reportes

Cuando necesitas incluir registros aunque no tengan datos relacionados (categorías sin alquileres, clientes sin pagos, etc.), usa `LEFT JOIN`. Con `INNER JOIN` esos registros desaparecerían del resultado.

```sql
-- INNER JOIN: solo categorías que tuvieron alquileres
FROM category INNER JOIN ... INNER JOIN rental

-- LEFT JOIN: TODAS las categorías, aunque no hayan tenido alquileres
FROM category LEFT JOIN ... LEFT JOIN rental
```

---

### Cuándo usar WHERE vs ON en el filtro de fecha con LEFT JOIN

```sql
-- ❌ INCORRECTO — el WHERE filtra DESPUÉS del JOIN y elimina filas con NULL
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_date >= NOW() - INTERVAL 1 YEAR
-- Esto equivale a un INNER JOIN: las categorías sin alquileres desaparecen

-- ✅ CORRECTO — el filtro va en el ON, antes del JOIN
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
    AND r.rental_date >= NOW() - INTERVAL 1 YEAR
-- Las categorías sin alquileres aparecen con COUNT = 0
```

---

### NOT EXISTS para lógica de "todos"

Para encontrar clientes que cumplan una condición con **todas** las filas de un conjunto, se usa doble negación:

```
"Clientes que alquilaron TODAS las películas de la categoría"
= "Clientes para los que NO EXISTE ninguna película de la categoría que NO hayan alquilado"
```

---

### SELECT ... INTO en funciones y eventos

```sql
DECLARE v_total INT;
SELECT COUNT(*) INTO v_total FROM rental WHERE customer_id = 1;
-- v_total ahora contiene el resultado del SELECT
```

Solo funciona cuando el SELECT devuelve **exactamente 1 fila y 1 columna**.

---

### SIGNAL SQLSTATE '45000'

Lanza un error personalizado desde un trigger o procedimiento. Cancela automáticamente la operación que lo disparó.

```sql
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Tu mensaje de error aquí';
```

`'45000'` es el código estándar de MySQL para errores definidos por el usuario (no reservado por el sistema).

---

### NEW y OLD en triggers

| | `NEW` | `OLD` |
|---|---|---|
| INSERT | ✅ Valor a insertar | ❌ No existe |
| UPDATE | ✅ Valor nuevo | ✅ Valor anterior |
| DELETE | ❌ No existe | ✅ Valor a borrar |

---

### Funciones de fecha útiles

| Función | Qué devuelve | Ejemplo |
|---|---|---|
| `NOW()` | Fecha y hora actual | `2026-03-09 14:30:00` |
| `CURDATE()` | Solo fecha actual | `2026-03-09` |
| `DATE(datetime)` | Extrae solo la fecha | `2026-03-09` |
| `YEAR(fecha)` | Año | `2026` |
| `MONTH(fecha)` | Mes (1-12) | `3` |
| `DATEDIFF(f1, f2)` | Días entre dos fechas | `6` |
| `DATE_FORMAT(f, fmt)` | Formato personalizado | `'2026-03-01'` |
| `GREATEST(a, b)` | El mayor de dos valores | `GREATEST(0, -3)` → `0` |
| `COALESCE(v, def)` | Primer valor no NULL | `COALESCE(NULL, 0)` → `0` |

---

### Orden de ejecución de un SELECT

```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

Lo más importante:
- `WHERE` se evalúa **antes** del `GROUP BY` → no puede usar funciones de agregación (`SUM`, `COUNT`, etc.)
- `HAVING` se evalúa **después** del `GROUP BY` → sí puede usar funciones de agregación
- Los alias del `SELECT` no están disponibles en el `WHERE` ni en el `HAVING` (en MySQL sí en `HAVING` pero no es estándar)

---

## 12. Errores Comunes

| Error | Causa | Solución |
|---|---|---|
| `Cannot add or update a child row: foreign key constraint fails` | Intentas insertar un FK que no existe en la tabla padre | Verifica que el ID referenciado exista antes de insertar |
| `Cannot delete or update a parent row: foreign key constraint fails` | Intentas borrar un registro que tiene hijos | Borra primero los hijos, luego el padre |
| `Data truncated for column` | Valor fuera del ENUM o tipo incorrecto | Usa exactamente uno de los valores definidos en el ENUM |
| `Subquery returns more than 1 row` | Usaste `=` con subconsulta que devuelve varias filas | Cambia `=` por `IN` |
| `Function already exists` | La función ya fue creada | Ejecuta `DROP FUNCTION IF EXISTS nombre;` antes de crearla |
| `Trigger already exists` | El trigger ya fue creado | Ejecuta `DROP TRIGGER IF EXISTS nombre;` antes de crearlo |
| `event_scheduler is disabled` | El scheduler está apagado | `SET GLOBAL event_scheduler = ON;` |
| `DELIMITER` no reconocido | Ejecutando línea por línea en consola | Usa `mysql -u root -p < archivo.sql` o ejecuta el archivo completo en Workbench |
| UPDATE sin WHERE | Se actualizan TODOS los registros de la tabla | Siempre incluir `WHERE` en `UPDATE` y `DELETE` |
