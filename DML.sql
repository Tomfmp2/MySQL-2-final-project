-- ==========================================================
-- 1. INSERTS DE DATOS MAESTROS
-- ==========================================================

INSERT INTO `ciudades` (`nombre`) VALUES
  ('Barranquilla'),
  ('Cali'),
  ('Medellín'),
  ('Bucaramanga'),
  ('Bogotá');

INSERT INTO `tipo_documento` (`tipo`) VALUES
  ('Cédula de Ciudadanía'),
  ('Cédula de Extranjería'),
  ('NIT'),
  ('Pasaporte'),
  ('RUT');

INSERT INTO `tipo_email` (`tipo`) VALUES
  ('gmail.com'),
  ('hotmail.com'),
  ('outlook.com'),
  ('yahoo.com'),
  ('acme.com.co');

INSERT INTO `tipo_pago` (`nombre`) VALUES
  ('Efectivo'),
  ('Transferencia Bancaria'),
  ('Tarjeta Débito'),
  ('Tarjeta Crédito'),
  ('PSE');

INSERT INTO `modulos` (`nombre`, `descripcion`) VALUES
  ('SEGURIDAD',  'Gestión de usuarios, roles y permisos'),
  ('INVENTARIO', 'Gestión de productos, categorías y bodegas'),
  ('COMPRAS',    'Gestión de proveedores y facturas de compra'),
  ('VENTAS',     'Gestión de clientes, asesores y facturas de venta'),
  ('REPORTES',   'Generación de reportes y estadísticas');

INSERT INTO `roles` (`nombre`, `descripcion`, `estado`) VALUES
  ('Administrador',          'Acceso total al sistema',                              '1'),
  ('Coordinador de Ventas',  'Acceso completo al módulo de ventas',                  '1'),
  ('Asesor Comercial',       'Facturación, devoluciones y clientes; sin eliminar',   '1'),
  ('Encargado Inventario',   'Acceso total al módulo de inventario y bodegas',       '1'),
  ('Auxiliar Inventario',    'Registro de productos y categorías',                   '1'),
  ('Gerente de Compras',     'Acceso total al módulo de compras',                    '1'),
  ('Auxiliar de Compras',    'Registro de facturas de compra y devoluciones',        '1');

INSERT INTO `permisos`
  (`modulo_id`, `nombre`, `descripcion`, `lectura`, `escritura`, `actualizacion`, `eliminacion`)
VALUES
  -- SEGURIDAD
  (1, 'SEG_TOTAL',     'Acceso total seguridad',             1, 1, 1, 1),
  (1, 'SEG_LECTURA',   'Solo lectura seguridad',             1, 0, 0, 0),
  -- INVENTARIO
  (2, 'INV_TOTAL',     'Acceso total inventario',            1, 1, 1, 1),
  (2, 'INV_ESCRITURA', 'Crear productos y categorías',       1, 1, 0, 0),
  (2, 'INV_LECTURA',   'Solo lectura inventario',            1, 0, 0, 0),
  -- COMPRAS
  (3, 'COMP_TOTAL',    'Acceso total compras',               1, 1, 1, 1),
  (3, 'COMP_ESCRITURA','Registrar facturas y devoluciones',  1, 1, 0, 0),
  (3, 'COMP_LECTURA',  'Solo lectura compras',               1, 0, 0, 0),
  -- VENTAS
  (4, 'VTA_TOTAL',     'Acceso total ventas',                1, 1, 1, 1),
  (4, 'VTA_ESCRITURA', 'Crear facturas, clientes',           1, 1, 1, 0),
  (4, 'VTA_LECTURA',   'Solo lectura ventas',                1, 0, 0, 0),
  -- REPORTES
  (5, 'REP_TOTAL',     'Acceso total reportes',              1, 1, 1, 1),
  (5, 'REP_LECTURA',   'Solo lectura reportes',              1, 0, 0, 0);

-- Asignar permisos a roles
INSERT INTO `rol_permiso` (`rol_id`, `permiso_id`) VALUES
  -- Administrador: todo
  (1, 1),(1, 3),(1, 6),(1, 9),(1, 12),
  -- Coordinador de Ventas: ventas total + reportes
  (2, 9),(2, 13),
  -- Asesor Comercial: ventas escritura (sin eliminar) + inventario lectura
  (3, 10),(3, 5),
  -- Encargado Inventario: inventario total + compras lectura
  (4, 3),(4, 8),
  -- Auxiliar Inventario: inventario escritura
  (5, 4),
  -- Gerente de Compras: compras total + inventario lectura + reportes
  (6, 6),(6, 5),(6, 13),
  -- Auxiliar de Compras: compras escritura + compras lectura
  (7, 7),(7, 8);

