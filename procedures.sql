USE mini_erp;
DELIMITER $$


-- MÓDULO: PRODUCTOS
-- Necesita: Crear, Actualizar, Desactivar, Listar
-- NO eliminar: productos con historial de ventas no se borran


CREATE PROCEDURE sp_crear_producto(
    IN p_codigo             VARCHAR(30),
    IN p_nombre             VARCHAR(50),
    IN p_descripcion        TEXT,
    IN p_categoria_id       INT,
    IN p_porcentaje_utilidad DECIMAL(5,2),
    IN p_valor_compra       DECIMAL(15,2),
    IN p_imagen_url         VARCHAR(255),
    OUT p_nuevo_id          INT
)
BEGIN
    DECLARE v_valor_venta DECIMAL(15,2);
    DECLARE v_iva         DECIMAL(5,2);
    DECLARE v_smlv        DECIMAL(15,2) DEFAULT 1423500.00;


    SET v_valor_venta = ROUND(p_valor_compra * (1 + p_porcentaje_utilidad / 100), 2);
    SET v_iva = IF(v_valor_venta > v_smlv, 19.00, 0.00);

    INSERT INTO productos(
        codigo, nombre, descripcion, categoria_id,
        porcentaje_utilidad, valor_compra, valor_venta, iva, imagen_url
    ) VALUES (
        p_codigo, p_nombre, p_descripcion, p_categoria_id,
        p_porcentaje_utilidad, p_valor_compra, v_valor_venta, v_iva, p_imagen_url
    );

    SET p_nuevo_id = LAST_INSERT_ID();

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(NULL, 'productos', 'INSERT', p_nuevo_id,
           CONCAT('Producto creado: ', p_codigo, ' - ', p_nombre), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_actualizar_producto(
    IN p_id                 INT,
    IN p_nombre             VARCHAR(50),
    IN p_descripcion        TEXT,
    IN p_categoria_id       INT,
    IN p_porcentaje_utilidad DECIMAL(5,2),
    IN p_valor_compra       DECIMAL(15,2),
    IN p_imagen_url         VARCHAR(255),
    IN p_usuario_id         INT
)
BEGIN
    DECLARE v_valor_venta  DECIMAL(15,2);
    DECLARE v_iva          DECIMAL(5,2);
    DECLARE v_smlv         DECIMAL(15,2) DEFAULT 1423500.00;
    DECLARE v_anterior     JSON;

    -- Guardar estado anterior para log
    SELECT JSON_OBJECT(
        'nombre', nombre, 'valor_compra', valor_compra,
        'valor_venta', valor_venta, 'iva', iva
    ) INTO v_anterior
    FROM productos WHERE id = p_id;

    SET v_valor_venta = ROUND(p_valor_compra * (1 + p_porcentaje_utilidad / 100), 2);
    SET v_iva = IF(v_valor_venta > v_smlv, 19.00, 0.00);

    UPDATE productos SET
        nombre              = p_nombre,
        descripcion         = p_descripcion,
        categoria_id        = p_categoria_id,
        porcentaje_utilidad = p_porcentaje_utilidad,
        valor_compra        = p_valor_compra,
        valor_venta         = v_valor_venta,
        iva                 = v_iva,
        imagen_url          = p_imagen_url
    WHERE id = p_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel, dato_anterior)
    VALUES(p_usuario_id, 'productos', 'UPDATE', p_id,
           CONCAT('Producto actualizado ID: ', p_id), 'INFO', v_anterior);
END$$

-- ─────────────────────────────────────────────────────────
-- NO se elimina físicamente, solo se desactiva
CREATE PROCEDURE sp_desactivar_producto(
    IN p_id         INT,
    IN p_usuario_id INT
)
BEGIN
    UPDATE productos SET estado = '0' WHERE id = p_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'productos', 'UPDATE', p_id,
           CONCAT('Producto desactivado ID: ', p_id), 'WARNING');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_listar_productos(
    IN p_estado       CHAR(1),   -- '1' activos, '0' inactivos, NULL todos
    IN p_categoria_id INT        -- NULL = todas las categorías
)
BEGIN
    SELECT
        p.id, p.codigo, p.nombre,
        c.tipo              AS categoria,
        p.porcentaje_utilidad,
        p.valor_compra,
        p.valor_venta,
        p.iva,
        ROUND(p.valor_venta * (1 + p.iva/100), 2) AS valor_neto_venta,
        p.estado
    FROM productos p
    JOIN categoria c ON c.id = p.categoria_id
    WHERE (p.estado      = p_estado      OR p_estado IS NULL)
      AND (p.categoria_id = p_categoria_id OR p_categoria_id IS NULL)
    ORDER BY p.nombre;
END$$


-- ==========================================================
-- MÓDULO: CLIENTES
-- Necesita: Crear persona, Crear empresa, Actualizar, Desactivar, Leer
-- NO eliminar: clientes con historial de ventas no se borran
-- ==========================================================

