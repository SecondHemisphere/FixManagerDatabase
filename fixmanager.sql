DROP DATABASE IF EXISTS fixmanager;
CREATE DATABASE fixmanager;
USE fixmanager;

CREATE TABLE usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol ENUM('ADMIN','TECNICO','CAJERO') NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE cliente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20) NOT NULL UNIQUE,
    direccion VARCHAR(150)
);

CREATE TABLE equipo_movil (
    id INT AUTO_INCREMENT PRIMARY KEY,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    imei VARCHAR(20) NOT NULL UNIQUE,
    tipo VARCHAR(30) NOT NULL,
    descripcion_danio TEXT,
    cliente_id INT NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES cliente(id)
);

CREATE TABLE recepcion_entrega (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipo_id INT NOT NULL,
    usuario_id INT NOT NULL,
    fecha_recepcion DATETIME DEFAULT CURRENT_TIMESTAMP,
    problema_reportado VARCHAR(255) NOT NULL,
    estado ENUM('RECIBIDO','LISTO','ENTREGADO') DEFAULT 'RECIBIDO',
    FOREIGN KEY (equipo_id) REFERENCES equipo_movil(id),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

CREATE TABLE reparacion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    diagnostico VARCHAR(255) NOT NULL,
    solucion VARCHAR(255) NOT NULL,
    costo_repuestos DECIMAL(10,2) NOT NULL,
    piezas_usadas VARCHAR(255) NOT NULL,
    estado ENUM('PENDIENTE','EN_PROCESO','FINALIZADO') DEFAULT 'PENDIENTE',
    recepcion_id INT NOT NULL UNIQUE,
    usuario_id INT NOT NULL,
    FOREIGN KEY (recepcion_id) REFERENCES recepcion_entrega(id),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

CREATE TABLE factura (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reparacion_id INT NOT NULL UNIQUE, 
    usuario_id INT NOT NULL,
    costo_total DECIMAL(10,2) NOT NULL,
    fecha_emision DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE','PAGADA') DEFAULT 'PENDIENTE',
    observaciones VARCHAR(255),
    metodo_pago ENUM('EFECTIVO','TARJETA','TRANSFERENCIA'),
    FOREIGN KEY (reparacion_id) REFERENCES reparacion(id),
    FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

DELIMITER $$

CREATE TRIGGER trg_reparacion_update
AFTER UPDATE ON reparacion
FOR EACH ROW
BEGIN
    IF NEW.estado = 'FINALIZADO' AND OLD.estado <> 'FINALIZADO' THEN
        UPDATE recepcion_entrega SET estado = 'LISTO' WHERE id = NEW.recepcion_id;
    END IF;
END$$

CREATE TRIGGER trg_factura_after_update
AFTER UPDATE ON factura
FOR EACH ROW
BEGIN
    IF NEW.estado = 'PAGADA' AND OLD.estado <> 'PAGADA' THEN
        UPDATE recepcion_entrega 
        SET estado = 'ENTREGADO' 
        WHERE id = (SELECT recepcion_id FROM reparacion WHERE id = NEW.reparacion_id);
    END IF;
END$$

CREATE TRIGGER trg_factura_prevent_update
BEFORE UPDATE ON factura
FOR EACH ROW
BEGIN
    IF OLD.estado = 'PAGADA' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se permite modificar una factura ya pagada.';
    END IF;
END$$

CREATE TRIGGER trg_factura_prevent_delete
BEFORE DELETE ON factura
FOR EACH ROW
BEGIN
    IF OLD.estado = 'PAGADA' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se permite eliminar una factura pagada.';
    END IF;
END$$

DELIMITER ;

INSERT INTO usuario (nombre, correo, contrasena, rol, activo) VALUES
('Administrador General','admin@fixmanager.com','123456','ADMIN',TRUE),
('Carlos Mendoza','cmendoza@fixmanager.com','123456','TECNICO',TRUE),
('Luis Ramírez','lramirez@fixmanager.com','123456','TECNICO',TRUE),
('Andrea Paredes','aparedes@fixmanager.com','123456','TECNICO',TRUE),
('Ana Torres','atorres@fixmanager.com','123456','CAJERO',TRUE),
('Kevin Sánchez','ksanchez@fixmanager.com','123456','CAJERO',TRUE),
('María Delgado','mdelgado@fixmanager.com','123456','ADMIN',TRUE),
('Jorge Vera','jvera@fixmanager.com','123456','TECNICO',TRUE),
('Paola Cedeño','pcedeno@fixmanager.com','123456','CAJERO',TRUE),
('Usuario Inactivo','test@fixmanager.com','123456','CAJERO',FALSE);

INSERT INTO cliente (nombre, correo, telefono, direccion) VALUES
('Juan Pérez','juan@gmail.com','0998765432','Quito - Centro'),
('María Gómez','maria@gmail.com','0987654321','Guayaquil - Norte'),
('Carlos López','carlos@gmail.com','0976543210','Cuenca - Av. Solano'),
('Ana Torres','ana@gmail.com','0965432109','Machala - Centro'),
('Luis Herrera','luis@gmail.com','0954321098','Loja - Sur'),
('Sofía Vargas','sofia@gmail.com','0943210987','Ambato - Ficoa'),
('Pedro Castillo','pedro@gmail.com','0932109876','Manta - Tarqui'),
('Elena Ruiz','elena@gmail.com','0921098765','Riobamba - Centro'),
('Miguel Díaz','miguel@gmail.com','0910987654','Ibarra - Norte'),
('Valeria Paredes','valeria@gmail.com','0909876543','Esmeraldas - Playa'),
('Ricardo Molina','ricardo@gmail.com','0991122334','Durán - Centro'),
('Daniela Cevallos','daniela@gmail.com','0988877665','Samborondón - Plaza Batán'),
('Javier Romero','javier@gmail.com','0977412589','Quito - Carcelén'),
('Fernanda Silva','fernanda@gmail.com','0966321458','Milagro - Norte'),
('Cristian León','cristian@gmail.com','0958741236','Babahoyo - Centro');

INSERT INTO equipo_movil (marca, modelo, imei, tipo, descripcion_danio, cliente_id) VALUES
('Samsung','A12','356789123456789','Celular','Pantalla rota',1),
('Xiaomi','Redmi Note 10','356789123456780','Celular','No enciende',2),
('iPhone','11','356789123456781','Celular','Batería dañada',3),
('Huawei','P30','356789123456782','Celular','Puerto dañado',4),
('Motorola','G20','356789123456783','Celular','Golpe lateral',5),
('Samsung','S21','356789123456784','Celular','Pantalla negra',6),
('iPhone','13 Pro','356789123456785','Celular','No carga batería',7),
('Xiaomi','Poco X3','356789123456786','Celular','Daño por humedad',8),
('Huawei','Y9','356789123456787','Celular','Micrófono dañado',9),
('Motorola','Edge 20','356789123456788','Celular','Reinicios constantes',10);

INSERT INTO recepcion_entrega (equipo_id, usuario_id, problema_reportado) VALUES
(1,5,'Pantalla no responde'),
(2,6,'No enciende'),
(3,5,'Batería baja'),
(4,9,'Puerto dañado'),
(5,5,'Golpe fuerte'),
(6,6,'Pantalla negra'),
(7,9,'No carga'),
(8,5,'Daño por humedad'),
(9,6,'Micrófono no funciona'),
(10,9,'Reinicios constantes');

INSERT INTO reparacion (diagnostico, solucion, costo_repuestos, piezas_usadas, estado, recepcion_id, usuario_id) VALUES
('Pantalla dañada','Cambio pantalla',45.00,'LCD','EN_PROCESO',1,2),
('Falla placa','Reparación de placa',60.00,'chips','EN_PROCESO',2,3),
('Batería defectuosa','Cambio batería',25.00,'batería','PENDIENTE',3,4),
('Puerto dañado','Cambio puerto',30.00,'USB-C','EN_PROCESO',4,2),
('Daño por golpe','Reemplazo flex',40.00,'flex encendido','EN_PROCESO',5,8),
('Pantalla rota','Cambio display',80.00,'AMOLED','PENDIENTE',6,3),
('No carga','Limpieza pin carga',20.00,'pin','EN_PROCESO',7,4),
('Humedad','Limpieza interna',50.00,'químicos','PENDIENTE',8,8),
('Micrófono dañado','Cambio micrófono',18.00,'micrófono','EN_PROCESO',9,2),
('Software','Reinstalación sistema',15.00,'software','EN_PROCESO',10,3);

UPDATE reparacion SET estado = 'FINALIZADO' WHERE id IN (1, 4, 9, 10);

INSERT INTO factura (reparacion_id, usuario_id, costo_total, estado, observaciones, metodo_pago) VALUES
(1,5,75.00,'PENDIENTE','OK','EFECTIVO'),
(4,5,55.00,'PENDIENTE','OK','EFECTIVO');

UPDATE factura SET estado = 'PAGADA' WHERE id = 1;

SELECT * FROM usuario;