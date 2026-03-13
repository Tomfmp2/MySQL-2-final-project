USE mini_erp;


-- ##########################################################
-- EVENTO 1: REPORTE MENSUAL DE VENTAS
-- Se ejecuta el día 1 de cada mes a las 00:05 AM
-- Consolida las ventas del mes anterior y las guarda en logs
-- ##########################################################

DROP EVENT IF EXISTS evt_reporte_mensual_ventas;

DELIMITER $$

CREATE EVENT evt_reporte_mensual_ventas
ON SCHEDULE
    EVERY 1 MONTH
    STARTS (DATE_FORMAT(NOW(), '%Y-%m-01') + INTERVAL 1 MONTH + INTERVAL 5 MINUTE)
COMMENT 'Genera el reporte mensual de ventas el día 1 de cada mes a las 00:05'
DO
BEGIN
    -- Variables de cabecera del periodo
    DECLARE v_periodo_ini   DATE;
    DECLARE v_periodo_fin   DATE;
    DECLARE v_periodo_label VARCHAR(7);

    -- Variables de resultado
    DECLARE v_total_facturas    INT     DEFAULT 0;
    DECLARE v_total_vendido     DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_total_iva         DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_total_descuentos  DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_total_neto        DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_total_devoluciones DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_ticket_promedio   DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_mejor_asesor      VARCHAR(150)  DEFAULT 'N/A';
    DECLARE v_mejor_ciudad      VARCHAR(50)   DEFAULT 'N/A';
    DECLARE v_producto_estrella VARCHAR(50)   DEFAULT 'N/A';

    -- Calcular el rango del mes anterior
    SET v_periodo_ini   = DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01');
    SET v_periodo_fin   = LAST_DAY(NOW() - INTERVAL 1 MONTH);
    SET v_periodo_label = DATE_FORMAT(v_periodo_ini, '%Y-%m');

    -- ── Totales de facturas activas del mes ──────────────────
    SELECT
        COUNT(DISTINCT fv.id),
        COALESCE(SUM(
            dfv.cantidad * dfv.valor_unitario
        ), 0),
        COALESCE(SUM(
            CASE WHEN dfv.iva > 0
                 THEN (dfv.cantidad * dfv.valor_unitario) * (dfv.iva / 100)
                 ELSE 0
            END
        ), 0)
    INTO
        v_total_facturas,
        v_total_vendido,
        v_total_iva
    FROM factura_venta fv
    JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
    WHERE fv.estado   = '1'
      AND fv.fecha   >= v_periodo_ini
      AND fv.fecha   <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND;

    -- ── Total descuentos aplicados ────────────────────────────
    SELECT
        COALESCE(SUM(
            (dfv.cantidad * dfv.valor_unitario) * (fv.descuento_porcentaje / 100)
        ), 0)
    INTO v_total_descuentos
    FROM factura_venta fv
    JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
    WHERE fv.estado  = '1'
      AND fv.fecha  >= v_periodo_ini
      AND fv.fecha  <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND;

    -- ── Total devoluciones del mes ────────────────────────────
    SELECT
        COALESCE(SUM(ddv.cantidad * dfv.valor_unitario), 0)
    INTO v_total_devoluciones
    FROM devolucion_venta dv
    JOIN detalle_devolucion_venta ddv ON ddv.devolucion_venta_id = dv.id
    JOIN detalle_factura_venta dfv    ON dfv.id = ddv.detalle_factura_venta_id
    WHERE dv.fecha >= v_periodo_ini
      AND dv.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND;

    -- ── Neto final = vendido + IVA - descuentos - devoluciones
    SET v_total_neto = v_total_vendido + v_total_iva - v_total_descuentos - v_total_devoluciones;

    -- ── Ticket promedio por factura ───────────────────────────
    IF v_total_facturas > 0 THEN
        SET v_ticket_promedio = v_total_neto / v_total_facturas;
    END IF;

    -- ── Mejor asesor del mes (por total vendido) ──────────────
    SELECT ac.razon_social
    INTO   v_mejor_asesor
    FROM   factura_venta fv
    JOIN   asesores_comerciales ac ON ac.id = fv.asesor_id
    WHERE  fv.estado  = '1'
      AND  fv.fecha  >= v_periodo_ini
      AND  fv.fecha  <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
      AND  fv.asesor_id IS NOT NULL
    GROUP  BY fv.asesor_id, ac.razon_social
    ORDER  BY COUNT(fv.id) DESC
    LIMIT  1;

    -- ── Ciudad con más ventas del mes ─────────────────────────
    SELECT ci.nombre
    INTO   v_mejor_ciudad
    FROM   factura_venta fv
    JOIN   clientes cl  ON cl.id = fv.cliente_id
    JOIN   ciudades ci  ON ci.id = cl.ciudad_id
    WHERE  fv.estado  = '1'
      AND  fv.fecha  >= v_periodo_ini
      AND  fv.fecha  <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
    GROUP  BY cl.ciudad_id, ci.nombre
    ORDER  BY COUNT(fv.id) DESC
    LIMIT  1;

    -- ── Producto más vendido del mes ──────────────────────────
    SELECT p.nombre
    INTO   v_producto_estrella
    FROM   detalle_factura_venta dfv
    JOIN   factura_venta fv ON fv.id = dfv.factura_venta_id
    JOIN   productos p      ON p.id  = dfv.producto_id
    WHERE  fv.estado  = '1'
      AND  fv.fecha  >= v_periodo_ini
      AND  fv.fecha  <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
    GROUP  BY dfv.producto_id, p.nombre
    ORDER  BY SUM(dfv.cantidad) DESC
    LIMIT  1;

    -- ── Guardar resumen consolidado en logs ───────────────────
    INSERT INTO logs (
        usuario_id, tabla, operacion, registro_id,
        descripcion, dato_nuevo, nivel
    )
    VALUES (
        NULL,
        'factura_venta',
        'SELECT',
        NULL,
        CONCAT('EVENTO AUTOMÁTICO | Reporte mensual de ventas — Periodo: ', v_periodo_label),
        JSON_OBJECT(
            'periodo',              v_periodo_label,
            'fecha_generacion',     NOW(),
            'total_facturas',       v_total_facturas,
            'total_vendido',        v_total_vendido,
            'total_iva',            v_total_iva,
            'total_descuentos',     v_total_descuentos,
            'total_devoluciones',   v_total_devoluciones,
            'total_neto',           v_total_neto,
            'ticket_promedio',      v_ticket_promedio,
            'mejor_asesor',         v_mejor_asesor,
            'ciudad_top',           v_mejor_ciudad,
            'producto_estrella',    v_producto_estrella
        ),
        'INFO'
    );

