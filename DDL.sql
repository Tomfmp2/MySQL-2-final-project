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
