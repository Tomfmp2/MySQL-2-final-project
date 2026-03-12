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