END$$

DELIMITER ;


-- ##########################################################
-- EVENTO 2: REPORTE MENSUAL DE ROTACIÓN DE PRODUCTOS
-- Se ejecuta el día 1 de cada mes a las 00:30 AM
-- Recalcula desde cero la tabla reporte_rotacion_producto
-- para el mes anterior, sobreescribiendo datos existentes
-- ##########################################################

DROP EVENT IF EXISTS evt_reporte_mensual_rotacion;

DELIMITER $$

CREATE EVENT evt_reporte_mensual_rotacion
ON SCHEDULE
    EVERY 1 MONTH
    STARTS (DATE_FORMAT(NOW(), '%Y-%m-01') + INTERVAL 1 MONTH + INTERVAL 30 MINUTE)
COMMENT 'Recalcula la rotación mensual de productos el día 1 de cada mes a las 00:30'
DO
BEGIN
    DECLARE v_periodo_ini   DATE;
    DECLARE v_periodo_fin   DATE;
    DECLARE v_periodo_label DATE;
    DECLARE v_total_prods   INT DEFAULT 0;
    DECLARE v_sin_movimiento INT DEFAULT 0;
    DECLARE v_alta_rotacion  INT DEFAULT 0;

    SET v_periodo_ini   = DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01');
    SET v_periodo_fin   = LAST_DAY(NOW() - INTERVAL 1 MONTH);
    SET v_periodo_label = v_periodo_ini;

    -- ── Limpiar datos del periodo anterior ya procesado ──────
    -- (en caso de re-ejecución del evento)
    DELETE FROM reporte_rotacion_producto
    WHERE periodo = v_periodo_label;

    -- ── Insertar/actualizar rotación por producto activo ─────
    -- Rotación = unidades_vendidas / ((stock_inicial + stock_final) / 2)
    -- Si el denominador es 0, rotación = unidades_vendidas (stock agotado)
    INSERT INTO reporte_rotacion_producto (
        periodo,
        producto_id,
        nombre_producto,
        unidades_vendidas,
        unidades_compradas,
        stock_final,
        rotacion
    )
    SELECT
        v_periodo_label                         AS periodo,
        p.id                                    AS producto_id,
        p.nombre                                AS nombre_producto,

        -- Unidades vendidas en el periodo (sin devoluciones)
        COALESCE((
            SELECT SUM(dfv.cantidad)
            FROM   detalle_factura_venta dfv
            JOIN   factura_venta fv ON fv.id = dfv.factura_venta_id
            WHERE  dfv.producto_id = p.id
              AND  fv.estado = '1'
              AND  fv.fecha >= v_periodo_ini
              AND  fv.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
        ) - COALESCE((
            SELECT SUM(ddv.cantidad)
            FROM   detalle_devolucion_venta ddv
            JOIN   devolucion_venta dv       ON dv.id  = ddv.devolucion_venta_id
            JOIN   detalle_factura_venta dfv ON dfv.id = ddv.detalle_factura_venta_id
            WHERE  dfv.producto_id = p.id
              AND  dv.fecha >= v_periodo_ini
              AND  dv.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
        ), 0), 0)                               AS unidades_vendidas,

        -- Unidades compradas en el periodo (sin devoluciones a proveedor)
        COALESCE((
            SELECT SUM(dfc.cantidad)
            FROM   detalle_factura_compra dfc
            JOIN   factura_compra fc ON fc.id = dfc.factura_compra_id
            WHERE  dfc.producto_id = p.id
              AND  fc.estado = '1'
              AND  fc.fecha >= v_periodo_ini
              AND  fc.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
        ) - COALESCE((
            SELECT SUM(ddc.cantidad)
            FROM   detalle_devolucion_compra ddc
            JOIN   devolucion_compra dc       ON dc.id  = ddc.devolucion_compra_id
            JOIN   detalle_factura_compra dfc ON dfc.id = ddc.detalle_factura_compra_id
            WHERE  dfc.producto_id = p.id
              AND  dc.fecha >= v_periodo_ini
              AND  dc.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
        ), 0), 0)                               AS unidades_compradas,

        -- Stock actual consolidado de todas las bodegas
        COALESCE((
            SELECT SUM(i.cantidad)
            FROM   inventario i
            WHERE  i.producto_id = p.id
        ), 0)                                   AS stock_final,

        -- Índice de rotación
        -- Si stock promedio = 0 pero hubo ventas → rotación alta = ventas mismas
        CASE
            WHEN (
                COALESCE((
                    SELECT SUM(i.cantidad) FROM inventario i WHERE i.producto_id = p.id
                ), 0) + COALESCE((
                    SELECT SUM(dfv.cantidad)
                    FROM detalle_factura_venta dfv
                    JOIN factura_venta fv ON fv.id = dfv.factura_venta_id
                    WHERE dfv.producto_id = p.id
                      AND fv.estado = '1'
                      AND fv.fecha >= v_periodo_ini
                      AND fv.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
                ), 0)
            ) = 0 THEN 0.0000
            ELSE ROUND(
                COALESCE((
                    SELECT SUM(dfv.cantidad)
                    FROM detalle_factura_venta dfv
                    JOIN factura_venta fv ON fv.id = dfv.factura_venta_id
                    WHERE dfv.producto_id = p.id
                      AND fv.estado = '1'
                      AND fv.fecha >= v_periodo_ini
                      AND fv.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
                ), 0)
                /
                (
                    (
                        COALESCE((
                            SELECT SUM(i.cantidad) FROM inventario i WHERE i.producto_id = p.id
                        ), 0)
                        + COALESCE((
                            SELECT SUM(dfv2.cantidad)
                            FROM detalle_factura_venta dfv2
                            JOIN factura_venta fv2 ON fv2.id = dfv2.factura_venta_id
                            WHERE dfv2.producto_id = p.id
                              AND fv2.estado = '1'
                              AND fv2.fecha >= v_periodo_ini
                              AND fv2.fecha <= v_periodo_fin + INTERVAL 1 DAY - INTERVAL 1 SECOND
                        ), 0)
                    ) / 2
                )
            , 4)
        END                                     AS rotacion

    FROM productos p
    WHERE p.estado = '1'
    ORDER BY p.id;

    -- ── Contar totales para el log ────────────────────────────
    SELECT COUNT(*)
    INTO   v_total_prods
    FROM   reporte_rotacion_producto
    WHERE  periodo = v_periodo_label;

    SELECT COUNT(*)
    INTO   v_sin_movimiento
    FROM   reporte_rotacion_producto
    WHERE  periodo            = v_periodo_label
      AND  unidades_vendidas  = 0
      AND  unidades_compradas = 0;

    SELECT COUNT(*)
    INTO   v_alta_rotacion
    FROM   reporte_rotacion_producto
    WHERE  periodo  = v_periodo_label
      AND  rotacion >= 1.5;

    -- ── Guardar resumen en logs ───────────────────────────────
    INSERT INTO logs (
        usuario_id, tabla, operacion, registro_id,
        descripcion, dato_nuevo, nivel
    )
    VALUES (
        NULL,
        'reporte_rotacion_producto',
        'INSERT',
        NULL,
        CONCAT('EVENTO AUTOMÁTICO | Reporte mensual de rotación — Periodo: ',
               DATE_FORMAT(v_periodo_label, '%Y-%m')),
        JSON_OBJECT(
            'periodo',              DATE_FORMAT(v_periodo_label, '%Y-%m'),
            'fecha_generacion',     NOW(),
            'productos_procesados', v_total_prods,
            'sin_movimiento',       v_sin_movimiento,
            'alta_rotacion',        v_alta_rotacion,
            'media_rotacion',       (v_total_prods - v_alta_rotacion - v_sin_movimiento),
            'criterio_alta',        'rotacion >= 1.5',
            'criterio_baja',        '0 < rotacion < 1.5',
            'criterio_sin_mov',     'ventas = 0 AND compras = 0'
        ),
        'INFO'
    );

