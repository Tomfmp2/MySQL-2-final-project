USE mini_erp;
DELIMITER $$

-- ==========================================================
-- REPORTE 1: VENTAS POR PERIODO
-- Filtra por rango de fechas, ciudad y asesor (todos opcionales)
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_ventas_periodo$$
CREATE PROCEDURE sp_reporte_ventas_periodo(
    IN p_fecha_ini  DATE,
    IN p_fecha_fin  DATE,
    IN p_ciudad_id  INT,   -- NULL = todas
    IN p_asesor_id  INT    -- NULL = todos
)
BEGIN
    SELECT
        fv.num_factura,
        fv.fecha,
        COALESCE(CONCAT(pe.nombre,' ',pe.apellido), em.nombre) AS cliente,
        CASE WHEN pe.cliente_id IS NOT NULL THEN 'Persona'
             ELSE 'Empresa' END                                AS tipo_cliente,
        ci.nombre                                              AS ciudad_cliente,
        ac.razon_social                                        AS asesor,
        tp.nombre                                              AS tipo_pago,
        fv.descuento_porcentaje,
        fn_subtotal_factura_venta(fv.id)                       AS subtotal,
        fn_iva_factura_venta(fv.id)                            AS iva,
        fn_valor_descuento_factura(fv.id)                      AS descuento_pesos,
        fn_total_factura_venta(fv.id)                          AS total_final
    FROM factura_venta fv
    JOIN clientes    cl  ON cl.id  = fv.cliente_id
    JOIN ciudades    ci  ON ci.id  = cl.ciudad_id
    JOIN tipo_pago   tp  ON tp.id  = fv.tipo_pago_id
    LEFT JOIN personas pe  ON pe.cliente_id = cl.id
    LEFT JOIN empresas em  ON em.cliente_id = cl.id
    LEFT JOIN asesores_comerciales ac ON ac.id = fv.asesor_id
    WHERE fv.estado = '1'
      AND DATE(fv.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
      AND (cl.ciudad_id = p_ciudad_id OR p_ciudad_id IS NULL)
      AND (fv.asesor_id = p_asesor_id OR p_asesor_id IS NULL)
    ORDER BY fv.fecha DESC;
END$$


-- ==========================================================
-- REPORTE 2: INVENTARIO POR BODEGA
-- Estado actual del inventario con alertas de stock
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_inventario_bodega$$
CREATE PROCEDURE sp_reporte_inventario_bodega(
    IN p_bodega_id    INT,   -- NULL = todas
    IN p_categoria_id INT    -- NULL = todas
)
BEGIN
    SELECT
        b.nombre                                AS bodega,
        ci.nombre                               AS ciudad,
        b.cantidad_maxima,
        fn_capacidad_disponible_bodega(b.id)    AS capacidad_disponible,
        ROUND(
            (SUM(i.cantidad) / b.cantidad_maxima) * 100, 2
        )                                       AS porcentaje_ocupacion,
        p.codigo,
        p.nombre                                AS producto,
        cat.tipo                                AS categoria,
        i.cantidad                              AS stock_actual,
        fn_precio_neto_producto(p.id)           AS precio_neto,
        fn_valor_inventario_costo(p.id)         AS valor_costo_total,
        CASE
            WHEN i.cantidad = 0   THEN 'SIN STOCK'
            WHEN i.cantidad < 5   THEN 'STOCK CRÍTICO'
            WHEN i.cantidad < 10  THEN 'STOCK BAJO'
            ELSE                       'NORMAL'
        END                                     AS alerta_stock
    FROM inventario i
    JOIN productos p   ON p.id   = i.producto_id
    JOIN categoria cat ON cat.id = p.categoria_id
    JOIN bodegas   b   ON b.id   = i.bodega_id
    JOIN ciudades  ci  ON ci.id  = b.ciudad_id
    WHERE (i.bodega_id   = p_bodega_id    OR p_bodega_id    IS NULL)
      AND (p.categoria_id = p_categoria_id OR p_categoria_id IS NULL)
      AND p.estado = '1'
    GROUP BY b.id, b.nombre, ci.nombre, b.cantidad_maxima,
             p.id, p.codigo, p.nombre, cat.tipo, i.cantidad
    ORDER BY alerta_stock ASC, i.cantidad ASC;
END$$


-- ==========================================================
-- REPORTE 3: COMISIONES POR PERIODO
-- Comisiones de todos los asesores en un mes
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_comisiones_mes$$
CREATE PROCEDURE sp_reporte_comisiones_mes(
    IN p_periodo DATE   -- Cualquier día del mes, ej: '2026-03-01'
)
BEGIN
    DECLARE v_periodo DATE;
    SET v_periodo = DATE_FORMAT(p_periodo, '%Y-%m-01');

    SELECT
        ac.id                                           AS asesor_id,
        ac.razon_social                                 AS asesor,
        ac.email,
        ci.nombre                                       AS ciudad,
        COUNT(DISTINCT fv.id)                           AS facturas_emitidas,
        SUM(dfv.cantidad)                               AS unidades_vendidas,
        fn_total_ventas_asesor(ac.id, v_periodo)        AS total_ventas_mes,
        ca.porcentaje                                   AS porcentaje_comision,
        fn_comision_asesor(ac.id, v_periodo)            AS valor_comision,
        ac.estado
    FROM asesores_comerciales ac
    JOIN ciudades ci ON ci.id = ac.ciudad_id
    LEFT JOIN factura_venta fv
           ON fv.asesor_id = ac.id
          AND DATE_FORMAT(fv.fecha, '%Y-%m-01') = v_periodo
          AND fv.estado = '1'
    LEFT JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
    LEFT JOIN comisiones_asesor ca
           ON ca.asesor_id = ac.id
          AND ca.periodo   = v_periodo
    WHERE ac.estado = '1'
    GROUP BY ac.id, ac.razon_social, ac.email, ci.nombre,
             ca.porcentaje, ac.estado
    ORDER BY fn_comision_asesor(ac.id, v_periodo) DESC;
END$$


-- ==========================================================
-- REPORTE 4: ROTACIÓN DE PRODUCTOS
-- Productos más y menos vendidos en un periodo
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_rotacion_productos$$
CREATE PROCEDURE sp_reporte_rotacion_productos(
    IN p_periodo    DATE,   -- Cualquier día del mes
    IN p_limite     INT     -- Top N productos, NULL = todos
)
BEGIN
    DECLARE v_periodo DATE;
    SET v_periodo = DATE_FORMAT(p_periodo, '%Y-%m-01');
    SET p_limite  = COALESCE(p_limite, 999999);

    SELECT
        p.codigo,
        p.nombre                                    AS producto,
        cat.tipo                                    AS categoria,
        rr.unidades_vendidas,
        rr.unidades_compradas,
        rr.stock_final,
        rr.rotacion,
        fn_precio_neto_producto(p.id)               AS precio_neto,
        fn_utilidad_producto(
            p.id,
            v_periodo,
            LAST_DAY(v_periodo)
        )                                           AS utilidad_mes,
        CASE
            WHEN rr.rotacion >= 0.7 THEN 'ALTA ROTACIÓN'
            WHEN rr.rotacion >= 0.3 THEN 'ROTACIÓN MEDIA'
            WHEN rr.rotacion >  0   THEN 'BAJA ROTACIÓN'
            ELSE                         'SIN MOVIMIENTO'
        END                                         AS clasificacion
    FROM reporte_rotacion_producto rr
    JOIN productos p   ON p.id   = rr.producto_id
    JOIN categoria cat ON cat.id = p.categoria_id
    WHERE rr.periodo = v_periodo
    ORDER BY rr.unidades_vendidas DESC
    LIMIT p_limite;
END$$


-- ==========================================================
-- REPORTE 5: COMPRAS POR PERIODO Y PROVEEDOR
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_compras_periodo$$
CREATE PROCEDURE sp_reporte_compras_periodo(
    IN p_fecha_ini   DATE,
    IN p_fecha_fin   DATE,
    IN p_proveedor_id INT   -- NULL = todos
)
BEGIN
    SELECT
        fc.num_factura,
        fc.fecha,
        pv.razon_social                         AS proveedor,
        pv.email                                AS email_proveedor,
        CONCAT(u.nombres,' ',u.apellidos)        AS usuario,
        tp.nombre                               AS tipo_pago,
        COUNT(dfc.id)                           AS lineas,
        SUM(dfc.cantidad)                       AS unidades_compradas,
        fn_total_factura_compra(fc.id)          AS total_factura,
        fc.estado
    FROM factura_compra fc
    JOIN proveedores pv ON pv.id  = fc.proveedor_id
    JOIN usuarios    u  ON u.id   = fc.usuario_id
    JOIN tipo_pago   tp ON tp.id  = fc.tipo_pago_id
    JOIN detalle_factura_compra dfc ON dfc.factura_compra_id = fc.id
    WHERE DATE(fc.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
      AND (fc.proveedor_id = p_proveedor_id OR p_proveedor_id IS NULL)
    GROUP BY fc.id, fc.num_factura, fc.fecha, pv.razon_social,
             pv.email, u.nombres, u.apellidos, tp.nombre, fc.estado
    ORDER BY fc.fecha DESC;
END$$


-- ==========================================================
-- REPORTE 6: DEVOLUCIONES POR PERIODO
-- Venta y compra juntas para análisis de calidad
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_devoluciones_periodo$$
CREATE PROCEDURE sp_reporte_devoluciones_periodo(
    IN p_fecha_ini DATE,
    IN p_fecha_fin DATE,
    IN p_tipo      ENUM('VENTA','COMPRA','TODAS')
)
BEGIN
    IF p_tipo = 'VENTA' OR p_tipo = 'TODAS' THEN
        SELECT
            'VENTA'                                             AS tipo_devolucion,
            dv.fecha,
            fv.num_factura,
            COALESCE(CONCAT(pe.nombre,' ',pe.apellido),em.nombre) AS cliente,
            p.nombre                                            AS producto,
            ddv.cantidad                                        AS cantidad_devuelta,
            ROUND(ddv.cantidad * dfv.valor_unitario
                  * (1 + dfv.iva/100), 2)                       AS valor_devuelto,
            dv.observaciones
        FROM devolucion_venta dv
        JOIN factura_venta           fv  ON fv.id  = dv.factura_venta_id
        JOIN detalle_devolucion_venta ddv ON ddv.devolucion_venta_id  = dv.id
        JOIN detalle_factura_venta   dfv ON dfv.id = ddv.detalle_factura_venta_id
        JOIN productos               p   ON p.id   = dfv.producto_id
        JOIN clientes                cl  ON cl.id  = fv.cliente_id
        LEFT JOIN personas pe ON pe.cliente_id = cl.id
        LEFT JOIN empresas em ON em.cliente_id = cl.id
        WHERE DATE(dv.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
        ORDER BY dv.fecha DESC;
    END IF;

    IF p_tipo = 'COMPRA' OR p_tipo = 'TODAS' THEN
        SELECT
            'COMPRA'                                            AS tipo_devolucion,
            dc.fecha,
            fc.num_factura,
            pv.razon_social                                     AS proveedor,
            p.nombre                                            AS producto,
            ddc.cantidad                                        AS cantidad_devuelta,
            ROUND(ddc.cantidad * dfc.valor_unitario
                  * (1 + dfc.iva/100), 2)                       AS valor_devuelto,
            dc.observaciones
        FROM devolucion_compra dc
        JOIN factura_compra            fc  ON fc.id  = dc.factura_compra_id
        JOIN detalle_devolucion_compra ddc ON ddc.devolucion_compra_id  = dc.id
        JOIN detalle_factura_compra    dfc ON dfc.id = ddc.detalle_factura_compra_id
        JOIN productos                 p   ON p.id   = dfc.producto_id
        JOIN proveedores               pv  ON pv.id  = fc.proveedor_id
        WHERE DATE(dc.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
        ORDER BY dc.fecha DESC;
    END IF;
END$$


-- ==========================================================
-- REPORTE 7: RENTABILIDAD POR CATEGORIA
-- Margen de ganancia real por categoría en un periodo
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_rentabilidad_categoria$$
CREATE PROCEDURE sp_reporte_rentabilidad_categoria(
    IN p_fecha_ini DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT
        cat.tipo                                            AS categoria,
        COUNT(DISTINCT p.id)                                AS productos_vendidos,
        SUM(dfv.cantidad)                                   AS unidades_vendidas,
        ROUND(SUM(dfv.cantidad * p.valor_compra), 2)        AS costo_total,
        ROUND(SUM(dfv.cantidad * dfv.valor_unitario), 2)    AS ingreso_bruto,
        ROUND(
            SUM(dfv.cantidad * dfv.valor_unitario)
            - SUM(dfv.cantidad * p.valor_compra), 2
        )                                                   AS utilidad_bruta,
        ROUND(
            ((SUM(dfv.cantidad * dfv.valor_unitario)
            - SUM(dfv.cantidad * p.valor_compra))
            / NULLIF(SUM(dfv.cantidad * p.valor_compra), 0)) * 100, 2
        )                                                   AS margen_porcentaje
    FROM detalle_factura_venta dfv
    JOIN factura_venta fv  ON fv.id  = dfv.factura_venta_id
    JOIN productos    p   ON p.id   = dfv.producto_id
    JOIN categoria    cat ON cat.id = p.categoria_id
    WHERE fv.estado = '1'
      AND DATE(fv.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
    GROUP BY cat.id, cat.tipo
    ORDER BY utilidad_bruta DESC;
END$$


-- ==========================================================
-- REPORTE 8: CLIENTES MÁS VALIOSOS (TOP)
-- ==========================================================

DROP PROCEDURE IF EXISTS sp_reporte_top_clientes$$
CREATE PROCEDURE sp_reporte_top_clientes(
    IN p_fecha_ini DATE,
    IN p_fecha_fin DATE,
    IN p_limite    INT    -- Top N, NULL = top 10
)
BEGIN
    SET p_limite = COALESCE(p_limite, 10);

    SELECT
        cl.num_documento,
        COALESCE(CONCAT(pe.nombre,' ',pe.apellido), em.nombre) AS cliente,
        CASE WHEN pe.cliente_id IS NOT NULL THEN 'Persona'
             ELSE 'Empresa' END                                AS tipo,
        ci.nombre                                              AS ciudad,
        COUNT(DISTINCT fv.id)                                  AS total_facturas,
        SUM(dfv.cantidad)                                      AS unidades_compradas,
        ROUND(
            SUM(dfv.cantidad * dfv.valor_unitario * (1+dfv.iva/100))
            * (1 - fv.descuento_porcentaje/100), 2
        )                                                      AS total_pagado,
        fn_descuento_cliente(cl.id)                            AS descuento_vigente_pct,
        MAX(fv.fecha)                                          AS ultima_compra
    FROM clientes cl
    JOIN factura_venta fv ON fv.cliente_id = cl.id AND fv.estado = '1'
    JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
    JOIN ciudades ci ON ci.id = cl.ciudad_id
    LEFT JOIN personas pe ON pe.cliente_id = cl.id
    LEFT JOIN empresas em ON em.cliente_id = cl.id
    WHERE DATE(fv.fecha) BETWEEN p_fecha_ini AND p_fecha_fin
    GROUP BY cl.id, cl.num_documento, ci.nombre,
             pe.nombre, pe.apellido, em.nombre, pe.cliente_id
    ORDER BY total_pagado DESC
    LIMIT p_limite;
END$$

DELIMITER ;
