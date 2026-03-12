USE mini_erp;
DELIMITER $$

-- ==========================================================
-- MÓDULO: VENTAS - CÁLCULOS DE FACTURA
-- ==========================================================

-- Subtotal de una factura (sin IVA, sin descuento)
DROP FUNCTION IF EXISTS fn_subtotal_factura_venta$$
CREATE FUNCTION fn_subtotal_factura_venta(p_factura_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal DECIMAL(15,2) DEFAULT 0;

    SELECT COALESCE(SUM(cantidad * valor_unitario), 0)
    INTO v_subtotal
    FROM detalle_factura_venta
    WHERE factura_venta_id = p_factura_id;

    RETURN v_subtotal;
END$$

-- ─────────────────────────────────────────────────────────
-- Total IVA de una factura de venta
DROP FUNCTION IF EXISTS fn_iva_factura_venta$$
CREATE FUNCTION fn_iva_factura_venta(p_factura_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_iva DECIMAL(15,2) DEFAULT 0;

    SELECT COALESCE(SUM(cantidad * valor_unitario * (iva / 100)), 0)
    INTO v_iva
    FROM detalle_factura_venta
    WHERE factura_venta_id = p_factura_id;

    RETURN ROUND(v_iva, 2);
END$$

-- ─────────────────────────────────────────────────────────
-- Valor del descuento en pesos de una factura
DROP FUNCTION IF EXISTS fn_valor_descuento_factura$$
CREATE FUNCTION fn_valor_descuento_factura(p_factura_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal_iva   DECIMAL(15,2) DEFAULT 0;
    DECLARE v_descuento_pct  DECIMAL(5,2)  DEFAULT 0;

    SELECT COALESCE(SUM(d.cantidad * d.valor_unitario * (1 + d.iva/100)), 0),
           fv.descuento_porcentaje
    INTO v_subtotal_iva, v_descuento_pct
    FROM factura_venta fv
    JOIN detalle_factura_venta d ON d.factura_venta_id = fv.id
    WHERE fv.id = p_factura_id
    GROUP BY fv.descuento_porcentaje;

    RETURN ROUND(v_subtotal_iva * (v_descuento_pct / 100), 2);
END$$

-- ─────────────────────────────────────────────────────────
-- Total final de una factura de venta (con IVA y descuento aplicado)
DROP FUNCTION IF EXISTS fn_total_factura_venta$$
CREATE FUNCTION fn_total_factura_venta(p_factura_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_iva      DECIMAL(15,2) DEFAULT 0;
    DECLARE v_descuento_pct  DECIMAL(5,2)  DEFAULT 0;

    SELECT COALESCE(SUM(d.cantidad * d.valor_unitario * (1 + d.iva/100)), 0),
           fv.descuento_porcentaje
    INTO v_total_iva, v_descuento_pct
    FROM factura_venta fv
    JOIN detalle_factura_venta d ON d.factura_venta_id = fv.id
    WHERE fv.id = p_factura_id
    GROUP BY fv.descuento_porcentaje;

    RETURN ROUND(v_total_iva * (1 - v_descuento_pct / 100), 2);
END$$

-- ─────────────────────────────────────────────────────────
-- Total final de una factura de compra (con IVA)
DROP FUNCTION IF EXISTS fn_total_factura_compra$$
CREATE FUNCTION fn_total_factura_compra(p_factura_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2) DEFAULT 0;

    SELECT COALESCE(SUM(cantidad * valor_unitario * (1 + iva/100)), 0)
    INTO v_total
    FROM detalle_factura_compra
    WHERE factura_compra_id = p_factura_id;

    RETURN ROUND(v_total, 2);
END$$


