USE mini_erp;

-- ==========================================================
-- MÓDULO: INVENTARIO
-- ==========================================================

-- Stock actual por producto y bodega
CREATE OR REPLACE VIEW v_stock_actual AS
SELECT
    p.id                                        AS producto_id,
    p.codigo,
    p.nombre                                    AS producto,
    c.tipo                                      AS categoria,
    b.id                                        AS bodega_id,
    b.nombre                                    AS bodega,
    ci.nombre                                   AS ciudad_bodega,
    i.cantidad                                  AS stock,
    ROUND(p.valor_venta * (1 + p.iva/100), 2)  AS precio_neto,
    ROUND(i.cantidad * p.valor_compra, 2)       AS valor_inventario_costo,
    ROUND(i.cantidad * p.valor_venta, 2)        AS valor_inventario_venta,
    p.estado                                    AS producto_estado
FROM inventario i
JOIN productos  p  ON p.id  = i.producto_id
JOIN categoria  c  ON c.id  = p.categoria_id
JOIN bodegas    b  ON b.id  = i.bodega_id
JOIN ciudades   ci ON ci.id = b.ciudad_id;

-- ─────────────────────────────────────────────────────────
-- Productos con stock bajo (menos de 5 unidades en cualquier bodega)
CREATE OR REPLACE VIEW v_stock_bajo AS
SELECT
    producto_id,
    codigo,
    producto,
    categoria,
    bodega_id,
    bodega,
    ciudad_bodega,
    stock,
    precio_neto
FROM v_stock_actual
WHERE stock < 5
ORDER BY stock ASC;

-- ─────────────────────────────────────────────────────────
-- Resumen de stock total por producto (suma todas las bodegas)
CREATE OR REPLACE VIEW v_stock_total_producto AS
SELECT
    p.id                                              AS producto_id,
    p.codigo,
    p.nombre                                          AS producto,
    c.tipo                                            AS categoria,
    SUM(i.cantidad)                                   AS stock_total,
    p.valor_compra,
    ROUND(p.valor_venta * (1 + p.iva/100), 2)        AS precio_neto,
    ROUND(SUM(i.cantidad) * p.valor_compra, 2)        AS valor_total_costo,
    p.estado
FROM inventario i
JOIN productos p ON p.id = i.producto_id
JOIN categoria c ON c.id = p.categoria_id
GROUP BY p.id, p.codigo, p.nombre, c.tipo,
         p.valor_compra, p.valor_venta, p.iva, p.estado;


-- ==========================================================
-- MÓDULO: VENTAS
-- ==========================================================

-- Detalle completo de facturas de venta
CREATE OR REPLACE VIEW v_facturas_venta AS
SELECT
    fv.id                                                       AS factura_id,
    fv.num_factura,
    fv.fecha,
    COALESCE(CONCAT(pe.nombre,' ',pe.apellido), em.nombre)      AS cliente,
    CASE WHEN pe.cliente_id IS NOT NULL THEN 'Persona'
         ELSE 'Empresa' END                                     AS tipo_cliente,
    CONCAT(cl.nombre_email,'@',te.tipo)                         AS email_cliente,
    ac.razon_social                                             AS asesor,
    CONCAT(u.nombres,' ',u.apellidos)                           AS usuario_cajero,
    tp.nombre                                                   AS tipo_pago,
    fv.descuento_porcentaje,
    SUM(dfv.cantidad * dfv.valor_unitario)                      AS subtotal,
    SUM(dfv.cantidad * dfv.valor_unitario * (dfv.iva/100))      AS total_iva,
    ROUND(
        SUM(dfv.cantidad * dfv.valor_unitario * (1 + dfv.iva/100))
        * (1 - fv.descuento_porcentaje/100)
    , 2)                                                        AS total_final,
    fv.estado,
    fv.observaciones
FROM factura_venta fv
JOIN clientes    cl  ON cl.id  = fv.cliente_id
JOIN tipo_email  te  ON te.id  = cl.tipo_email_id
JOIN tipo_pago   tp  ON tp.id  = fv.tipo_pago_id
JOIN usuarios    u   ON u.id   = fv.usuario_id
JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
LEFT JOIN personas  pe  ON pe.cliente_id  = cl.id
LEFT JOIN empresas  em  ON em.cliente_id  = cl.id
LEFT JOIN asesores_comerciales ac ON ac.id = fv.asesor_id
GROUP BY fv.id, fv.num_factura, fv.fecha, cl.nombre_email, te.tipo,
         pe.nombre, pe.apellido, em.nombre, pe.cliente_id,
         ac.razon_social, u.nombres, u.apellidos,
         tp.nombre, fv.descuento_porcentaje, fv.estado, fv.observaciones;

-- ─────────────────────────────────────────────────────────
-- Líneas de detalle de cada factura de venta
CREATE OR REPLACE VIEW v_detalle_facturas_venta AS
SELECT
    fv.num_factura,
    fv.fecha,
    p.codigo                                                    AS cod_producto,
    p.nombre                                                    AS producto,
    b.nombre                                                    AS bodega,
    dfv.cantidad,
    dfv.valor_unitario,
    dfv.iva,
    ROUND(dfv.cantidad * dfv.valor_unitario, 2)                 AS subtotal_linea,
    ROUND(dfv.cantidad * dfv.valor_unitario * (dfv.iva/100), 2) AS iva_linea,
    ROUND(dfv.cantidad * dfv.valor_unitario * (1+dfv.iva/100), 2) AS total_linea,
    fv.descuento_porcentaje
