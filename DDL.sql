CREATE DATABASE IF NOT EXISTS mini_erp;
USE mini_erp;

-- ==========================================================
-- 1. TABLAS MAESTRAS
-- ==========================================================

CREATE TABLE `ciudades` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL
);

CREATE TABLE `tipo_documento` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo` varchar(25) NOT NULL
);

CREATE TABLE `tipo_email` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo` varchar(100) NOT NULL
);

CREATE TABLE `tipo_pago` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nombre` varchar(50) UNIQUE NOT NULL
);

CREATE TABLE `modulos` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nombre` varchar(50) UNIQUE NOT NULL,
  `descripcion` varchar(200)
);

-- ==========================================================
-- 2. MÓDULO DE SEGURIDAD
-- ==========================================================

CREATE TABLE `roles` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `nombre` varchar(50) UNIQUE NOT NULL,
  `descripcion` varchar(200),
  `estado` ENUM('0','1') NOT NULL DEFAULT '1'
);

CREATE TABLE `permisos` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `modulo_id` int NOT NULL,
  `nombre` varchar(50) UNIQUE NOT NULL,
  `descripcion` varchar(200),
  `lectura`       TINYINT(1) NOT NULL DEFAULT 0,
  `escritura`     TINYINT(1) NOT NULL DEFAULT 0,
  `actualizacion` TINYINT(1) NOT NULL DEFAULT 0,
  `eliminacion`   TINYINT(1) NOT NULL DEFAULT 0
);

CREATE TABLE `usuarios` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `rol_principal_id` int NULL,
  `tipo_documento_id` int NOT NULL,
  `num_documento` varchar(20) UNIQUE NOT NULL,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `direccion` varchar(200) NOT NULL,
  `ciudad_id` int NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `email_personal` varchar(100) NOT NULL,
  `email_corporativo` varchar(100) UNIQUE NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `foto_url` varchar(255),
  `estado` ENUM('0','1') NOT NULL DEFAULT '1',
  INDEX `idx_usuario_login` (`email_corporativo`, `estado`)
);

CREATE TABLE `rol_permiso` (
  `rol_id` int NOT NULL,
  `permiso_id` int NOT NULL,
  PRIMARY KEY (`rol_id`, `permiso_id`)
);

CREATE TABLE `usuario_rol` (
  `usuario_id` int NOT NULL,
  `rol_id` int NOT NULL,
  PRIMARY KEY (`usuario_id`, `rol_id`)
);

CREATE TABLE `usuario_permiso` (
  `usuario_id` int NOT NULL,
  `permiso_id` int NOT NULL,
  PRIMARY KEY (`usuario_id`, `permiso_id`)
);

-- ==========================================================
-- 3. MÓDULO DE INVENTARIO
-- ==========================================================

CREATE TABLE `categoria` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo` varchar(30) NOT NULL
);

CREATE TABLE `productos` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `codigo` varchar(30) UNIQUE NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` text NOT NULL,
  `categoria_id` int NOT NULL,
  `porcentaje_utilidad` decimal(5,2) NOT NULL,
  `valor_compra` decimal(15,2) NOT NULL,
  `valor_venta` decimal(15,2) NOT NULL,
  `iva` decimal(5,2) NOT NULL,
  `imagen_url` varchar(255),
  `estado` ENUM('0','1') NOT NULL DEFAULT '1',
  INDEX `idx_producto_query` (`nombre`, `codigo`)
);

CREATE TABLE `bodegas` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `codigo` varchar(30) UNIQUE NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `descripcion` text,
  `ciudad_id` int NOT NULL,
  `direccion` varchar(200) NOT NULL,
  `cantidad_maxima` int NOT NULL,
  `estado` ENUM('0','1') NOT NULL DEFAULT '1'
);

CREATE TABLE `inventario` (
  `producto_id` int NOT NULL,
  `bodega_id` int NOT NULL,
  `cantidad` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`producto_id`, `bodega_id`),
  INDEX `idx_inventario_stock` (`cantidad`)
);

-- ==========================================================
-- 4. MÓDULO DE COMPRAS
-- ==========================================================

