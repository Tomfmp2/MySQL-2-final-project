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


-- ==========================================================
-- MÓDULO: USUARIOS
-- Necesita: Crear, Actualizar, Desactivar, Leer
-- NO eliminar: auditoría requiere conservar usuarios
-- ==========================================================

CREATE PROCEDURE sp_crear_usuario(
    IN p_rol_principal_id  INT,
    IN p_tipo_doc_id       INT,
    IN p_num_doc           VARCHAR(20),
    IN p_nombres           VARCHAR(100),
    IN p_apellidos         VARCHAR(100),
    IN p_direccion         VARCHAR(200),
    IN p_ciudad_id         INT,
    IN p_telefono          VARCHAR(20),
    IN p_email_personal    VARCHAR(100),
    IN p_email_corporativo VARCHAR(100),
    IN p_password_hash     VARCHAR(255),
    OUT p_nuevo_id         INT
)
BEGIN
    INSERT INTO usuarios(
        rol_principal_id, tipo_documento_id, num_documento,
        nombres, apellidos, direccion, ciudad_id,
        telefono, email_personal, email_corporativo, password_hash
    ) VALUES(
        p_rol_principal_id, p_tipo_doc_id, p_num_doc,
        p_nombres, p_apellidos, p_direccion, p_ciudad_id,
        p_telefono, p_email_personal, p_email_corporativo, p_password_hash
    );

    SET p_nuevo_id = LAST_INSERT_ID();

    -- Asignar rol principal automáticamente en tabla puente
    INSERT INTO usuario_rol(usuario_id, rol_id)
    VALUES(p_nuevo_id, p_rol_principal_id);

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(NULL, 'usuarios', 'INSERT', p_nuevo_id,
           CONCAT('Usuario creado: ', p_email_corporativo), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_actualizar_usuario(
    IN p_id         INT,
    IN p_nombres    VARCHAR(100),
    IN p_apellidos  VARCHAR(100),
    IN p_direccion  VARCHAR(200),
    IN p_ciudad_id  INT,
    IN p_telefono   VARCHAR(20),
    IN p_foto_url   VARCHAR(255),
    IN p_usuario_id INT   -- quien ejecuta la acción
)
BEGIN
    UPDATE usuarios SET
        nombres   = p_nombres,
        apellidos = p_apellidos,
        direccion = p_direccion,
        ciudad_id = p_ciudad_id,
        telefono  = p_telefono,
        foto_url  = p_foto_url
    WHERE id = p_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'usuarios', 'UPDATE', p_id,
           CONCAT('Usuario actualizado ID: ', p_id), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_desactivar_usuario(
    IN p_id         INT,
    IN p_usuario_id INT
)
BEGIN
    UPDATE usuarios SET estado = '0' WHERE id = p_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'usuarios', 'UPDATE', p_id,
           CONCAT('Usuario desactivado ID: ', p_id), 'WARNING');
END$$


-- ==========================================================
-- MÓDULO: FACTURA DE VENTA
-- Necesita: Crear (cabecera + líneas en transacción), Anular
-- NO actualizar líneas: las facturas son documentos contables
-- ==========================================================

CREATE PROCEDURE sp_crear_factura_venta(
    IN  p_cliente_id          INT,
    IN  p_asesor_id           INT,
    IN  p_usuario_id          INT,
    IN  p_tipo_pago_id        INT,
    IN  p_num_factura         VARCHAR(50),
    IN  p_observaciones       TEXT,
    OUT p_factura_id          INT
)
BEGIN
    DECLARE v_descuento      DECIMAL(5,2) DEFAULT 0.00;
    DECLARE v_total_acum     DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_smlv           DECIMAL(15,2) DEFAULT 1423500.00;

    -- Calcular descuento automático si cliente supera 200 millones acumulados
    SELECT COALESCE(SUM(dfv.cantidad * dfv.valor_unitario * (1 + dfv.iva/100)), 0)
    INTO v_total_acum
    FROM factura_venta fv
    JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
    WHERE fv.cliente_id = p_cliente_id AND fv.estado = '1';

    IF v_total_acum > 200000000 THEN
        SET v_descuento = 5.00;
    END IF;

    -- Verificar si tiene descuento específico activo (sobreescribe el automático)
    SELECT COALESCE(MAX(porcentaje), v_descuento)
    INTO v_descuento
    FROM descuentos_cliente
    WHERE cliente_id = p_cliente_id AND activo = 1;

    INSERT INTO factura_venta(
        cliente_id, asesor_id, usuario_id, fecha,
        tipo_pago_id, num_factura, descuento_porcentaje, observaciones
    ) VALUES(
        p_cliente_id, p_asesor_id, p_usuario_id, NOW(),
        p_tipo_pago_id, p_num_factura, v_descuento, p_observaciones
    );

    SET p_factura_id = LAST_INSERT_ID();

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'factura_venta', 'INSERT', p_factura_id,
           CONCAT('Factura venta creada: ', p_num_factura,
                  ' | Descuento aplicado: ', v_descuento, '%'), 'INFO');
