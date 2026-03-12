usuarios y permisos



USE mini_erp;

-- ==========================================================
-- USUARIOS DE BASE DE DATOS SEGÚN ROL DEL NEGOCIO
-- ==========================================================
-- Roles del negocio:
--   1. Administrador      → acceso total
--   2. Gerente            → lectura total + reportes
--   3. Cajero/Vendedor    → ventas, clientes, inventario lectura
--   4. Bodeguero          → inventario, compras, traslados
--   5. Asesor Comercial   → sus propias ventas y comisiones
--   6. Contador           → facturas, reportes, solo lectura
--   7. App Backend        → ejecución de SPs únicamente
-- ==========================================================


-- ##########################################################
-- LIMPIEZA PREVIA (si ya existen)
-- ##########################################################

DROP USER IF EXISTS 'admin_erp'@'localhost';
DROP USER IF EXISTS 'gerente_erp'@'localhost';
DROP USER IF EXISTS 'cajero_erp'@'localhost';
DROP USER IF EXISTS 'bodeguero_erp'@'localhost';
DROP USER IF EXISTS 'asesor_erp'@'localhost';
DROP USER IF EXISTS 'contador_erp'@'localhost';
DROP USER IF EXISTS 'app_backend'@'%';


-- ##########################################################
-- 1. ADMINISTRADOR
-- Acceso total a la base de datos
-- Caso de uso: DBA o desarrollador senior del sistema
-- ##########################################################

CREATE USER 'admin_erp'@'localhost'
    IDENTIFIED BY 'Admin@ERP_2026#Seguro';

GRANT ALL PRIVILEGES
    ON proyecto2.*
    TO 'admin_erp'@'localhost'
    WITH GRANT OPTION;
-- WITH GRANT OPTION: puede asignar permisos a otros usuarios


-- ##########################################################
-- 2. GERENTE
-- Solo lectura en tablas + ejecución de SPs de reportes
-- Caso de uso: directivo que consulta indicadores del negocio
-- ##########################################################

CREATE USER 'gerente_erp'@'localhost'
    IDENTIFIED BY 'Gerente@ERP_2026#';

-- Lectura en todas las tablas transaccionales
GRANT SELECT ON proyecto2.productos              TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.categoria             TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.clientes              TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.personas              TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.empresas              TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.factura_venta         TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_factura_venta TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.factura_compra        TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_factura_compra TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.devolucion_venta      TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.devolucion_compra     TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.inventario            TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.bodegas               TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.asesores_comerciales  TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.comisiones_asesor     TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.proveedores           TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.usuarios              TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.reporte_rotacion_producto TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.logs                  TO 'gerente_erp'@'localhost';

-- Acceso a todas las vistas
GRANT SELECT ON proyecto2.v_stock_actual            TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_bajo              TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_total_producto    TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_facturas_venta          TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_detalle_facturas_venta  TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_ventas_por_asesor       TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_devoluciones_venta      TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_facturas_compra         TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_devoluciones_compra     TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_historial_cliente       TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_permisos_usuario        TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_logs_errores            TO 'gerente_erp'@'localhost';
GRANT SELECT ON proyecto2.v_actividad_reciente      TO 'gerente_erp'@'localhost';

-- Ejecución de SPs de reportes y funciones
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_ventas_periodo        TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_inventario_bodega     TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_comisiones_mes        TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_rotacion_productos    TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_compras_periodo       TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_devoluciones_periodo  TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_rentabilidad_categoria TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_top_clientes          TO 'gerente_erp'@'localhost';

GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_venta            TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_compra           TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_descuento_cliente              TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_comision_asesor                TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_ventas_asesor            TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_utilidad_producto              TO 'gerente_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_total_producto           TO 'gerente_erp'@'localhost';


-- ##########################################################
-- 3. CAJERO / VENDEDOR
-- Crea facturas de venta, gestiona clientes
-- Caso de uso: empleado en caja o mostrador de ventas
-- ##########################################################

CREATE USER 'cajero_erp'@'localhost'
    IDENTIFIED BY 'Cajero@ERP_2026#';

-- Lectura de catálogos necesarios para operar
GRANT SELECT ON proyecto2.productos              TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.categoria             TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.clientes              TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.personas              TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.empresas              TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.inventario            TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.bodegas               TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.tipo_pago             TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.tipo_documento        TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.tipo_email            TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.ciudades              TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.asesores_comerciales  TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.garantias             TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.descuentos_cliente    TO 'cajero_erp'@'localhost';