FROM detalle_factura_venta dfv
JOIN factura_venta fv ON fv.id = dfv.factura_venta_id
JOIN productos     p  ON p.id  = dfv.producto_id
JOIN bodegas       b  ON b.id  = dfv.bodega_id;

-- ─────────────────────────────────────────────────────────
-- Ventas por asesor en el mes actual
CREATE OR REPLACE VIEW v_ventas_por_asesor AS
SELECT
    ac.id                                                       AS asesor_id,
    ac.razon_social                                             AS asesor,
    COUNT(DISTINCT fv.id)                                       AS num_facturas,
    SUM(dfv.cantidad)                                           AS unidades_vendidas,
    ROUND(
        SUM(dfv.cantidad * dfv.valor_unitario * (1+dfv.iva/100))
        * (1 - fv.descuento_porcentaje/100)
    , 2)                                                        AS total_ventas,
    YEAR(fv.fecha)                                              AS anio,
    MONTH(fv.fecha)                                             AS mes
FROM factura_venta fv
JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
JOIN asesores_comerciales  ac  ON ac.id = fv.asesor_id
WHERE fv.estado = '1'
GROUP BY ac.id, ac.razon_social, YEAR(fv.fecha), MONTH(fv.fecha);

-- ─────────────────────────────────────────────────────────
-- Devoluciones de venta con detalle
CREATE OR REPLACE VIEW v_devoluciones_venta AS
SELECT
    dv.id                                                       AS devolucion_id,
    dv.fecha,
    fv.num_factura,
    COALESCE(CONCAT(pe.nombre,' ',pe.apellido), em.nombre)      AS cliente,
    CONCAT(u.nombres,' ',u.apellidos)                           AS usuario,
    p.nombre                                                    AS producto,
    ddv.cantidad                                                AS cantidad_devuelta,
    dfv.valor_unitario,
    ROUND(ddv.cantidad * dfv.valor_unitario * (1+dfv.iva/100), 2) AS valor_devuelto,
    dv.observaciones
FROM devolucion_venta dv
JOIN factura_venta           fv  ON fv.id  = dv.factura_venta_id
JOIN usuarios                u   ON u.id   = dv.usuario_id
JOIN detalle_devolucion_venta ddv ON ddv.devolucion_venta_id = dv.id
JOIN detalle_factura_venta   dfv ON dfv.id = ddv.detalle_factura_venta_id
JOIN productos               p   ON p.id   = dfv.producto_id
JOIN clientes                cl  ON cl.id  = fv.cliente_id
LEFT JOIN personas  pe ON pe.cliente_id = cl.id
LEFT JOIN empresas  em ON em.cliente_id = cl.id;


-- ==========================================================
-- MÓDULO: COMPRAS
-- ==========================================================

-- Detalle completo de facturas de compra
CREATE OR REPLACE VIEW v_facturas_compra AS
SELECT
    fc.id                                                       AS factura_id,
    fc.num_factura,
    fc.fecha,
    pv.razon_social                                             AS proveedor,
    CONCAT(u.nombres,' ',u.apellidos)                           AS usuario,
    tp.nombre                                                   AS tipo_pago,
    SUM(dfc.cantidad * dfc.valor_unitario)                      AS subtotal,
    SUM(dfc.cantidad * dfc.valor_unitario * (dfc.iva/100))      AS total_iva,
    ROUND(SUM(dfc.cantidad * dfc.valor_unitario * (1+dfc.iva/100)), 2) AS total_final,
    fc.estado,
    fc.observaciones
FROM factura_compra fc
JOIN proveedores pv ON pv.id = fc.proveedor_id
JOIN usuarios    u  ON u.id  = fc.usuario_id
JOIN tipo_pago   tp ON tp.id = fc.tipo_pago_id
JOIN detalle_factura_compra dfc ON dfc.factura_compra_id = fc.id
GROUP BY fc.id, fc.num_factura, fc.fecha, pv.razon_social,
         u.nombres, u.apellidos, tp.nombre, fc.estado, fc.observaciones;

-- ─────────────────────────────────────────────────────────
-- Devoluciones de compra con detalle
CREATE OR REPLACE VIEW v_devoluciones_compra AS
SELECT
    dc.id                                                       AS devolucion_id,
    dc.fecha,
    fc.num_factura,
    pv.razon_social                                             AS proveedor,
    CONCAT(u.nombres,' ',u.apellidos)                           AS usuario,
    p.nombre                                                    AS producto,
    ddc.cantidad                                                AS cantidad_devuelta,
    dfc.valor_unitario,
    ROUND(ddc.cantidad * dfc.valor_unitario * (1+dfc.iva/100), 2) AS valor_devuelto,
    dc.observaciones
FROM devolucion_compra dc
JOIN factura_compra           fc  ON fc.id  = dc.factura_compra_id
JOIN usuarios                 u   ON u.id   = dc.usuario_id
JOIN proveedores              pv  ON pv.id  = fc.proveedor_id
JOIN detalle_devolucion_compra ddc ON ddc.devolucion_compra_id = dc.id
JOIN detalle_factura_compra   dfc ON dfc.id = ddc.detalle_factura_compra_id
JOIN productos                p   ON p.id   = dfc.producto_id;