END$$

-- ─────────────────────────────────────────────────────────
CREATE PROCEDURE sp_agregar_linea_venta(
    IN p_factura_id    INT,
    IN p_producto_id   INT,
    IN p_bodega_id     INT,
    IN p_cantidad      INT,
    IN p_usuario_id    INT
)
BEGIN
    DECLARE v_stock        INT DEFAULT 0;
    DECLARE v_valor_venta  DECIMAL(15,2);
    DECLARE v_iva          DECIMAL(5,2);

    -- Validar stock disponible
    SELECT COALESCE(cantidad, 0) INTO v_stock
    FROM inventario
    WHERE producto_id = p_producto_id AND bodega_id = p_bodega_id;

    IF v_stock < p_cantidad THEN
        INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel, dato_nuevo)
        VALUES(p_usuario_id, 'detalle_factura_venta', 'ERROR', p_factura_id,
               CONCAT('Stock insuficiente. Producto: ', p_producto_id,
                      ' | Bodega: ', p_bodega_id,
                      ' | Disponible: ', v_stock,
                      ' | Solicitado: ', p_cantidad),
               'ERROR',
               JSON_OBJECT('producto_id', p_producto_id, 'bodega_id', p_bodega_id,
                           'disponible', v_stock, 'solicitado', p_cantidad));

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente en la bodega para esta venta.';
    END IF;

    -- Obtener precio y IVA vigente del producto
    SELECT valor_venta, iva INTO v_valor_venta, v_iva
    FROM productos WHERE id = p_producto_id;

    -- Insertar línea
    INSERT INTO detalle_factura_venta(
        factura_venta_id, producto_id, bodega_id,
        cantidad, valor_unitario, iva
    ) VALUES(
        p_factura_id, p_producto_id, p_bodega_id,
        p_cantidad, v_valor_venta, v_iva
    );

    -- Descontar stock
    UPDATE inventario SET cantidad = cantidad - p_cantidad
    WHERE producto_id = p_producto_id AND bodega_id = p_bodega_id;

    -- Crear garantía empresa automáticamente (3 meses)
    INSERT INTO garantias(detalle_venta_id, tipo, meses, fecha_inicio, fecha_fin)
    VALUES(LAST_INSERT_ID(), 'empresa', 3, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 MONTH));
END$$

-- ─────────────────────────────────────────────────────────
-- Anular solo si no tiene devoluciones asociadas
CREATE PROCEDURE sp_anular_factura_venta(
    IN p_factura_id INT,
    IN p_usuario_id INT
)
BEGIN
    DECLARE v_tiene_dev INT DEFAULT 0;

    SELECT COUNT(*) INTO v_tiene_dev
    FROM devolucion_venta WHERE factura_venta_id = p_factura_id;

    IF v_tiene_dev > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede anular: la factura tiene devoluciones registradas.';
    END IF;

    UPDATE factura_venta SET estado = '0' WHERE id = p_factura_id;

    INSERT INTO logs(usuario_id, tabla, operacion, registro_id, descripcion, nivel)
    VALUES(p_usuario_id, 'factura_venta', 'UPDATE', p_factura_id,
           CONCAT('Factura venta anulada ID: ', p_factura_id), 'WARNING');
END$$


