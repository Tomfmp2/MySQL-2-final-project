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


