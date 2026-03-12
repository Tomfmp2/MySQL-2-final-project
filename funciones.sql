USE mini_erp;
DELIMITER $$

-- ==========================================================
-- MÓDULO: INVENTARIO - VALIDACIONES
-- ==========================================================

-- Valida capacidad máxima de bodega antes de recibir compra
DROP TRIGGER IF EXISTS trg_validar_capacidad_bodega$$
CREATE TRIGGER trg_validar_capacidad_bodega
BEFORE INSERT ON detalle_factura_compra
FOR EACH ROW
BEGIN
    DECLARE v_capacidad_max  INT DEFAULT 0;
    DECLARE v_stock_total    INT DEFAULT 0;

    SELECT cantidad_maxima INTO v_capacidad_max
    FROM bodegas WHERE id = NEW.bodega_id;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_stock_total
    FROM inventario WHERE bodega_id = NEW.bodega_id;

    IF (v_stock_total + NEW.cantidad) > v_capacidad_max THEN
        INSERT INTO logs(tabla, operacion, descripcion, nivel, dato_nuevo)
        VALUES('detalle_factura_compra', 'ERROR',
               CONCAT('Bodega sin capacidad. Bodega ID: ', NEW.bodega_id,
                      ' | Capacidad máx: ', v_capacidad_max,
                      ' | Ocupado: ', v_stock_total,
                      ' | Intentado agregar: ', NEW.cantidad),
               'ERROR',
               JSON_OBJECT('bodega_id',   NEW.bodega_id,
                           'producto_id', NEW.producto_id,
                           'cantidad',    NEW.cantidad));

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La bodega no tiene capacidad suficiente para recibir este ingreso.';
    END IF;
END$$

-- ─────────────────────────────────────────────────────────
-- Valida stock antes de registrar línea de venta
DROP TRIGGER IF EXISTS trg_validar_stock_venta$$
CREATE TRIGGER trg_validar_stock_venta
BEFORE INSERT ON detalle_factura_venta
FOR EACH ROW
BEGIN
    DECLARE v_stock INT DEFAULT 0;

    SELECT COALESCE(cantidad, 0) INTO v_stock
    FROM inventario
    WHERE producto_id = NEW.producto_id AND bodega_id = NEW.bodega_id;

    IF v_stock < NEW.cantidad THEN
        INSERT INTO logs(tabla, operacion, descripcion, nivel, dato_nuevo)
        VALUES('detalle_factura_venta', 'ERROR',
               CONCAT('Stock insuficiente. Producto ID: ', NEW.producto_id,
                      ' | Bodega ID: ', NEW.bodega_id,
                      ' | Disponible: ', v_stock,
                      ' | Solicitado: ', NEW.cantidad),
               'ERROR',
               JSON_OBJECT('producto_id', NEW.producto_id,
                           'bodega_id',   NEW.bodega_id,
                           'disponible',  v_stock,
                           'solicitado',  NEW.cantidad));

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente en la bodega para realizar la venta.';
    END IF;
END$$

-- ─────────────────────────────────────────────────────────
-- Valida stock antes de registrar devolución de compra
DROP TRIGGER IF EXISTS trg_validar_stock_devolucion_compra$$
CREATE TRIGGER trg_validar_stock_devolucion_compra
BEFORE INSERT ON detalle_devolucion_compra
FOR EACH ROW
BEGIN
    DECLARE v_producto_id INT;
    DECLARE v_bodega_id   INT;
    DECLARE v_stock       INT DEFAULT 0;

    SELECT producto_id, bodega_id INTO v_producto_id, v_bodega_id
    FROM detalle_factura_compra WHERE id = NEW.detalle_factura_compra_id;

    SELECT COALESCE(cantidad, 0) INTO v_stock
    FROM inventario WHERE producto_id = v_producto_id AND bodega_id = v_bodega_id;

    IF v_stock < NEW.cantidad THEN
        INSERT INTO logs(tabla, operacion, descripcion, nivel)
        VALUES('detalle_devolucion_compra', 'ERROR',
               CONCAT('Stock insuficiente para devolver al proveedor. Producto ID: ', v_producto_id,
                      ' | Stock actual: ', v_stock,
                      ' | Cantidad a devolver: ', NEW.cantidad),
               'ERROR');

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No hay suficiente stock para procesar la devolución al proveedor.';
    END IF;
END$$