-- Vistas útiles para el cajero
GRANT SELECT ON proyecto2.v_stock_actual            TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_bajo              TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_facturas_venta          TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_detalle_facturas_venta  TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_historial_cliente       TO 'cajero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_devoluciones_venta      TO 'cajero_erp'@'localhost';

-- SPs de ventas y clientes
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_factura_venta       TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_agregar_linea_venta       TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_anular_factura_venta      TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_devolucion_venta    TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_cliente_persona     TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_cliente_empresa     TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_actualizar_cliente        TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_leer_cliente              TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_listar_productos          TO 'cajero_erp'@'localhost';

-- Funciones que necesita para mostrar precios y descuentos
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_venta        TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_subtotal_factura_venta     TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_iva_factura_venta          TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_valor_descuento_factura    TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_descuento_cliente          TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_aplicar_descuento          TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_precio_neto_producto       TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_disponible           TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_garantia_vigente           TO 'cajero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_dias_garantia_restantes    TO 'cajero_erp'@'localhost';


-- ##########################################################
-- 4. BODEGUERO
-- Gestiona compras, inventario y traslados entre bodegas
-- Caso de uso: encargado de bodega y recepción de mercancía
-- ##########################################################

CREATE USER 'bodeguero_erp'@'localhost'
    IDENTIFIED BY 'Bodega@ERP_2026#';

-- Lectura de catálogos necesarios
GRANT SELECT ON proyecto2.productos               TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.categoria              TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.inventario             TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.bodegas                TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.ciudades               TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.proveedores            TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.factura_compra         TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_factura_compra TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.tipo_pago              TO 'bodeguero_erp'@'localhost';

-- Vistas de inventario
GRANT SELECT ON proyecto2.v_stock_actual            TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_bajo              TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_total_producto    TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_facturas_compra         TO 'bodeguero_erp'@'localhost';
GRANT SELECT ON proyecto2.v_devoluciones_compra     TO 'bodeguero_erp'@'localhost';

-- SPs de compras, inventario y traslados
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_factura_compra      TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_agregar_linea_compra      TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_anular_factura_compra     TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_devolucion_compra   TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_traslado_inventario       TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_inventario_bodega TO 'bodeguero_erp'@'localhost';

-- Funciones de inventario
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_disponible           TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_total_producto       TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_valor_inventario_costo     TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_capacidad_disponible_bodega TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_precio_neto_producto       TO 'bodeguero_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_compra       TO 'bodeguero_erp'@'localhost';


-- ##########################################################
-- 5. ASESOR COMERCIAL
-- Consulta sus propias ventas y comisiones
-- Caso de uso: vendedor externo que solo ve su información
-- ##########################################################

CREATE USER 'asesor_erp'@'localhost'
    IDENTIFIED BY 'Asesor@ERP_2026#';

-- Solo lectura de lo que necesita
GRANT SELECT ON proyecto2.productos              TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.categoria             TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.clientes              TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.personas              TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.empresas              TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.factura_venta         TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_factura_venta TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.comisiones_asesor     TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.inventario            TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.descuentos_cliente    TO 'asesor_erp'@'localhost';

-- Vistas relevantes para el asesor
GRANT SELECT ON proyecto2.v_ventas_por_asesor       TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.v_historial_cliente       TO 'asesor_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_actual            TO 'asesor_erp'@'localhost';

-- SPs de reportes propios
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_ventas_periodo   TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_comisiones_mes   TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_top_clientes     TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_leer_cliente             TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_listar_productos         TO 'asesor_erp'@'localhost';

-- Funciones de consulta
GRANT EXECUTE ON FUNCTION proyecto2.fn_comision_asesor           TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_ventas_asesor       TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_descuento_cliente         TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_precio_neto_producto      TO 'asesor_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_disponible          TO 'asesor_erp'@'localhost';


-- ##########################################################
-- 6. CONTADOR
-- Solo lectura total para análisis contable y financiero
-- Caso de uso: área contable, auditor externo
-- ##########################################################

CREATE USER 'contador_erp'@'localhost'
    IDENTIFIED BY 'Contador@ERP_2026#';

-- Lectura de todo lo contable y financiero
GRANT SELECT ON proyecto2.factura_venta               TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_factura_venta       TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.factura_compra              TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_factura_compra      TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.devolucion_venta            TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_devolucion_venta    TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.devolucion_compra           TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.detalle_devolucion_compra   TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.productos                   TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.clientes                    TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.personas                    TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.empresas                    TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.proveedores                 TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.comisiones_asesor           TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.inventario                  TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.tipo_pago                   TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.logs                        TO 'contador_erp'@'localhost';

