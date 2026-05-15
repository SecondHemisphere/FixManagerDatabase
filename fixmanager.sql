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
('Administrador General', 'admin@fixmanager.com', 'admin2026', 'ADMIN', TRUE),
('Roberto Anchundia', 'ranchundia@fixmanager.com', 'techguayas2026', 'TECNICO', TRUE),
('Diana Villamar', 'dvillamar@fixmanager.com', 'dvillacaja26', 'CAJERO', TRUE),
('Christian Coello', 'ccoello@fixmanager.com', 'reparaexpress9', 'TECNICO', TRUE),
('Nathaly Barzola', 'nbarzola@fixmanager.com', 'natycaja2026', 'CAJERO', TRUE),
('Geovanny Pincay', 'gpincay@fixmanager.com', 'geotechmaster', 'TECNICO', TRUE);

SET @tecnico1 = (SELECT id FROM usuario WHERE correo = 'ranchundia@fixmanager.com');
SET @cajero1  = (SELECT id FROM usuario WHERE correo = 'dvillamar@fixmanager.com');
SET @tecnico2 = (SELECT id FROM usuario WHERE correo = 'ccoello@fixmanager.com');
SET @cajero2  = (SELECT id FROM usuario WHERE correo = 'nbarzola@fixmanager.com');
SET @tecnico3 = (SELECT id FROM usuario WHERE correo = 'gpincay@fixmanager.com');

INSERT INTO cliente (nombre, correo, telefono, direccion) VALUES
('Jefferson Mendoza', 'jmendoza.ec@gmail.com', '0981234567', 'Guayaquil - Sauces 4, Mz. F2'),
('Glenda Holguín', 'glen_holguin@hotmail.com', '0997654321', 'Guayaquil - Urdesa Central, Av. Las Monjas'),
('Bryan Caicedo', 'bcaicedo99@gmail.com', '0961472583', 'Guayaquil - Alborada 11va Etapa'),
('Estefanía Moreira', 'emoreira_est@outlook.com', '0953698521', 'Duran - Cdla. El Recreo 2da Etapa'),
('Santiago Yánez', 'syanez_tech@gmail.com', '0932581476', 'Guayaquil - Centro, Av. 9 de Octubre y Boyacá'),
('Ingrid Solórzano', 'isolorzano@gmail.com', '0978523641', 'Guayaquil - Mapasingue Oeste, Av. Principal'),
('Kevin Villalta', 'kvillalta.94@gmail.com', '0941239874', 'Guayaquil - Mucho Lote 1, Etapa 2'),
('Roxana Lindao', 'rlindao_c@hotmail.com', '0929874561', 'Guayaquil - Barrio Cuba, Calle El Oro'),
('Marlon Intriago', 'mintriago_eng@gmail.com', '0985214763', 'Samborondón - La Puntilla, Mz. A'),
('Tatiana Bajaña', 'tbajana_makeup@outlook.com', '0963214587', 'Guayaquil - Suburbio, 25 y la Q'),
('Alejandro Giler', 'agiler_99@gmail.com', '0957412369', 'Guayaquil - Kennedy Norte, detrás del Gobierno Zonal');

SET @id_cliente_base = (SELECT id FROM cliente WHERE correo = 'jmendoza.ec@gmail.com');