CREATE TABLE `proveedores` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo_documento_id` int NOT NULL,
  `num_documento` varchar(20) UNIQUE NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(200) NOT NULL,
  `ciudad_id` int NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  `estado` ENUM('0','1') NOT NULL DEFAULT '1'
);

CREATE TABLE `proveedor_producto` (
  `proveedor_id` int NOT NULL,
  `producto_id` int NOT NULL,
  PRIMARY KEY (`proveedor_id`, `producto_id`)
);

CREATE TABLE `factura_compra` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `proveedor_id` int NOT NULL,
  `usuario_id` int NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tipo_pago_id` int NOT NULL,
  `num_factura` varchar(50) UNIQUE NOT NULL,
  `estado` ENUM('0','1') NOT NULL DEFAULT '1',
  `observaciones` text,
  INDEX `idx_compra_fecha` (`fecha`)
);

CREATE TABLE `detalle_factura_compra` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `factura_compra_id` int NOT NULL,
  `producto_id` int NOT NULL,
  `bodega_id` int NOT NULL,
  `cantidad` int NOT NULL,
  `valor_unitario` decimal(15,2) NOT NULL,
  `iva` decimal(5,2) NOT NULL,
  INDEX `idx_det_compra_prod` (`producto_id`)
);

CREATE TABLE `devolucion_compra` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `factura_compra_id` int NOT NULL,
  `usuario_id` int NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observaciones` text,
  INDEX `idx_devcom_fecha` (`fecha`)
);

CREATE TABLE `detalle_devolucion_compra` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `devolucion_compra_id` int NOT NULL,
  `detalle_factura_compra_id` int NOT NULL,
  `cantidad` int NOT NULL
);

-- ==========================================================
-- 5. MÓDULO DE VENTAS
-- ==========================================================

CREATE TABLE `clientes` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo_documento_id` int NOT NULL,
  `num_documento` varchar(20) UNIQUE NOT NULL,
  `nombre_email` varchar(100) NOT NULL,
  `tipo_email_id` int NOT NULL,
  `direccion` varchar(200) NOT NULL,
  `ciudad_id` int NOT NULL,
  `genero` ENUM('M','F','Otro') NULL,
  `estado` ENUM('0','1') NOT NULL DEFAULT '1',
  INDEX `idx_cliente_doc` (`num_documento`)
);

CREATE TABLE `personas` (
  `cliente_id` int PRIMARY KEY,
  `nombre` varchar(50) NOT NULL,
  `apellido` varchar(50) NOT NULL
);

CREATE TABLE `empresas` (
  `cliente_id` int PRIMARY KEY,
  `nombre` varchar(100) NOT NULL,
  `representante` varchar(50) NOT NULL
);

CREATE TABLE `num_telefonico` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `telefono` varchar(20) NOT NULL,
  `cliente_id` int NOT NULL,
  INDEX `idx_numtel_cliente` (`cliente_id`)
);

CREATE TABLE `descuentos_cliente` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `cliente_id` int NOT NULL,
  `porcentaje` decimal(5,2) NOT NULL,
  `monto_minimo` decimal(15,2) NOT NULL DEFAULT 0.00,
  `activo` TINYINT(1) NOT NULL DEFAULT 1,
  `fecha_aplicacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_desc_cliente` (`cliente_id`)
);

CREATE TABLE `asesores_comerciales` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `tipo_documento_id` int NOT NULL,
  `num_documento` varchar(20) UNIQUE NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(200) NOT NULL,
  `ciudad_id` int NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  `estado` ENUM('0','1') NOT NULL DEFAULT '1'
);

CREATE TABLE `asesor_producto` (
  `asesor_id` int NOT NULL,
  `producto_id` int NOT NULL,
  PRIMARY KEY (`asesor_id`, `producto_id`)
);

CREATE TABLE `comisiones_asesor` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `asesor_id` int NOT NULL,
  `periodo` date NOT NULL,
  `total_ventas` decimal(15,2) NOT NULL DEFAULT 0.00,
  `porcentaje` decimal(5,2) NOT NULL DEFAULT 0.00,
  `valor` decimal(15,2) NOT NULL DEFAULT 0.00,
  UNIQUE KEY `uq_asesor_periodo` (`asesor_id`, `periodo`)
);

