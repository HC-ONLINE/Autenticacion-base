SET FOREIGN_KEY_CHECKS = 0;

-- Asegurar que las vistas no generen conflictos antes de recrear tablas
DROP VIEW IF EXISTS vista_nomina_detallada;
DROP VIEW IF EXISTS vista_empleados;

-- Eliminar tablas para mantener definiciones consistentes
DROP TABLE IF EXISTS transacciones_nomina;
DROP TABLE IF EXISTS pagos_nomina;
DROP TABLE IF EXISTS novedades;
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS nomina;
DROP TABLE IF EXISTS periodo_nomina;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS empresa;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS = 1;

-- ========================================
-- TABLA DE ROLES (Normalización)
-- ========================================
CREATE TABLE IF NOT EXISTS roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS empresa (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nit VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    tipo ENUM('natural', 'juridica') DEFAULT 'juridica',
    representante VARCHAR(150),
    direccion TEXT,
    telefono VARCHAR(20),
    email VARCHAR(100),
    estado ENUM('activa', 'inactiva', 'suspendida') DEFAULT 'activa',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_nit (nit),
    INDEX idx_nombre (nombre),
    INDEX idx_estado (estado)
);

-- ========================================
-- TABLA USUARIOS
-- ========================================
CREATE TABLE IF NOT EXISTS usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    -- Datos de autenticación
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,

    -- Datos personales
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    documento VARCHAR(20) NOT NULL UNIQUE,
    tipo_documento ENUM('CC', 'CE', 'PP', 'TI') DEFAULT 'CC',
    fecha_nacimiento DATE,
    edad INT,
    genero ENUM('Masculino', 'Femenino', 'Otro', 'Prefiero no decirlo') DEFAULT 'Masculino',
    telefono VARCHAR(20),
    direccion TEXT,
    
    -- Datos laborales
    salario_base DECIMAL(12,2),
    cargo VARCHAR(100),
    fecha_inicio_contrato DATE,
    fecha_fin_contrato DATE,
    tipo_contrato ENUM('indefinido', 'fijo', 'obra_labor', 'prestacion_servicios') DEFAULT 'indefinido',
    
    -- Relaciones
    id_empresa INT NOT NULL,
    id_rol INT NOT NULL,
    
    -- Control
    estado ENUM('activo', 'inactivo', 'suspendido', 'retirado') DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    FOREIGN KEY (id_empresa) REFERENCES empresa(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_rol) REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_email (email),
    INDEX idx_documento (documento),
    INDEX idx_empresa (id_empresa),
    INDEX idx_rol (id_rol),
    INDEX idx_estado (estado),
    INDEX idx_nombre_apellido (nombre, apellido)
);

-- ========================================
-- TABLA PERIODO NOMINA
-- ========================================
CREATE TABLE IF NOT EXISTS periodo_nomina (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    descripcion VARCHAR(100),
    estado ENUM('abierto', 'cerrado', 'procesado') DEFAULT 'abierto',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_fechas (fecha_inicio, fecha_fin),
    INDEX idx_estado (estado)
);