END$$

DELIMITER ;


-- ##########################################################
-- VERIFICACIÓN
-- ##########################################################

-- Ver que el scheduler está activo
SHOW VARIABLES LIKE 'event_scheduler';

-- Ver los eventos creados
SHOW EVENTS FROM mini_erp;

-- Ver detalle de cada evento
SHOW CREATE EVENT evt_reporte_mensual_ventas\G
SHOW CREATE EVENT evt_reporte_mensual_rotacion\G



-- EJECUCIÓN MANUAL 


-- Disparar el evento de ventas ahora mismo
CALL sys.execute_prepared_stmt(
    (SELECT event_definition
     FROM   information_schema.EVENTS
     WHERE  EVENT_SCHEMA = 'mini_erp'
       AND  EVENT_NAME   = 'evt_reporte_mensual_ventas')
);

-- ─── PRUEBA RÁPIDA EVENTO 1 ──────────────────────────────
SET @ini = DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01');
SET @fin = LAST_DAY(NOW() - INTERVAL 1 MONTH);

SELECT
    DATE_FORMAT(@ini, '%Y-%m')           AS periodo,
    COUNT(DISTINCT fv.id)                AS total_facturas,
    ROUND(SUM(dfv.cantidad * dfv.valor_unitario), 2)
                                         AS total_bruto,
    ROUND(SUM(
        CASE WHEN dfv.iva > 0
             THEN (dfv.cantidad * dfv.valor_unitario) * (dfv.iva/100)
             ELSE 0 END), 2)             AS total_iva,
    ROUND(SUM(
        (dfv.cantidad * dfv.valor_unitario) * (fv.descuento_porcentaje/100)
    ), 2)                                AS total_descuentos