CREATE TABLE `factura_venta` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `cliente_id` int NOT NULL,
  `asesor_id` int NULL,
  `usuario_id` int NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tipo_pago_id` int NOT NULL,
  `num_factura` varchar(50) UNIQUE NOT NULL,
  `descuento_porcentaje` decimal(5,2) NOT NULL DEFAULT 0.00,
  `estado` ENUM('0','1') NOT NULL DEFAULT '1',
  `observaciones` text,
  INDEX `idx_venta_asesor_mes` (`fecha`, `asesor_id`)
);

CREATE TABLE `detalle_factura_venta` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `factura_venta_id` int NOT NULL,
  `producto_id` int NOT NULL,
  `bodega_id` int NOT NULL,
  `cantidad` int NOT NULL,
  `valor_unitario` decimal(15,2) NOT NULL,
  `iva` decimal(5,2) NOT NULL,
  INDEX `idx_det_venta_prod` (`producto_id`)
);

CREATE TABLE `devolucion_venta` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `factura_venta_id` int NOT NULL,
  `usuario_id` int NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `observaciones` text,
  INDEX `idx_devvta_fecha` (`fecha`)
);

CREATE TABLE `detalle_devolucion_venta` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `devolucion_venta_id` int NOT NULL,
  `detalle_factura_venta_id` int NOT NULL,
  `cantidad` int NOT NULL
);

-- ==========================================================
-- 6. REGLAS DE NEGOCIO
-- ==========================================================

CREATE TABLE `garantias` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `detalle_venta_id` int NOT NULL,
  `tipo` ENUM('empresa','proveedor') NOT NULL,
  `meses` int NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  INDEX `idx_garantia_venta` (`detalle_venta_id`)
);

CREATE TABLE `reporte_rotacion_producto` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `periodo` date NOT NULL,
  `producto_id` int NOT NULL,
  `nombre_producto` varchar(50) NOT NULL,
  `unidades_vendidas` int NOT NULL DEFAULT 0,
  `unidades_compradas` int NOT NULL DEFAULT 0,
  `stock_final` int NOT NULL DEFAULT 0,
  `rotacion` decimal(10,4) NOT NULL DEFAULT 0.0000,
  UNIQUE KEY `uq_rotacion_periodo_prod` (`periodo`, `producto_id`)
);

-- ==========================================================
-- 7. LOGS
-- ==========================================================

CREATE TABLE `logs` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `usuario_id` int NULL,
  `tabla` varchar(50) NOT NULL,
  `operacion` ENUM('INSERT','UPDATE','DELETE','SELECT','ERROR') NOT NULL,
  `registro_id` int NULL,
  `descripcion` text NOT NULL,
  `dato_anterior` JSON NULL,
  `dato_nuevo` JSON NULL,
  `ip` varchar(45) NULL,
  `nivel` ENUM('INFO','WARNING','ERROR') NOT NULL DEFAULT 'INFO',
  INDEX `idx_log_fecha`     (`fecha`),
  INDEX `idx_log_tabla`     (`tabla`),
  INDEX `idx_log_nivel`     (`nivel`),
  INDEX `idx_log_usuario`   (`usuario_id`),
  INDEX `idx_log_operacion` (`operacion`)
);

-- ==========================================================
-- 8. FOREIGN KEYS
-- ==========================================================

-- Seguridad
ALTER TABLE `permisos`
  ADD CONSTRAINT `fk_permiso_modulo`
    FOREIGN KEY (`modulo_id`) REFERENCES `modulos`(`id`);

ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_usuario_rol_principal`
    FOREIGN KEY (`rol_principal_id`) REFERENCES `roles`(`id`),
  ADD CONSTRAINT `fk_usuario_tipo_doc`
    FOREIGN KEY (`tipo_documento_id`) REFERENCES `tipo_documento`(`id`),
  ADD CONSTRAINT `fk_usuario_ciudad`
    FOREIGN KEY (`ciudad_id`) REFERENCES `ciudades`(`id`);