INSERT INTO equipo_movil (marca, modelo, imei, tipo, descripcion_danio, cliente_id) VALUES
('Samsung', 'Galaxy A54', '359874123654120', 'Celular', 'Pantalla trizada y líneas verdes', @id_cliente_base),
('Apple', 'iPhone 14 Pro', '354125896321475', 'Celular', 'Batería inflada, no pasa del logo', @id_cliente_base + 1),
('Xiaomi', 'Redmi Note 12 Pro', '357412589632144', 'Celular', 'Sufrió caída en líquido (piscina)', @id_cliente_base + 2),
('Samsung', 'Galaxy Tab S8', '352147896325411', 'Tablet', 'Pin de carga tipo C destruido', @id_cliente_base + 3),
('Motorola', 'Moto G84', '358963214752148', 'Celular', 'No da imagen, pero vibra y timbra', @id_cliente_base + 4),
('Honor', 'Magic 5 Lite', '356321478596214', 'Celular', 'Vidrio de cámara posterior roto', @id_cliente_base + 5),
('Infinix', 'Hot 30i', '351478523698412', 'Celular', 'Botón de encendido hundido y trabado', @id_cliente_base + 6),
('Apple', 'iPad Air 5', '359632147854123', 'Tablet', 'No reconoce redes Wi-Fi ni Bluetooth', @id_cliente_base + 7),
('Tecno', 'Pova 5', '354785214796321', 'Celular', 'Se recalienta al cargar y se apaga', @id_cliente_base + 8),
('Xiaomi', 'Poco F5 Pro', '358741236985214', 'Celular', 'Error de software tras actualización fallida', @id_cliente_base + 9),
('Samsung', 'Galaxy S23 Ultra', '352369874125478', 'Celular', 'Tapa trasera de vidrio rota por impacto', @id_cliente_base + 10);

SET @id_equipo_base = (SELECT id FROM equipo_movil WHERE imei = '359874123654120');

INSERT INTO recepcion_entrega (equipo_id, usuario_id, problema_reportado) VALUES
(@id_equipo_base, @cajero1, 'Cambio de módulo de pantalla completo por golpe'),
(@id_equipo_base + 1, @cajero1, 'Cambio de batería de alta calidad y revisión de software'),
(@id_equipo_base + 2, @cajero1, 'Mantenimiento preventivo por humedad y sulfatación'),
(@id_equipo_base + 3, @cajero1, 'Reemplazo de pin de carga soldado a la placa base'),
(@id_equipo_base + 4, @cajero2, 'Diagnóstico de pantalla o posible daño en el flex principal'),
(@id_equipo_base + 5, @cajero2, 'Reemplazo del cristal protector del lente de la cámara'),
(@id_equipo_base + 6, @cajero2, 'Cambio de flex interno de botones de volumen y encendido'),
(@id_equipo_base + 7, @cajero1, 'Revisión de antena IC de Wi-Fi en la placa principal'),
(@id_equipo_base + 8, @cajero2, 'Cambio de puerto de carga y revisión de regulador de voltaje'),
(@id_equipo_base + 9, @cajero1, 'Flasheo de firmware de fábrica por modo brickeo'),
(@id_equipo_base + 10, @cajero2, 'Instalación de tapa trasera original color verde');

SET @id_recepcion_base = (SELECT id FROM recepcion_entrega WHERE equipo_id = @id_equipo_base);

INSERT INTO reparacion (diagnostico, solucion, costo_repuestos, piezas_usadas, estado, recepcion_id, usuario_id) VALUES
('Pantalla OLED rota internamente', 'Instalación de nueva pantalla original', 65.00, 'Pantalla Samsung A54', 'EN_PROCESO', @id_recepcion_base, @tecnico1),
('Batería degradada al 68% con deformación', 'Reemplazo de batería homologada', 30.00, 'Batería iPhone 14P', 'PENDIENTE', @id_recepcion_base + 1, @tecnico2),
('Cortocircuito menor en línea secundaria por agua', 'Baño químico en tina ultrasónica y resoldaje', 15.00, 'Alcohol Isopropílico y Flux', 'EN_PROCESO', @id_recepcion_base + 2, @tecnico1),
('Pistas del pin de carga desprendidas', 'Micro-soldadura de nuevo puerto tipo C', 8.00, 'Puerto Tipo C Genérico', 'PENDIENTE', @id_recepcion_base + 3, @tecnico2),
('Flex de pantalla desconectado tras impacto', 'Limpieza de conectores y sujeción interna', 5.00, 'Cinta térmica de sujeción', 'EN_PROCESO', @id_recepcion_base + 4, @tecnico1),
('Lente protector fisurado', 'Extracción manual del vidrio e instalación de repuesto', 4.00, 'Lente de cámara Honor M5L', 'PENDIENTE', @id_recepcion_base + 5, @tecnico3),
('Flex de encendido roto en la base', 'Reemplazo del componente flex flexor completo', 7.00, 'Flex Power Infinix Hot 30i', 'EN_PROCESO', @id_recepcion_base + 6, @tecnico3),
('Módulo integrado de Wi-Fi desoldado por caída', 'Proceso de reballing al chip de conectividad', 0.00, 'Esferas de estaño y flux', 'PENDIENTE', @id_recepcion_base + 7, @tecnico2),
('IC de carga integrado dañado por cargador genérico', 'Reemplazo del integrado de carga en placa', 12.00, 'Chip IC de carga compatible', 'EN_PROCESO', @id_recepcion_base + 8, @tecnico1),
('Bucle de sistema por partición dañada', 'Carga de sistema operativo vía comandos EDL', 0.00, 'Software / Rom Global Oficial', 'EN_PROCESO', @id_recepcion_base + 9, @tecnico2),
('Tapa de vidrio posterior pulverizada', 'Instalación de tapa con adhesivo industrial B7000', 18.00, 'Tapa trasera S23 Ultra', 'EN_PROCESO', @id_recepcion_base + 10, @tecnico3);