INSERT INTO `categoria` (`tipo`) VALUES
  ('Procesadores'),
  ('Memorias RAM'),
  ('Almacenamiento SSD'),
  ('Almacenamiento HDD'),
  ('Tarjetas Gráficas'),
  ('Placas Base'),
  ('Fuentes de Poder'),
  ('Refrigeración'),
  ('Periféricos'),
  ('Redes y Conectividad');

INSERT INTO `bodegas`
  (`codigo`, `nombre`, `descripcion`, `ciudad_id`, `direccion`, `cantidad_maxima`, `estado`)
VALUES
  ('BOD-BAQ-01', 'Bodega Barranquilla', 'Sede principal Barranquilla', 1, 'Cra 46 #72-50',     5000, '1'),
  ('BOD-CAL-01', 'Bodega Cali',         'Sede Cali',                   2, 'Av 6N #23-45',      4000, '1'),
  ('BOD-MED-01', 'Bodega Medellín',     'Sede Medellín',               3, 'Cra 80 #34-10',     4500, '1'),
  ('BOD-BUC-01', 'Bodega Bucaramanga',  'Sede Bucaramanga',            4, 'Cll 35 #28-60',     3000, '1'),
  ('BOD-BOG-01', 'Bodega Bogotá',       'Sede Bogotá',                 5, 'Ak 68 #13-09',      6000, '1');

INSERT INTO `proveedores`
  (`tipo_documento_id`, `num_documento`, `razon_social`, `direccion`, `ciudad_id`, `telefono`, `email`, `estado`)
VALUES
  (3, '900123456-1', 'Tech Distribuciones S.A.',   'Cll 72 #50-21', 1, '6017001122', 'ventas@techdist.com',    '1'),
  (3, '800987654-2', 'Global Hardware Ltda.',       'Cra 15 #93-40', 5, '6014005566', 'compras@globalhw.com',  '1'),
  (4, 'US-TEC-001',  'Samsung Electronics Co.',     'Seoul, Korea',  5, '6014009900', 'b2b@samsung.com',       '1'),
  (4, 'US-TEC-002',  'Kingston Technology Corp.',   'California US', 1, '6017008800', 'sales@kingston.com',    '1'),
  (3, '901234567-3', 'Soluciones PC Colombia S.A.', 'Av El Dorado',  5, '6013007744', 'info@solucionespc.com', '1');

INSERT INTO `productos`
  (`codigo`, `nombre`, `descripcion`, `categoria_id`, `porcentaje_utilidad`,
   `valor_compra`, `valor_venta`, `iva`, `estado`)
VALUES
  ('PRD-001', 'Procesador Intel Core i9',   'Intel Core i9-13900K 24 núcleos 5.8GHz', 1, 15.00, 2500000, 2875000, 19.00, '1'),
  ('PRD-002', 'Procesador AMD Ryzen 9',     'AMD Ryzen 9 7950X 16 núcleos 5.7GHz',   1, 15.00, 2200000, 2530000, 19.00, '1'),
  ('PRD-003', 'Memoria RAM DDR5 32GB',      'Kingston Fury Beast DDR5 32GB 6000MHz', 2, 20.00,  650000,  780000, 19.00, '1'),
  ('PRD-004', 'Memoria RAM DDR4 16GB',      'Samsung 16GB DDR4 3200MHz CL16',        2, 20.00,  280000,  336000, 19.00, '1'),
  ('PRD-005', 'SSD NVMe 1TB',               'Samsung 970 EVO Plus 1TB M.2 NVMe',     3, 18.00,  450000,  531000, 19.00, '1'),
  ('PRD-006', 'SSD SATA 500GB',             'Kingston A400 500GB SATA III',           3, 18.00,  210000,  247800, 19.00, '1'),
  ('PRD-007', 'HDD 2TB',                    'Seagate Barracuda 2TB 7200RPM',          4, 12.00,  280000,  313600,  0.00, '1'),
  ('PRD-008', 'Tarjeta Gráfica RTX 4070',   'NVIDIA GeForce RTX 4070 12GB GDDR6X',   5, 20.00, 3800000, 4560000, 19.00, '1'),
  ('PRD-009', 'Placa Base ATX Z790',        'ASUS ROG Strix Z790-E Gaming WiFi',      6, 18.00, 1500000, 1770000, 19.00, '1'),
  ('PRD-010', 'Fuente 850W 80+ Gold',       'Corsair RM850x 850W Modular',            7, 15.00,  750000,  862500, 19.00, '1');