ALTER TABLE `rol_permiso`
  ADD CONSTRAINT `fk_rolpermiso_rol`
    FOREIGN KEY (`rol_id`) REFERENCES `roles`(`id`),
  ADD CONSTRAINT `fk_rolpermiso_permiso`
    FOREIGN KEY (`permiso_id`) REFERENCES `permisos`(`id`);

ALTER TABLE `usuario_rol`
  ADD CONSTRAINT `fk_usuariorol_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`),
  ADD CONSTRAINT `fk_usuariorol_rol`
    FOREIGN KEY (`rol_id`) REFERENCES `roles`(`id`);

ALTER TABLE `usuario_permiso`
  ADD CONSTRAINT `fk_usuariopermiso_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`),
  ADD CONSTRAINT `fk_usuariopermiso_permiso`
    FOREIGN KEY (`permiso_id`) REFERENCES `permisos`(`id`);

-- Inventario
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_producto_categoria`
    FOREIGN KEY (`categoria_id`) REFERENCES `categoria`(`id`);

ALTER TABLE `bodegas`
  ADD CONSTRAINT `fk_bodega_ciudad`
    FOREIGN KEY (`ciudad_id`) REFERENCES `ciudades`(`id`);

ALTER TABLE `inventario`
  ADD CONSTRAINT `fk_inventario_producto`
    FOREIGN KEY (`producto_id`) REFERENCES `productos`(`id`),
  ADD CONSTRAINT `fk_inventario_bodega`
    FOREIGN KEY (`bodega_id`) REFERENCES `bodegas`(`id`);

-- Compras
ALTER TABLE `proveedores`
  ADD CONSTRAINT `fk_proveedor_tipodoc`
    FOREIGN KEY (`tipo_documento_id`) REFERENCES `tipo_documento`(`id`),
  ADD CONSTRAINT `fk_proveedor_ciudad`
    FOREIGN KEY (`ciudad_id`) REFERENCES `ciudades`(`id`);

ALTER TABLE `proveedor_producto`
  ADD CONSTRAINT `fk_provprod_proveedor`
    FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores`(`id`),
  ADD CONSTRAINT `fk_provprod_producto`
    FOREIGN KEY (`producto_id`) REFERENCES `productos`(`id`);

ALTER TABLE `factura_compra`
  ADD CONSTRAINT `fk_fcompra_proveedor`
    FOREIGN KEY (`proveedor_id`) REFERENCES `proveedores`(`id`),
  ADD CONSTRAINT `fk_fcompra_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`),
  ADD CONSTRAINT `fk_fcompra_tipopago`
    FOREIGN KEY (`tipo_pago_id`) REFERENCES `tipo_pago`(`id`);

ALTER TABLE `detalle_factura_compra`
  ADD CONSTRAINT `fk_detcompra_factura`
    FOREIGN KEY (`factura_compra_id`) REFERENCES `factura_compra`(`id`),
  ADD CONSTRAINT `fk_detcompra_producto`
    FOREIGN KEY (`producto_id`) REFERENCES `productos`(`id`),
  ADD CONSTRAINT `fk_detcompra_bodega`
    FOREIGN KEY (`bodega_id`) REFERENCES `bodegas`(`id`);

ALTER TABLE `devolucion_compra`
  ADD CONSTRAINT `fk_devcom_factura`
    FOREIGN KEY (`factura_compra_id`) REFERENCES `factura_compra`(`id`),
  ADD CONSTRAINT `fk_devcom_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`);

ALTER TABLE `detalle_devolucion_compra`
  ADD CONSTRAINT `fk_detdevcom_devolucion`
    FOREIGN KEY (`devolucion_compra_id`) REFERENCES `devolucion_compra`(`id`),
  ADD CONSTRAINT `fk_detdevcom_detalle`
    FOREIGN KEY (`detalle_factura_compra_id`) REFERENCES `detalle_factura_compra`(`id`);