SET @id_reparacion_base = (SELECT id FROM reparacion WHERE recepcion_id = @id_recepcion_base);

UPDATE reparacion SET estado = 'FINALIZADO' WHERE id IN (@id_reparacion_base, @id_reparacion_base + 2, @id_reparacion_base + 4, @id_reparacion_base + 6, @id_reparacion_base + 9);

INSERT INTO factura (reparacion_id, usuario_id, costo_total, estado, observaciones, metodo_pago) VALUES
(@id_reparacion_base, @cajero1, 110.00, 'PENDIENTE', 'Garantía de 3 meses por el módulo de pantalla', 'EFECTIVO'),
(@id_reparacion_base + 1, @cajero1, 55.00, 'PENDIENTE', 'Cliente pasará a retirar el fin de semana', 'TARJETA'),
(@id_reparacion_base + 2, @cajero1, 45.00, 'PENDIENTE', 'Se sugiere usar estuche impermeable', 'TRANSFERENCIA'),
(@id_reparacion_base + 3, @cajero2, 30.00, 'PENDIENTE', 'Pin de carga reforzado con resina epóxica', 'EFECTIVO'),
(@id_reparacion_base + 4, @cajero2, 25.00, 'PENDIENTE', 'Solo requería mano de obra técnica', 'EFECTIVO'),
(@id_reparacion_base + 5, @cajero2, 15.00, 'PENDIENTE', 'Limpieza de sensor fotográfico incluida', 'TRANSFERENCIA'),
(@id_reparacion_base + 6, @cajero1, 25.00, 'PENDIENTE', 'Botones físicos con excelente pulsación', 'EFECTIVO'),
(@id_reparacion_base + 7, @cajero1, 60.00, 'PENDIENTE', 'Trabajo complejo a nivel de placa madre', 'TARJETA'),
(@id_reparacion_base + 8, @cajero2, 40.00, 'PENDIENTE', 'Se recomienda no usar cargadores de imitación', 'TRANSFERENCIA'),
(@id_reparacion_base + 9, @cajero2, 20.00, 'PENDIENTE', 'Datos del usuario borrados por formateo forzado', 'EFECTIVO'),
(@id_reparacion_base + 10, @cajero1, 45.00, 'PENDIENTE', 'Estética trasera recuperada al 100%', 'EFECTIVO');

SET @id_factura_base = (SELECT id FROM factura WHERE reparacion_id = @id_reparacion_base);

UPDATE factura SET estado = 'PAGADA', metodo_pago = 'EFECTIVO' WHERE id IN (@id_factura_base, @id_factura_base + 4, @id_factura_base + 6);
UPDATE factura SET estado = 'PAGADA', metodo_pago = 'TRANSFERENCIA' WHERE id = @id_factura_base + 2;

SELECT * FROM usuario;