INSERT INTO `inventario` (`producto_id`, `bodega_id`, `cantidad`) VALUES
  (1, 1, 20),(1, 5, 15),
  (2, 1, 18),(2, 5, 12),
  (3, 1, 50),(3, 2, 30),(3, 5, 40),
  (4, 1, 80),(4, 3, 60),(4, 5, 70),
  (5, 1, 45),(5, 4, 25),(5, 5, 35),
  (6, 2, 60),(6, 3, 40),
  (7, 1, 30),(7, 2, 20),(7, 5, 25),
  (8, 1, 10),(8, 5,  8),
  (9, 1, 15),(9, 5, 10),
  (10,1, 25),(10,3, 20);

INSERT INTO `proveedor_producto` (`proveedor_id`, `producto_id`) VALUES
  (1,1),(1,2),(1,9),(1,10),
  (2,7),(2,8),(2,9),
  (3,3),(3,4),(3,5),
  (4,3),(4,4),(4,6),
  (5,1),(5,2),(5,5),(5,6),(5,7);

INSERT INTO `clientes`
  (`tipo_documento_id`, `num_documento`, `nombre_email`, `tipo_email_id`,
   `direccion`, `ciudad_id`, `genero`, `estado`)
VALUES
  (1, '1098765432', 'jperez',      1, 'Cll 45 #23-10', 4, 'M', '1'),
  (1, '1087654321', 'amarinez',    2, 'Cra 33 #12-50', 5, 'F', '1'),
  (1, '1076543210', 'cgomez',      1, 'Av 30 #15-20',  3, 'M', '1'),
  (1, '1065432109', 'lrodriguez',  3, 'Cll 10 #8-45',  1, 'F', '1'),
  (3, '900111222-1','techcorp',    5, 'Cra 7 #32-18',  5,  NULL,'1'),
  (3, '900333444-2','innovatech',  5, 'Ak 19 #100-21', 5,  NULL,'1');

INSERT INTO `personas` (`cliente_id`, `nombre`, `apellido`) VALUES
  (1, 'Juan',   'Pérez'),
  (2, 'Andrea', 'Martínez'),
  (3, 'Carlos', 'Gómez'),
  (4, 'Laura',  'Rodríguez');

INSERT INTO `empresas` (`cliente_id`, `nombre`, `representante`) VALUES
  (5, 'TechCorp Colombia S.A.S.',  'Roberto Salcedo'),
  (6, 'InnovaTech Ltda.',          'Patricia Herrera');

INSERT INTO `num_telefonico` (`telefono`, `cliente_id`) VALUES
  ('3001234567', 1),
  ('3109876543', 2),
  ('3205551234', 3),
  ('3158889900', 4),
  ('6017001100', 5),
  ('6013002200', 6);

INSERT INTO `asesores_comerciales`
  (`tipo_documento_id`, `num_documento`, `razon_social`, `direccion`,
   `ciudad_id`, `telefono`, `email`, `estado`)
VALUES
  (1, '80123456', 'Carlos Mendoza Ruiz',    'Cll 90 #15-30', 5, '3001112233', 'cmendoza@acme.com.co',  '1'),
  (1, '52987654', 'Diana Torres Vargas',    'Cra 11 #65-20', 5, '3114445566', 'dtorres@acme.com.co',   '1'),
  (1, '71234567', 'Miguel Castillo Parra',  'Av 68 #22-18',  5, '3127778899', 'mcastillo@acme.com.co', '1');

INSERT INTO `asesor_producto` (`asesor_id`, `producto_id`) VALUES
  (1,1),(1,2),(1,8),(1,9),
  (2,3),(2,4),(2,5),(2,6),
  (3,7),(3,10),(3,3),(3,1);

INSERT INTO `usuarios`
  (`rol_principal_id`, `tipo_documento_id`, `num_documento`, `nombres`, `apellidos`,
   `direccion`, `ciudad_id`, `telefono`, `email_personal`, `email_corporativo`,
   `password_hash`, `estado`)
VALUES
  (1, 1, '12345678',  'Admin',    'Sistema',    'Cll 1 #1-1',    5, '3000000001',
   'admin@gmail.com',       'admin@acme.com.co',
   '$2b$12$placeholder_hash_admin',    '1'),

  (2, 1, '23456789',  'Sofía',    'López',      'Cra 50 #20-30', 5, '3011234567',
   'slopez@gmail.com',      'slopez@acme.com.co',
   '$2b$12$placeholder_hash_coord',    '1'),

  (3, 1, '34567890',  'Andrés',   'Mora',       'Cll 80 #10-15', 4, '3022345678',
   'amora@hotmail.com',     'amora@acme.com.co',
   '$2b$12$placeholder_hash_asesor',   '1'),

  (4, 1, '45678901',  'Patricia', 'Suárez',     'Av Norte #5-20',3, '3033456789',
   'psuarez@outlook.com',   'psuarez@acme.com.co',
   '$2b$12$placeholder_hash_inv',      '1'),

  (6, 1, '56789012',  'Hernán',   'Ríos',       'Cra 15 #33-40', 1, '3044567890',
   'hrios@gmail.com',       'hrios@acme.com.co',
   '$2b$12$placeholder_hash_gcompras', '1');