FROM factura_venta fv
JOIN detalle_factura_venta dfv ON dfv.factura_venta_id = fv.id
WHERE fv.estado = '1'
  AND fv.fecha BETWEEN @ini AND @fin + INTERVAL 1 DAY - INTERVAL 1 SECOND;

-- ─── PRUEBA RÁPIDA EVENTO 2 ──────────────────────────────
SET @periodo = DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01');

SELECT
    p.nombre                                AS producto,
    COALESCE(SUM(dfv.cantidad), 0)          AS unidades_vendidas,
    COALESCE(SUM(i.cantidad), 0)            AS stock_actual,
    CASE
        WHEN COALESCE(SUM(dfv.cantidad), 0) = 0 THEN 'SIN MOVIMIENTO'
        WHEN COALESCE(SUM(dfv.cantidad), 0) /
             NULLIF((COALESCE(SUM(i.cantidad),0) +
                     COALESCE(SUM(dfv.cantidad),0)) / 2, 0) >= 1.5
             THEN 'ALTA'
        ELSE 'MEDIA / BAJA'
    END                                     AS clasificacion_rotacion
FROM productos p
LEFT JOIN detalle_factura_venta dfv
       ON dfv.producto_id = p.id
LEFT JOIN factura_venta fv
       ON fv.id = dfv.factura_venta_id
      AND fv.estado = '1'
      AND fv.fecha BETWEEN @periodo AND LAST_DAY(@periodo) + INTERVAL 1 DAY - INTERVAL 1 SECOND
LEFT JOIN inventario i ON i.producto_id = p.id
WHERE p.estado = '1'
GROUP BY p.id, p.nombre
ORDER BY unidades_vendidas DESC;

-- ─── Ver los logs generados por los eventos ───────────────
SELECT
    fecha,
    descripcion,
    dato_nuevo
FROM logs
WHERE tabla IN ('factura_venta', 'reporte_rotacion_producto')
  AND descripcion LIKE 'EVENTO AUTOMÁTICO%'
ORDER BY fecha DESC
LIMIT 10;
