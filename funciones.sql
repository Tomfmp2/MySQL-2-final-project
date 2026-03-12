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


-- ==========================================================
-- MÓDULO: DESCUENTOS
-- ==========================================================

-- Porcentaje de descuento vigente para un cliente
DROP FUNCTION IF EXISTS fn_descuento_cliente$$
CREATE FUNCTION fn_descuento_cliente(p_cliente_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_descuento     DECIMAL(5,2) DEFAULT 0.00;
    DECLARE v_total_acum    DECIMAL(15,2) DEFAULT 0;

    -- Primero verifica si tiene descuento activo registrado
    SELECT COALESCE(MAX(porcentaje), 0) INTO v_descuento
    FROM descuentos_cliente
    WHERE cliente_id = p_cliente_id AND activo = 1;

    -- Si no tiene, evalúa por acumulado histórico
    IF v_descuento = 0 THEN
        SELECT COALESCE(SUM(d.cantidad * d.valor_unitario * (1 + d.iva/100)), 0)
        INTO v_total_acum
        FROM factura_venta fv
        JOIN detalle_factura_venta d ON d.factura_venta_id = fv.id
        WHERE fv.cliente_id = p_cliente_id AND fv.estado = '1';

        SET v_descuento = CASE
            WHEN v_total_acum >= 500000000 THEN 10.00
            WHEN v_total_acum >= 200000000 THEN  5.00
            ELSE 0.00
        END;
    END IF;

    RETURN v_descuento;
END$$

-- ─────────────────────────────────────────────────────────
-- Aplica el descuento a un monto dado y retorna el valor a pagar
DROP FUNCTION IF EXISTS fn_aplicar_descuento$$
CREATE FUNCTION fn_aplicar_descuento(
    p_monto      DECIMAL(15,2),
    p_cliente_id INT
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_pct DECIMAL(5,2) DEFAULT 0;

    SET v_pct = fn_descuento_cliente(p_cliente_id);

    RETURN ROUND(p_monto * (1 - v_pct / 100), 2);
END$$


-- ==========================================================
-- MÓDULO: INVENTARIO
-- ==========================================================

-- Stock disponible de un producto en una bodega específica
DROP FUNCTION IF EXISTS fn_stock_disponible$$
CREATE FUNCTION fn_stock_disponible(
    p_producto_id INT,
    p_bodega_id   INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock INT DEFAULT 0;

    SELECT COALESCE(cantidad, 0) INTO v_stock
    FROM inventario
    WHERE producto_id = p_producto_id AND bodega_id = p_bodega_id;

    RETURN v_stock;
END$$

-- ─────────────────────────────────────────────────────────
-- Stock total de un producto en todas las bodegas
DROP FUNCTION IF EXISTS fn_stock_total_producto$$
CREATE FUNCTION fn_stock_total_producto(p_producto_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_total
    FROM inventario
    WHERE producto_id = p_producto_id;

    RETURN v_total;
END$$

-- ─────────────────────────────────────────────────────────
-- Valor total del inventario de un producto a precio de costo
DROP FUNCTION IF EXISTS fn_valor_inventario_costo$$
CREATE FUNCTION fn_valor_inventario_costo(p_producto_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_valor_compra DECIMAL(15,2) DEFAULT 0;
    DECLARE v_stock_total  INT DEFAULT 0;

    SELECT valor_compra INTO v_valor_compra
    FROM productos WHERE id = p_producto_id;

    SET v_stock_total = fn_stock_total_producto(p_producto_id);

    RETURN ROUND(v_stock_total * v_valor_compra, 2);
END$$

-- ─────────────────────────────────────────────────────────
-- Capacidad disponible restante en una bodega
DROP FUNCTION IF EXISTS fn_capacidad_disponible_bodega$$
CREATE FUNCTION fn_capacidad_disponible_bodega(p_bodega_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_capacidad_max INT DEFAULT 0;
    DECLARE v_ocupado       INT DEFAULT 0;

    SELECT cantidad_maxima INTO v_capacidad_max
    FROM bodegas WHERE id = p_bodega_id;

    SELECT COALESCE(SUM(cantidad), 0) INTO v_ocupado
    FROM inventario WHERE bodega_id = p_bodega_id;

    RETURN (v_capacidad_max - v_ocupado);
END$$


-- ==========================================================
-- MÓDULO: ASESORES - COMISIONES
-- ==========================================================

-- Comisión acumulada de un asesor en un periodo (YYYY-MM-01)
DROP FUNCTION IF EXISTS fn_comision_asesor$$
CREATE FUNCTION fn_comision_asesor(
    p_asesor_id INT,
    p_periodo   DATE
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_valor DECIMAL(15,2) DEFAULT 0;

    SELECT COALESCE(valor, 0) INTO v_valor
    FROM comisiones_asesor
    WHERE asesor_id = p_asesor_id
      AND periodo   = DATE_FORMAT(p_periodo, '%Y-%m-01');

    RETURN v_valor;
END$$

-- ─────────────────────────────────────────────────────────
-- Total vendido por un asesor en un periodo
DROP FUNCTION IF EXISTS fn_total_ventas_asesor$$
CREATE FUNCTION fn_total_ventas_asesor(
    p_asesor_id INT,
    p_periodo   DATE
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(15,2) DEFAULT 0;

    SELECT COALESCE(total_ventas, 0) INTO v_total
    FROM comisiones_asesor
    WHERE asesor_id = p_asesor_id
      AND periodo   = DATE_FORMAT(p_periodo, '%Y-%m-01');

    RETURN v_total;
END$$


-- ==========================================================
-- MÓDULO: PRODUCTOS - UTILIDAD
-- ==========================================================

-- Utilidad bruta generada por un producto en un periodo
DROP FUNCTION IF EXISTS fn_utilidad_producto$$
CREATE FUNCTION fn_utilidad_producto(
    p_producto_id INT,
    p_fecha_ini   DATE,
    p_fecha_fin   DATE
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_utilidad DECIMAL(15,2) DEFAULT 0;

    SELECT COALESCE(
        SUM(d.cantidad * (p.valor_venta - p.valor_compra)), 0
    )
    INTO v_utilidad
    FROM detalle_factura_venta d
    JOIN factura_venta fv ON fv.id = d.factura_venta_id
    JOIN productos     p  ON p.id  = d.producto_id
    WHERE d.producto_id = p_producto_id
      AND DATE(fv.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
      AND fv.estado = '1';

    RETURN ROUND(v_utilidad, 2);
END$$

-- ─────────────────────────────────────────────────────────
-- Precio neto de venta de un producto (valor_venta + IVA)
DROP FUNCTION IF EXISTS fn_precio_neto_producto$$
CREATE FUNCTION fn_precio_neto_producto(p_producto_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_precio DECIMAL(15,2) DEFAULT 0;

    SELECT ROUND(valor_venta * (1 + iva/100), 2)
    INTO v_precio
    FROM productos WHERE id = p_producto_id;

    RETURN v_precio;
END$$


-- ==========================================================
-- MÓDULO: GARANTÍAS
-- ==========================================================

-- Verifica si una garantía está vigente (1 = vigente, 0 = vencida)
DROP FUNCTION IF EXISTS fn_garantia_vigente$$
CREATE FUNCTION fn_garantia_vigente(p_garantia_id INT)
RETURNS TINYINT(1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_fin DATE;

    SELECT fecha_fin INTO v_fecha_fin
    FROM garantias WHERE id = p_garantia_id;

    RETURN IF(CURDATE() <= v_fecha_fin, 1, 0);
END$$

-- ─────────────────────────────────────────────────────────
-- Días restantes de una garantía (negativo = ya venció)
DROP FUNCTION IF EXISTS fn_dias_garantia_restantes$$
CREATE FUNCTION fn_dias_garantia_restantes(p_garantia_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_fin DATE;

    SELECT fecha_fin INTO v_fecha_fin
    FROM garantias WHERE id = p_garantia_id;

    RETURN DATEDIFF(v_fecha_fin, CURDATE());
END$$

DELIMITER ;