-- ─────────────────────────────────────────────────────────
-- Valida que devolución de venta no supere cantidad vendida
DROP TRIGGER IF EXISTS trg_validar_cantidad_devolucion_venta$$
CREATE TRIGGER trg_validar_cantidad_devolucion_venta
BEFORE INSERT ON detalle_devolucion_venta
FOR EACH ROW
BEGIN
    DECLARE v_cantidad_original INT DEFAULT 0;
    DECLARE v_cantidad_devuelta INT DEFAULT 0;

    SELECT cantidad INTO v_cantidad_original
    FROM detalle_factura_venta WHERE id = NEW.detalle_factura_venta_id;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_cantidad_devuelta
    FROM detalle_devolucion_venta
    WHERE detalle_factura_venta_id = NEW.detalle_factura_venta_id;

    IF (v_cantidad_devuelta + NEW.cantidad) > v_cantidad_original THEN
        INSERT INTO logs(tabla, operacion, descripcion, nivel)
        VALUES('detalle_devolucion_venta', 'ERROR',
               CONCAT('Devolución excede cantidad vendida. Detalle ID: ',
                       NEW.detalle_factura_venta_id,
                      ' | Vendido: ', v_cantidad_original,
                      ' | Ya devuelto: ', v_cantidad_devuelta,
                      ' | Intentado: ', NEW.cantidad),
               'ERROR');

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cantidad a devolver supera la cantidad vendida en la factura.';
    END IF;
END$$

-- ─────────────────────────────────────────────────────────
-- Valida que devolución de compra no supere cantidad comprada
DROP TRIGGER IF EXISTS trg_validar_cantidad_devolucion_compra$$
CREATE TRIGGER trg_validar_cantidad_devolucion_compra
BEFORE INSERT ON detalle_devolucion_compra
FOR EACH ROW
BEGIN
    DECLARE v_cantidad_original INT DEFAULT 0;
    DECLARE v_cantidad_devuelta INT DEFAULT 0;

    SELECT cantidad INTO v_cantidad_original
    FROM detalle_factura_compra WHERE id = NEW.detalle_factura_compra_id;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_cantidad_devuelta
    FROM detalle_devolucion_compra
    WHERE detalle_factura_compra_id = NEW.detalle_factura_compra_id;

    IF (v_cantidad_devuelta + NEW.cantidad) > v_cantidad_original THEN
        INSERT INTO logs(tabla, operacion, descripcion, nivel)
        VALUES('detalle_devolucion_compra', 'ERROR',
               CONCAT('Devolución excede cantidad comprada. Detalle ID: ',
                       NEW.detalle_factura_compra_id,
                      ' | Comprado: ', v_cantidad_original,
                      ' | Ya devuelto: ', v_cantidad_devuelta,
                      ' | Intentado: ', NEW.cantidad),
               'ERROR');

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cantidad a devolver supera la cantidad comprada en la factura.';
    END IF;
END$$


-- ==========================================================
-- MÓDULO: PRODUCTOS - AUTOMATIZACIÓN
-- ==========================================================

-- Recalcula valor_venta e IVA al modificar precio o utilidad
DROP TRIGGER IF EXISTS trg_recalcular_precio_producto$$
CREATE TRIGGER trg_recalcular_precio_producto
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    DECLARE v_smlv DECIMAL(15,2) DEFAULT 1423500.00;

    IF NEW.valor_compra <> OLD.valor_compra
    OR NEW.porcentaje_utilidad <> OLD.porcentaje_utilidad THEN

        SET NEW.valor_venta = ROUND(
            NEW.valor_compra * (1 + NEW.porcentaje_utilidad / 100), 2
        );
        SET NEW.iva = IF(NEW.valor_venta > v_smlv, 19.00, 0.00);

        INSERT INTO logs(tabla, operacion, registro_id, descripcion, nivel,
                         dato_anterior, dato_nuevo)
        VALUES('productos', 'UPDATE', NEW.id,
               CONCAT('Precio recalculado automáticamente. Producto: ', NEW.nombre),
               'WARNING',
               JSON_OBJECT('valor_compra', OLD.valor_compra,
                           'valor_venta',  OLD.valor_venta,
                           'iva',          OLD.iva),
               JSON_OBJECT('valor_compra', NEW.valor_compra,
                           'valor_venta',  NEW.valor_venta,
                           'iva',          NEW.iva));
    END IF;
END$$

-- ─────────────────────────────────────────────────────────
-- Bloquea borrado físico de producto con historial de ventas
DROP TRIGGER IF EXISTS trg_proteger_borrado_producto$$
CREATE TRIGGER trg_proteger_borrado_producto
BEFORE DELETE ON productos
FOR EACH ROW
BEGIN
    DECLARE v_tiene_ventas INT DEFAULT 0;

    SELECT COUNT(*) INTO v_tiene_ventas
    FROM detalle_factura_venta WHERE producto_id = OLD.id;

    IF v_tiene_ventas > 0 THEN
        INSERT INTO logs(tabla, operacion, registro_id, descripcion, nivel)
        VALUES('productos', 'ERROR', OLD.id,
               CONCAT('Borrado bloqueado. Producto tiene ', v_tiene_ventas,
                      ' líneas de venta. ID: ', OLD.id),
               'ERROR');

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar un producto con historial de ventas. Use desactivar.';
    END IF;