INSERT INTO `usuario_rol` (`usuario_id`, `rol_id`) VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (4, 4),
  (5, 6);

INSERT INTO `factura_compra`
  (`proveedor_id`, `usuario_id`, `fecha`, `tipo_pago_id`, `num_factura`, `estado`)
VALUES
  (1, 5, '2026-01-10 09:00:00', 2, 'FC-2026-001', '1'),
  (3, 5, '2026-01-15 10:30:00', 2, 'FC-2026-002', '1'),
  (2, 5, '2026-02-05 08:45:00', 1, 'FC-2026-003', '1');

INSERT INTO `detalle_factura_compra`
  (`factura_compra_id`, `producto_id`, `bodega_id`, `cantidad`, `valor_unitario`, `iva`)
VALUES
  (1, 1, 1, 10, 2500000, 19.00),
  (1, 2, 1,  8, 2200000, 19.00),
  (2, 3, 5, 20,  650000, 19.00),
  (2, 4, 5, 30,  280000, 19.00),
  (3, 8, 1,  5, 3800000, 19.00),
  (3, 7, 2, 15,  280000,  0.00);

INSERT INTO `factura_venta`
  (`cliente_id`, `asesor_id`, `usuario_id`, `fecha`, `tipo_pago_id`,
   `num_factura`, `descuento_porcentaje`, `estado`)
VALUES
  (1, 1, 3, '2026-01-20 14:00:00', 1, 'FV-2026-001', 0.00, '1'),
  (5, 2, 2, '2026-01-25 10:00:00', 2, 'FV-2026-002', 5.00, '1'),
  (2, 3, 3, '2026-02-10 16:30:00', 5, 'FV-2026-003', 0.00, '1');

INSERT INTO `detalle_factura_venta`
  (`factura_venta_id`, `producto_id`, `bodega_id`, `cantidad`, `valor_unitario`, `iva`)
VALUES
  (1, 3, 1, 2,  780000, 19.00),
  (1, 6, 2, 1,  247800, 19.00),
  (2, 1, 1, 3, 2875000, 19.00),
  (2, 8, 1, 2, 4560000, 19.00),
  (3, 4, 5, 4,  336000, 19.00),
  (3, 5, 5, 2,  531000, 19.00);

INSERT INTO `garantias`
  (`detalle_venta_id`, `tipo`, `meses`, `fecha_inicio`, `fecha_fin`)
VALUES
  (1, 'empresa',   3, '2026-01-20', '2026-04-20'),
  (1, 'proveedor',12, '2026-01-20', '2027-01-20'),
  (2, 'empresa',   3, '2026-01-25', '2026-04-25'),
  (2, 'proveedor',12, '2026-01-25', '2027-01-25'),
  (3, 'empresa',   3, '2026-01-25', '2026-04-25'),
  (3, 'proveedor',12, '2026-01-25', '2027-01-25'),
  (4, 'empresa',   3, '2026-01-25', '2026-04-25'),
  (4, 'proveedor',12, '2026-01-25', '2027-01-25'),
  (5, 'empresa',   3, '2026-02-10', '2026-05-10'),
  (5, 'proveedor',12, '2026-02-10', '2027-02-10');

INSERT INTO `descuentos_cliente` (`cliente_id`, `porcentaje`, `monto_minimo`, `activo`) VALUES
  (5, 5.00, 200000000, 1),
  (6, 5.00, 200000000, 1);

INSERT INTO `logs`
  (`usuario_id`, `tabla`, `operacion`, `registro_id`, `descripcion`, `nivel`)
VALUES
  (1, 'usuarios',         'INSERT', 1, 'Usuario administrador creado en el sistema', 'INFO'),
  (5, 'factura_compra',   'INSERT', 1, 'Factura de compra FC-2026-001 registrada',   'INFO'),
  (5, 'factura_compra',   'INSERT', 2, 'Factura de compra FC-2026-002 registrada',   'INFO'),
  (2, 'factura_venta',    'INSERT', 1, 'Factura de venta FV-2026-001 registrada',    'INFO'),
  (2, 'factura_venta',    'INSERT', 2, 'Factura de venta FV-2026-002 registrada',    'INFO'),
  (NULL,'inventario',     'UPDATE', NULL,'Actualización automática de stock por compra FC-2026-001','INFO'),
  (NULL,'detalle_factura_venta','ERROR', NULL,
   'Intento fallido: stock insuficiente producto_id=9 bodega_id=3 solicitado=5 disponible=0','ERROR');
