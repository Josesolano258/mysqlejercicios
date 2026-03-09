CREATE DATABASE IF NOT EXISTS sakila;
USE sakila;

CREATE TABLE language (
    language_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name          CHAR(20)         NOT NULL
);

CREATE TABLE category (
    category_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(25)      NOT NULL
);

CREATE TABLE actor (
    actor_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name  VARCHAR(45) NOT NULL,
    last_name   VARCHAR(45) NOT NULL
);

CREATE TABLE film (
    film_id              SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title                VARCHAR(128)      NOT NULL,
    description          TEXT,
    release_year         YEAR,
    language_id          TINYINT UNSIGNED  NOT NULL,
    rental_duration      TINYINT UNSIGNED  NOT NULL DEFAULT 3,
    rental_rate          DECIMAL(4,2)      NOT NULL DEFAULT 4.99,
    length               SMALLINT UNSIGNED,
    replacement_cost     DECIMAL(5,2)      NOT NULL DEFAULT 19.99,
    rating               ENUM('G','PG','PG-13','R','NC-17') DEFAULT 'G',
    FOREIGN KEY (language_id) REFERENCES language(language_id)
);

CREATE TABLE film_actor (
    actor_id  SMALLINT UNSIGNED NOT NULL,
    film_id   SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (actor_id, film_id),
    FOREIGN KEY (actor_id) REFERENCES actor(actor_id),
    FOREIGN KEY (film_id)  REFERENCES film(film_id)
);

CREATE TABLE film_category (
    film_id     SMALLINT UNSIGNED NOT NULL,
    category_id TINYINT UNSIGNED  NOT NULL,
    PRIMARY KEY (film_id, category_id),
    FOREIGN KEY (film_id)     REFERENCES film(film_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

CREATE TABLE country (
    country_id  SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    country     VARCHAR(50)       NOT NULL
);

CREATE TABLE city (
    city_id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    city        VARCHAR(50)       NOT NULL,
    country_id  SMALLINT UNSIGNED NOT NULL,
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

CREATE TABLE address (
    address_id  SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    address     VARCHAR(50)       NOT NULL,
    district    VARCHAR(20)       NOT NULL,
    city_id     SMALLINT UNSIGNED NOT NULL,
    postal_code VARCHAR(10),
    phone       VARCHAR(20)       NOT NULL,
    FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE store (
    store_id    TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    address_id  SMALLINT UNSIGNED NOT NULL,
    FOREIGN KEY (address_id) REFERENCES address(address_id)
);

CREATE TABLE staff (
    staff_id      TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(45)       NOT NULL,
    last_name     VARCHAR(45)       NOT NULL,
    address_id    SMALLINT UNSIGNED NOT NULL,
    email         VARCHAR(50),
    store_id      TINYINT UNSIGNED  NOT NULL,
    active        TINYINT(1)        NOT NULL DEFAULT 1,
    username      VARCHAR(16)       NOT NULL,
    total_rentals INT               NOT NULL DEFAULT 0,
    FOREIGN KEY (address_id) REFERENCES address(address_id),
    FOREIGN KEY (store_id)   REFERENCES store(store_id)
);

CREATE TABLE customer (
    customer_id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    store_id        TINYINT UNSIGNED  NOT NULL,
    first_name      VARCHAR(45)       NOT NULL,
    last_name       VARCHAR(45)       NOT NULL,
    email           VARCHAR(50),
    address_id      SMALLINT UNSIGNED NOT NULL,
    active          TINYINT(1)        NOT NULL DEFAULT 1,
    create_date     DATETIME          NOT NULL DEFAULT NOW(),
    saldo_pendiente DECIMAL(5,2)      NOT NULL DEFAULT 0.00,
    FOREIGN KEY (store_id)   REFERENCES store(store_id),
    FOREIGN KEY (address_id) REFERENCES address(address_id)
);

CREATE TABLE inventory (
    inventory_id  MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    film_id       SMALLINT UNSIGNED  NOT NULL,
    store_id      TINYINT UNSIGNED   NOT NULL,
    FOREIGN KEY (film_id)  REFERENCES film(film_id),
    FOREIGN KEY (store_id) REFERENCES store(store_id)
);

CREATE TABLE rental (
    rental_id     INT                NOT NULL AUTO_INCREMENT PRIMARY KEY,
    rental_date   DATETIME           NOT NULL,
    inventory_id  MEDIUMINT UNSIGNED NOT NULL,
    customer_id   SMALLINT UNSIGNED  NOT NULL,
    return_date   DATETIME,
    staff_id      TINYINT UNSIGNED   NOT NULL,
    FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id),
    FOREIGN KEY (customer_id)  REFERENCES customer(customer_id),
    FOREIGN KEY (staff_id)     REFERENCES staff(staff_id)
);

CREATE TABLE payment (
    payment_id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_id  SMALLINT UNSIGNED NOT NULL,
    staff_id     TINYINT UNSIGNED  NOT NULL,
    rental_id    INT               NOT NULL,
    amount       DECIMAL(5,2)      NOT NULL,
    payment_date DATETIME          NOT NULL DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (staff_id)    REFERENCES staff(staff_id),
    FOREIGN KEY (rental_id)   REFERENCES rental(rental_id)
);

-- Tablas auxiliares para triggers y eventos
CREATE TABLE auditoria_cliente (
    id_auditoria     INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_id      SMALLINT UNSIGNED NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior   VARCHAR(200),
    valor_nuevo      VARCHAR(200),
    fecha_cambio     DATETIME    NOT NULL DEFAULT NOW(),
    usuario          VARCHAR(50) DEFAULT CURRENT_USER()
);

CREATE TABLE historial_costo_film (
    id_historial         INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    film_id              SMALLINT UNSIGNED NOT NULL,
    rental_rate_anterior DECIMAL(4,2),
    rental_rate_nuevo    DECIMAL(4,2),
    fecha_cambio         DATETIME      NOT NULL DEFAULT NOW()
);

CREATE TABLE notificacion_eliminacion (
    id_notificacion INT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    rental_id       INT      NOT NULL,
    customer_id     SMALLINT UNSIGNED NOT NULL,
    fecha_alquiler  DATETIME,
    fecha_registro  DATETIME NOT NULL DEFAULT NOW(),
    mensaje         VARCHAR(255)
);

CREATE TABLE informe_mensual (
    id_informe       INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    anio             YEAR          NOT NULL,
    mes              TINYINT       NOT NULL,
    total_alquileres INT           NOT NULL DEFAULT 0,
    total_ingresos   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    categoria_top    VARCHAR(25),
    fecha_generado   DATETIME      NOT NULL DEFAULT NOW()
);

CREATE TABLE categoria_popular (
    id               INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    category_id      TINYINT UNSIGNED NOT NULL,
    nombre           VARCHAR(25)   NOT NULL,
    total_alquileres INT           NOT NULL DEFAULT 0,
    mes_referencia   DATE          NOT NULL,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);