END$$


-- ==========================================================
-- MÓDULO: VENTAS - AUTOMATIZACIÓN
-- ==========================================================

-- Crea garantías empresa (3m) y proveedor (12m) al registrar línea de venta
DROP TRIGGER IF EXISTS trg_crear_garantias$$
CREATE TRIGGER trg_crear_garantias
AFTER INSERT ON detalle_factura_venta
FOR EACH ROW
BEGIN
    INSERT INTO garantias(detalle_venta_id, tipo, meses, fecha_inicio, fecha_fin)
    VALUES
        (NEW.id, 'empresa',   3,  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3  MONTH)),
        (NEW.id, 'proveedor', 12, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 MONTH));
END$$

-- ─────────────────────────────────────────────────────────
-- Activa descuento 5% automático cuando cliente supera $200M acumulados
DROP TRIGGER IF EXISTS trg_evaluar_descuento_cliente$$
CREATE TRIGGER trg_evaluar_descuento_cliente
AFTER INSERT ON detalle_factura_venta
FOR EACH ROW
BEGIN
    DECLARE v_cliente_id    INT;
    DECLARE v_total_acum    DECIMAL(15,2) DEFAULT 0;
    DECLARE v_ya_tiene_desc INT DEFAULT 0;

    SELECT cliente_id INTO v_cliente_id
    FROM factura_venta WHERE id = NEW.factura_venta_id;

    SELECT COALESCE(SUM(d.cantidad * d.valor_unitario * (1 + d.iva/100)), 0)
    INTO v_total_acum
    FROM factura_venta fv
    JOIN detalle_factura_venta d ON d.factura_venta_id = fv.id
    WHERE fv.cliente_id = v_cliente_id AND fv.estado = '1';

    SELECT COUNT(*) INTO v_ya_tiene_desc
    FROM descuentos_cliente
    WHERE cliente_id = v_cliente_id AND activo = 1;

    IF v_total_acum > 200000000 AND v_ya_tiene_desc = 0 THEN
        INSERT INTO descuentos_cliente(cliente_id, porcentaje, monto_minimo, activo)
        VALUES(v_cliente_id, 5.00, 200000000, 1);

        INSERT INTO logs(tabla, operacion, registro_id, descripcion, nivel)
        VALUES('descuentos_cliente', 'INSERT', v_cliente_id,
               CONCAT('Descuento 5% activado. Cliente ID: ', v_cliente_id,
                      ' | Acumulado: $', FORMAT(v_total_acum, 0)),
               'INFO');
    END IF;
END$$

-- ─────────────────────────────────────────────────────────
-- Acumula comisión del asesor por periodo al cerrar factura de venta
DROP TRIGGER IF EXISTS trg_calcular_comision_asesor$$
CREATE TRIGGER trg_calcular_comision_asesor
AFTER INSERT ON factura_venta
FOR EACH ROW
BEGIN
    DECLARE v_porcentaje DECIMAL(5,2) DEFAULT 2.00;
    DECLARE v_total      DECIMAL(15,2) DEFAULT 0;
    DECLARE v_periodo    DATE;

    IF NEW.asesor_id IS NOT NULL THEN
        SET v_periodo = DATE_FORMAT(NEW.fecha, '%Y-%m-01');

        SELECT COALESCE(
            SUM(dfv.cantidad * dfv.valor_unitario * (1 + dfv.iva/100))
            * (1 - NEW.descuento_porcentaje / 100), 0
        )
        INTO v_total
        FROM detalle_factura_venta dfv
        WHERE dfv.factura_venta_id = NEW.id;

        INSERT INTO comisiones_asesor(asesor_id, periodo, total_ventas, porcentaje, valor)
        VALUES(NEW.asesor_id, v_periodo, v_total, v_porcentaje,
               ROUND(v_total * v_porcentaje / 100, 2))
        ON DUPLICATE KEY UPDATE
            total_ventas = total_ventas + v_total,
            valor        = ROUND((total_ventas + v_total) * v_porcentaje / 100, 2);

        INSERT INTO logs(tabla, operacion, registro_id, descripcion, nivel)
        VALUES('comisiones_asesor', 'INSERT', NEW.asesor_id,
               CONCAT('Comisión acumulada. Asesor ID: ', NEW.asesor_id,
                      ' | Periodo: ', v_periodo,
                      ' | Base: $', FORMAT(v_total, 0),
                      ' | Comisión: $', FORMAT(ROUND(v_total * v_porcentaje/100, 2), 0)),
               'INFO');
    END IF;
END$$