-- Todas las vistas financieras
GRANT SELECT ON proyecto2.v_facturas_venta            TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_detalle_facturas_venta    TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_facturas_compra           TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_devoluciones_venta        TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_devoluciones_compra       TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_historial_cliente         TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_logs_errores              TO 'contador_erp'@'localhost';
GRANT SELECT ON proyecto2.v_stock_total_producto      TO 'contador_erp'@'localhost';

-- Reportes financieros
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_ventas_periodo         TO 'contador_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_compras_periodo        TO 'contador_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_devoluciones_periodo   TO 'contador_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_rentabilidad_categoria TO 'contador_erp'@'localhost';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_top_clientes           TO 'contador_erp'@'localhost';

-- Funciones financieras
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_venta             TO 'contador_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_compra            TO 'contador_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_subtotal_factura_venta          TO 'contador_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_iva_factura_venta               TO 'contador_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_valor_descuento_factura         TO 'contador_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_utilidad_producto               TO 'contador_erp'@'localhost';
GRANT EXECUTE ON FUNCTION proyecto2.fn_valor_inventario_costo          TO 'contador_erp'@'localhost';


-- ##########################################################
-- 7. APP BACKEND
-- Usuario que usa la aplicación web/móvil
-- Solo ejecuta SPs, no accede a tablas directamente
-- Caso de uso: API REST, microservicios
-- Se conecta desde cualquier IP (%) con SSL recomendado
-- ##########################################################

CREATE USER 'app_backend'@'%'
    IDENTIFIED BY 'AppBackend@ERP_2026#Ultra';

-- Solo ejecuta SPs — nunca accede a tablas directamente
-- SPs de productos
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_producto            TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_actualizar_producto       TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_desactivar_producto       TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_listar_productos          TO 'app_backend'@'%';

-- SPs de clientes
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_cliente_persona     TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_cliente_empresa     TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_actualizar_cliente        TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_desactivar_cliente        TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_leer_cliente              TO 'app_backend'@'%';

-- SPs de usuarios
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_usuario             TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_actualizar_usuario        TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_desactivar_usuario        TO 'app_backend'@'%';

-- SPs de ventas
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_factura_venta       TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_agregar_linea_venta       TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_anular_factura_venta      TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_devolucion_venta    TO 'app_backend'@'%';

-- SPs de compras
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_factura_compra      TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_agregar_linea_compra      TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_anular_factura_compra     TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_crear_devolucion_compra   TO 'app_backend'@'%';

-- SPs de inventario
GRANT EXECUTE ON PROCEDURE proyecto2.sp_traslado_inventario       TO 'app_backend'@'%';

-- SPs de reportes
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_ventas_periodo         TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_inventario_bodega      TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_comisiones_mes         TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_rotacion_productos     TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_compras_periodo        TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_devoluciones_periodo   TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_rentabilidad_categoria TO 'app_backend'@'%';
GRANT EXECUTE ON PROCEDURE proyecto2.sp_reporte_top_clientes           TO 'app_backend'@'%';

-- Todas las funciones
GRANT EXECUTE ON FUNCTION proyecto2.fn_subtotal_factura_venta          TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_iva_factura_venta               TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_valor_descuento_factura         TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_venta             TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_factura_compra            TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_descuento_cliente               TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_aplicar_descuento               TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_disponible                TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_stock_total_producto            TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_valor_inventario_costo          TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_capacidad_disponible_bodega     TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_comision_asesor                 TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_total_ventas_asesor             TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_utilidad_producto               TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_precio_neto_producto            TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_garantia_vigente                TO 'app_backend'@'%';
GRANT EXECUTE ON FUNCTION proyecto2.fn_dias_garantia_restantes         TO 'app_backend'@'%';


-- ##########################################################
-- APLICAR TODOS LOS CAMBIOS
-- ##########################################################

FLUSH PRIVILEGES;


-- ##########################################################
-- VERIFICACIÓN: Ver usuarios y sus permisos
-- ##########################################################

-- Ver todos los usuarios creados
SELECT user, host, account_locked, password_expired
FROM mysql.user
WHERE user IN (
    'admin_erp','gerente_erp','cajero_erp',
    'bodeguero_erp','asesor_erp','contador_erp','app_backend'
);

-- Ver permisos de un usuario específico
SHOW GRANTS FOR 'cajero_erp'@'localhost';
SHOW GRANTS FOR 'app_backend'@'%';