-- ========================================
-- TABLA NOMINA
-- ========================================
CREATE TABLE IF NOT EXISTS nomina (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_periodo INT NOT NULL,
    id_empleado INT NOT NULL,
    sueldo_base_periodo DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_devengados DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_deducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
    pago_neto DECIMAL(12,2) NOT NULL DEFAULT 0,
    
    -- Campos calculados adicionales
    horas_trabajadas DECIMAL(8,2) DEFAULT 0,
    horas_extras DECIMAL(8,2) DEFAULT 0,
    valor_hora_extra DECIMAL(10,2) DEFAULT 0,
    
    -- Control
    estado ENUM('borrador', 'procesada', 'pagada', 'anulada') DEFAULT 'borrador',
    fecha_procesamiento TIMESTAMP NULL,
    fecha_pago TIMESTAMP NULL,
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    FOREIGN KEY (id_periodo) REFERENCES periodo_nomina(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_empleado) REFERENCES usuarios(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Restricción única
    UNIQUE KEY unique_nomina_periodo_empleado (id_periodo, id_empleado),
    
    -- Índices
    INDEX idx_periodo (id_periodo),
    INDEX idx_empleado (id_empleado),
    INDEX idx_estado (estado),
    INDEX idx_fecha_procesamiento (fecha_procesamiento)
);

-- ========================================
-- TABLA TRANSACCIONES NOMINA
-- ========================================
CREATE TABLE IF NOT EXISTS transacciones_nomina (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_nomina INT NOT NULL,
    tipo_transaccion ENUM('devengado', 'deduccion') NOT NULL,
    sub_tipo VARCHAR(50) NOT NULL, -- Ej: salario_base, horas_extras, eps, pension, etc.
    monto DECIMAL(12,2) NOT NULL,
    descripcion TEXT,
    es_porcentaje BOOLEAN DEFAULT FALSE,
    valor_porcentaje DECIMAL(5,2) DEFAULT 0,
    base_calculo DECIMAL(12,2) DEFAULT 0,
    
    -- Control
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    FOREIGN KEY (id_nomina) REFERENCES nomina(id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_nomina (id_nomina),
    INDEX idx_tipo_transaccion (tipo_transaccion),
    INDEX idx_sub_tipo (sub_tipo)
);

-- ========================================
-- TABLA PAGOS NOMINA
-- ========================================
CREATE TABLE IF NOT EXISTS pagos_nomina (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_nomina INT NOT NULL,
    fecha_pago DATE NOT NULL,
    pago_neto DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM('transferencia', 'cheque', 'efectivo', 'consignacion') DEFAULT 'transferencia',
    numero_referencia VARCHAR(100),
    banco VARCHAR(100),
    numero_cuenta VARCHAR(30),
    
    -- Control
    estado ENUM('pendiente', 'procesado', 'fallido', 'reversado') DEFAULT 'pendiente',
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    FOREIGN KEY (id_nomina) REFERENCES nomina(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_nomina (id_nomina),
    INDEX idx_fecha_pago (fecha_pago),
    INDEX idx_estado (estado),
    INDEX idx_metodo_pago (metodo_pago)
);

-- ========================================
-- TABLA NOVEDADES
-- ========================================
CREATE TABLE IF NOT EXISTS novedades (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_nomina INT NOT NULL,
    fecha DATE NOT NULL,
    tipo_novedad ENUM('incapacidad', 'vacaciones', 'permiso', 'licencia', 'ausencia', 'hora_extra', 'recargo_nocturno', 'festivo', 'otro') NOT NULL,
    detalle TEXT NOT NULL,
    valor_monetario DECIMAL(12,2) DEFAULT 0,
    horas_cantidad DECIMAL(8,2) DEFAULT 0,
    dias_cantidad INT DEFAULT 0,
    
    -- Control y aprobaciones
    estado ENUM('pendiente', 'aprobada', 'rechazada', 'procesada') DEFAULT 'pendiente',
    aprobado_por INT NULL,
    fecha_aprobacion TIMESTAMP NULL,
    observaciones_aprobacion TEXT,
    
    -- Archivos adjuntos
    archivo_soporte VARCHAR(255),
    
    -- Control
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    FOREIGN KEY (id_nomina) REFERENCES nomina(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (aprobado_por) REFERENCES usuarios(id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_nomina (id_nomina),
    INDEX idx_fecha (fecha),
    INDEX idx_tipo_novedad (tipo_novedad),
    INDEX idx_estado (estado),
    INDEX idx_aprobado_por (aprobado_por)
);

-- ========================================
-- TABLA VENTAS
-- ========================================
CREATE TABLE IF NOT EXISTS ventas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_empleado INT NOT NULL,
    fecha_venta DATE NOT NULL,
    total_venta DECIMAL(12,2) NOT NULL,
    comision_porcentaje DECIMAL(5,2) DEFAULT 0,
    comision_valor DECIMAL(12,2) DEFAULT 0,
    detalle TEXT,
    
    -- Control
    estado ENUM('activa', 'anulada', 'devuelta') DEFAULT 'activa',
    numero_factura VARCHAR(50),
    cliente VARCHAR(200),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    FOREIGN KEY (id_empleado) REFERENCES usuarios(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_empleado (id_empleado),
    INDEX idx_fecha_venta (fecha_venta),
    INDEX idx_estado (estado),
    INDEX idx_numero_factura (numero_factura)
);

-- ========================================
-- DATOS INICIALES
-- ========================================

INSERT IGNORE INTO roles (nombre, descripcion) VALUES
('admin', 'Acceso total al sistema'),
('usuario', 'Acceso limitado para tareas específicas'),
('empleado', 'Acceso básico para consultar información personal');

INSERT IGNORE INTO empresa (nit, nombre, tipo, representante, direccion, telefono, email) VALUES
('900123456-7', 'Empresa Ejemplo S.A.S', 'juridica', 'Juan Pérez Martínez', 'Calle 123 #45-67, Bogotá', '+57 1 2345678', 'contacto@empresa.com');

-- Insertar usuarios de ejemplo
INSERT IGNORE INTO usuarios (
    email, password, nombre, apellido, documento, tipo_documento,
    fecha_nacimiento, genero, telefono, direccion, salario_base, cargo,
    fecha_inicio_contrato, tipo_contrato, id_empresa, id_rol, estado
) VALUES 
-- Usuario administrador
(
    'admin@empresa.com', 
    '123456', -- password
    'Administrador', 
    'Sistema', 
    '12345678', 
    'CC',
    '1990-01-01', 
    'Masculino', 
    '+57 300 1234567', 
    'Dirección administrativa', 
    5000000.00, 
    'Administrador de Sistema',
    '2025-01-01', 
    'indefinido', 
    1, 
    1, 
    'activo'
),
-- Usuario empleado de ejemplo
(
    'empleado@empresa.com',
    '123456', -- password
    'María',
    'González',
    '87654321',
    'CC',
    '1985-05-15',
    'Femenino',
    '+57 310 9876543',
    'Carrera 45 #12-34',
    2500000.00,
    'Desarrollador',
    '2025-01-15',
    'indefinido',
    1,
    3,
    'activo'
),
-- Usuario supervisor de ejemplo  
(
    'supervisor@empresa.com',
    '123456', -- password
    'Carlos',
    'Rodríguez', 
    '11223344',
    'CC',
    '1980-03-22',
    'Masculino',
    '+57 320 5551234',
    'Avenida 68 #25-45',
    3800000.00,
    'Supervisor de Área',
    '2024-06-01',
    'indefinido',
    1,
    2,
    'activo'
);

-- Insertar período de nómina de ejemplo
INSERT IGNORE INTO periodo_nomina (fecha_inicio, fecha_fin, descripcion, estado) VALUES
('2025-10-01', '2025-10-31', 'Período Octubre 2025', 'abierto'),
('2025-09-01', '2025-09-30', 'Período Septiembre 2025', 'cerrado');

-- Insertar nóminas de ejemplo
INSERT IGNORE INTO nomina (id_periodo, id_empleado, sueldo_base_periodo, horas_trabajadas, estado) VALUES
(1, 1, 5000000.00, 176.00, 'borrador'),
(1, 2, 2500000.00, 176.00, 'borrador'),
(1, 3, 3800000.00, 184.00, 'borrador'); -- Supervisor con horas extras

-- Insertar transacciones de nómina de ejemplo
INSERT IGNORE INTO transacciones_nomina (id_nomina, tipo_transaccion, sub_tipo, monto, descripcion) VALUES
-- Transacciones para administrador (nómina ID 1)
(1, 'devengado', 'salario_base', 5000000.00, 'Salario base mensual'),
(1, 'deduccion', 'salud', 200000.00, 'Aporte EPS 4%'),
(1, 'deduccion', 'pension', 200000.00, 'Aporte pensión 4%'),
-- Transacciones para empleado (nómina ID 2)  
(2, 'devengado', 'salario_base', 2500000.00, 'Salario base mensual'),
(2, 'deduccion', 'salud', 100000.00, 'Aporte EPS 4%'),
(2, 'deduccion', 'pension', 100000.00, 'Aporte pensión 4%'),
-- Transacciones para supervisor (nómina ID 3)
(3, 'devengado', 'salario_base', 3800000.00, 'Salario base mensual'),
(3, 'devengado', 'horas_extras', 120000.00, 'Pago 8 horas extras'),
(3, 'deduccion', 'salud', 152000.00, 'Aporte EPS 4%'),
(3, 'deduccion', 'pension', 152000.00, 'Aporte pensión 4%');

-- ========================================
-- TRIGGERS PARA CÁLCULOS AUTOMÁTICOS
-- ========================================

DROP TRIGGER IF EXISTS tr_calcular_totales_nomina;
CREATE TRIGGER tr_calcular_totales_nomina 
BEFORE UPDATE ON nomina
FOR EACH ROW
SET 
    NEW.total_devengados = (
        SELECT COALESCE(SUM(monto), 0)
        FROM transacciones_nomina
        WHERE id_nomina = NEW.id AND tipo_transaccion = 'devengado'
    ),
    NEW.total_deducciones = (
        SELECT COALESCE(SUM(monto), 0)
        FROM transacciones_nomina
        WHERE id_nomina = NEW.id AND tipo_transaccion = 'deduccion'
    ),
    NEW.pago_neto = (
        SELECT COALESCE(SUM(monto), 0)
        FROM transacciones_nomina
        WHERE id_nomina = NEW.id AND tipo_transaccion = 'devengado'
    ) - (
        SELECT COALESCE(SUM(monto), 0)
        FROM transacciones_nomina
        WHERE id_nomina = NEW.id AND tipo_transaccion = 'deduccion'
    );

DROP TRIGGER IF EXISTS tr_actualizar_edad_usuario;
CREATE TRIGGER tr_actualizar_edad_usuario
BEFORE INSERT ON usuarios
FOR EACH ROW
SET NEW.edad = CASE
    WHEN NEW.fecha_nacimiento IS NOT NULL THEN TIMESTAMPDIFF(YEAR, NEW.fecha_nacimiento, CURDATE())
    ELSE NEW.edad
END;

DROP TRIGGER IF EXISTS tr_actualizar_edad_usuario_update;
CREATE TRIGGER tr_actualizar_edad_usuario_update
BEFORE UPDATE ON usuarios
FOR EACH ROW
SET NEW.edad = CASE
    WHEN NEW.fecha_nacimiento IS NOT NULL THEN TIMESTAMPDIFF(YEAR, NEW.fecha_nacimiento, CURDATE())
    ELSE NEW.edad
END;

-- ========================================
-- VISTAS ÚTILES
-- ========================================

DROP VIEW IF EXISTS vista_empleados;
CREATE VIEW vista_empleados AS
SELECT 
    u.id,
    u.nombre,
    u.apellido,
    CONCAT(u.nombre, ' ', u.apellido) AS nombre_completo,
    u.documento,
    u.tipo_documento,
    u.email,
    u.telefono,
    u.cargo,
    u.salario_base,
    u.fecha_inicio_contrato,
    u.fecha_fin_contrato,
    u.tipo_contrato,
    u.estado,
    e.nombre AS empresa,
    r.nombre AS rol
FROM usuarios u
JOIN empresa e ON u.id_empresa = e.id
JOIN roles r ON u.id_rol = r.id;

DROP VIEW IF EXISTS vista_nomina_detallada;
CREATE VIEW vista_nomina_detallada AS
SELECT 
    n.id,
    p.fecha_inicio,
    p.fecha_fin,
    CONCAT(u.nombre, ' ', u.apellido) AS empleado,
    u.documento,
    u.cargo,
    n.sueldo_base_periodo,
    n.total_devengados,
    n.total_deducciones,
    n.pago_neto,
    n.estado,
    n.fecha_procesamiento,
    n.fecha_pago
FROM nomina n
JOIN periodo_nomina p ON n.id_periodo = p.id
JOIN usuarios u ON n.id_empleado = u.id;

-- ========================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- ========================================

CREATE INDEX idx_usuario_empresa_estado ON usuarios(id_empresa, estado);
CREATE INDEX idx_nomina_periodo_estado ON nomina(id_periodo, estado);
CREATE INDEX idx_transacciones_nomina_tipo ON transacciones_nomina(id_nomina, tipo_transaccion);
CREATE INDEX idx_novedades_fecha_estado ON novedades(fecha, estado);
CREATE INDEX idx_ventas_empleado_fecha ON ventas(id_empleado, fecha_venta);