-- Ventas
ALTER TABLE `clientes`
  ADD CONSTRAINT `fk_cliente_tipodoc`
    FOREIGN KEY (`tipo_documento_id`) REFERENCES `tipo_documento`(`id`),
  ADD CONSTRAINT `fk_cliente_tipoemail`
    FOREIGN KEY (`tipo_email_id`) REFERENCES `tipo_email`(`id`),
  ADD CONSTRAINT `fk_cliente_ciudad`
    FOREIGN KEY (`ciudad_id`) REFERENCES `ciudades`(`id`);

ALTER TABLE `personas`
  ADD CONSTRAINT `fk_persona_cliente`
    FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`);

ALTER TABLE `empresas`
  ADD CONSTRAINT `fk_empresa_cliente`
    FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`);

ALTER TABLE `num_telefonico`
  ADD CONSTRAINT `fk_numtel_cliente`
    FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`);

ALTER TABLE `descuentos_cliente`
  ADD CONSTRAINT `fk_descuento_cliente`
    FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`);

ALTER TABLE `asesores_comerciales`
  ADD CONSTRAINT `fk_asesor_tipodoc`
    FOREIGN KEY (`tipo_documento_id`) REFERENCES `tipo_documento`(`id`),
  ADD CONSTRAINT `fk_asesor_ciudad`
    FOREIGN KEY (`ciudad_id`) REFERENCES `ciudades`(`id`);

ALTER TABLE `asesor_producto`
  ADD CONSTRAINT `fk_asesprod_asesor`
    FOREIGN KEY (`asesor_id`) REFERENCES `asesores_comerciales`(`id`),
  ADD CONSTRAINT `fk_asesprod_producto`
    FOREIGN KEY (`producto_id`) REFERENCES `productos`(`id`);

ALTER TABLE `comisiones_asesor`
  ADD CONSTRAINT `fk_comision_asesor`
    FOREIGN KEY (`asesor_id`) REFERENCES `asesores_comerciales`(`id`);

ALTER TABLE `factura_venta`
  ADD CONSTRAINT `fk_fventa_cliente`
    FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`),
  ADD CONSTRAINT `fk_fventa_asesor`
    FOREIGN KEY (`asesor_id`) REFERENCES `asesores_comerciales`(`id`),
  ADD CONSTRAINT `fk_fventa_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`),
  ADD CONSTRAINT `fk_fventa_tipopago`
    FOREIGN KEY (`tipo_pago_id`) REFERENCES `tipo_pago`(`id`);

ALTER TABLE `detalle_factura_venta`
  ADD CONSTRAINT `fk_detventa_factura`
    FOREIGN KEY (`factura_venta_id`) REFERENCES `factura_venta`(`id`),
  ADD CONSTRAINT `fk_detventa_producto`
    FOREIGN KEY (`producto_id`) REFERENCES `productos`(`id`),
  ADD CONSTRAINT `fk_detventa_bodega`
    FOREIGN KEY (`bodega_id`) REFERENCES `bodegas`(`id`);

ALTER TABLE `devolucion_venta`
  ADD CONSTRAINT `fk_devvta_factura`
    FOREIGN KEY (`factura_venta_id`) REFERENCES `factura_venta`(`id`),
  ADD CONSTRAINT `fk_devvta_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`);

ALTER TABLE `detalle_devolucion_venta`
  ADD CONSTRAINT `fk_detdevvta_devolucion`
    FOREIGN KEY (`devolucion_venta_id`) REFERENCES `devolucion_venta`(`id`),
  ADD CONSTRAINT `fk_detdevvta_detalle`
    FOREIGN KEY (`detalle_factura_venta_id`) REFERENCES `detalle_factura_venta`(`id`);

-- Reglas de negocio
ALTER TABLE `garantias`
  ADD CONSTRAINT `fk_garantia_detventa`
    FOREIGN KEY (`detalle_venta_id`) REFERENCES `detalle_factura_venta`(`id`);

ALTER TABLE `reporte_rotacion_producto`
  ADD CONSTRAINT `fk_rotacion_producto`
    FOREIGN KEY (`producto_id`) REFERENCES `productos`(`id`);

-- Logs (FK nullable, no bloquea si usuario es NULL)
ALTER TABLE `logs`
  ADD CONSTRAINT `fk_log_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`);