CREATE PROCEDURE sp_crear_cliente_persona(
    IN p_tipo_doc_id  INT,
    IN p_num_doc      VARCHAR(20),
    IN p_nombre_email VARCHAR(100),
    IN p_tipo_email_id INT,
    IN p_direccion    VARCHAR(200),
    IN p_ciudad_id    INT,
    IN p_genero       ENUM('M','F','Otro'),
    IN p_nombre       VARCHAR(50),
    IN p_apellido     VARCHAR(50),
    IN p_telefono     VARCHAR(20),
    OUT p_nuevo_id    INT
)
BEGIN
    INSERT INTO clientes(
        tipo_documento_id, num_documento, nombre_email,
        tipo_email_id, direccion, ciudad_id, genero
    ) VALUES(
        p_tipo_doc_id, p_num_doc, p_nombre_email,
        p_tipo_email_id, p_direccion, p_ciudad_id, p_genero
    );

    SET p_nuevo_id = LAST_INSERT_ID();

    INSERT INTO personas(cliente_id, nombre, apellido)
    VALUES(p_nuevo_id, p_nombre, p_apellido);

    INSERT INTO num_telefonico(telefono, cliente_id)
    VALUES(p_telefono, p_nuevo_id);

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(NULL, 'clientes', 'INSERT', p_nuevo_id,
           CONCAT('Cliente persona creado: ', p_nombre, ' ', p_apellido), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_crear_cliente_empresa(
    IN p_tipo_doc_id   INT,
    IN p_num_doc       VARCHAR(20),
    IN p_nombre_email  VARCHAR(100),
    IN p_tipo_email_id INT,
    IN p_direccion     VARCHAR(200),
    IN p_ciudad_id     INT,
    IN p_nombre_emp    VARCHAR(100),
    IN p_representante VARCHAR(50),
    IN p_telefono      VARCHAR(20),
    OUT p_nuevo_id     INT
)
BEGIN
    INSERT INTO clientes(
        tipo_documento_id, num_documento, nombre_email,
        tipo_email_id, direccion, ciudad_id
    ) VALUES(
        p_tipo_doc_id, p_num_doc, p_nombre_email,
        p_tipo_email_id, p_direccion, p_ciudad_id
    );

    SET p_nuevo_id = LAST_INSERT_ID();

    INSERT INTO empresas(cliente_id, nombre, representante)
    VALUES(p_nuevo_id, p_nombre_emp, p_representante);

    INSERT INTO num_telefonico(telefono, cliente_id)
    VALUES(p_telefono, p_nuevo_id);

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(NULL, 'clientes', 'INSERT', p_nuevo_id,
           CONCAT('Cliente empresa creado: ', p_nombre_emp), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_actualizar_cliente(
    IN p_id           INT,
    IN p_nombre_email VARCHAR(100),
    IN p_tipo_email_id INT,
    IN p_direccion    VARCHAR(200),
    IN p_ciudad_id    INT,
    IN p_genero       ENUM('M','F','Otro'),
    IN p_usuario_id   INT
)
BEGIN
    UPDATE clientes SET
        nombre_email   = p_nombre_email,
        tipo_email_id  = p_tipo_email_id,
        direccion      = p_direccion,
        ciudad_id      = p_ciudad_id,
        genero         = p_genero
    WHERE id = p_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'clientes', 'UPDATE', p_id,
           CONCAT('Cliente actualizado ID: ', p_id), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_desactivar_cliente(
    IN p_id         INT,
    IN p_usuario_id INT
)
BEGIN
    UPDATE clientes SET estado = '0' WHERE id = p_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'clientes', 'UPDATE', p_id,
           CONCAT('Cliente desactivado ID: ', p_id), 'WARNING');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_leer_cliente(IN p_id INT)
BEGIN
    SELECT
        cl.id,
        td.tipo                                              AS tipo_documento,
        cl.num_documento,
        COALESCE(CONCAT(pe.nombre,' ',pe.apellido), em.nombre) AS nombre_completo,
        CASE WHEN pe.cliente_id IS NOT NULL THEN 'Persona' ELSE 'Empresa' END AS tipo_cliente,
        em.representante,
        cl.genero,
        cl.direccion,
        ci.nombre                                            AS ciudad,
        CONCAT(cl.nombre_email,'@',te.tipo)                  AS email,
        GROUP_CONCAT(nt.telefono SEPARATOR ', ')             AS telefonos,
        cl.estado
    FROM clientes cl
    JOIN tipo_documento td ON td.id = cl.tipo_documento_id
    JOIN tipo_email     te ON te.id = cl.tipo_email_id
    JOIN ciudades       ci ON ci.id = cl.ciudad_id
    LEFT JOIN personas  pe ON pe.cliente_id = cl.id
    LEFT JOIN empresas  em ON em.cliente_id = cl.id
    LEFT JOIN num_telefonico nt ON nt.cliente_id = cl.id
    WHERE cl.id = p_id
    GROUP BY cl.id;
END$$


