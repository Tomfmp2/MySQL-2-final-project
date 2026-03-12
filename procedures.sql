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


