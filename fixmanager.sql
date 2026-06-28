DROP DATABASE IF EXISTS fixmanager;
CREATE DATABASE fixmanager;
USE fixmanager;

CREATE TABLE usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol ENUM('ADMIN','RECEPCIONISTA','TECNICO','CAJERO') NOT NULL,
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
    tipo ENUM('CELULAR','TABLET','SMARTWATCH','ACCESORIOS','OTRO') NOT NULL,
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
    costo_servicio DECIMAL(10,2) NOT NULL,
    costo_repuestos DECIMAL(10,2) NOT NULL,
    piezas_usadas VARCHAR(255),
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

CREATE TRIGGER trg_factura_before_insert
BEFORE INSERT ON factura
FOR EACH ROW
BEGIN
    DECLARE v_servicio DECIMAL(10,2);
    DECLARE v_repuestos DECIMAL(10,2);

    SELECT costo_servicio, costo_repuestos
    INTO v_servicio, v_repuestos
    FROM reparacion
    WHERE id = NEW.reparacion_id;

    SET NEW.costo_total = v_servicio + v_repuestos;
END$$

DELIMITER ;

INSERT INTO usuario (nombre, correo, contrasena, rol, activo) VALUES
('Administrador General', 'admin@fixmanager.ec', 'admin2026', 'ADMIN', TRUE),

('Carlos Mena', 'cmena@fixmanager.ec', 'cmn48a2', 'RECEPCIONISTA', TRUE),
('José Almeida', 'jalmeida@fixmanager.ec', 'alm73k1', 'RECEPCIONISTA', TRUE),
('María Quishpe', 'mquishpe@fixmanager.ec', 'qsp91m4', 'RECEPCIONISTA', TRUE),

('Geovanny Pincay', 'gpincay@fixmanager.ec', 'gpc28z7', 'TECNICO', TRUE),
('Christian Coello', 'ccoello@fixmanager.ec', 'col56t3', 'TECNICO', TRUE),
('Roberto Anchundia', 'ranchundia@fixmanager.ec', 'anc84p9', 'TECNICO', TRUE),
('Luis Zambrano', 'lzambrano@fixmanager.ec', 'zbr12m6', 'TECNICO', TRUE),

('Nathaly Barzola', 'nbarzola@fixmanager.ec', 'brz77c2', 'CAJERO', TRUE),
('Diana Villamar', 'dvillamar@fixmanager.ec', 'vll39d8', 'CAJERO', TRUE),
('Fernando Cedeño', 'fcedeno@fixmanager.ec', 'cdn64k5', 'CAJERO', TRUE);

-- RECEPCIONISTAS
SET @recep1 = (SELECT id FROM usuario WHERE correo = 'cmena@fixmanager.ec');
SET @recep2 = (SELECT id FROM usuario WHERE correo = 'jalmeida@fixmanager.ec');
SET @recep3 = (SELECT id FROM usuario WHERE correo = 'mquishpe@fixmanager.ec');

-- TÉCNICOS
SET @tecnico1 = (SELECT id FROM usuario WHERE correo = 'gpincay@fixmanager.ec');
SET @tecnico2 = (SELECT id FROM usuario WHERE correo = 'ccoello@fixmanager.ec');
SET @tecnico3 = (SELECT id FROM usuario WHERE correo = 'ranchundia@fixmanager.ec');
SET @tecnico4 = (SELECT id FROM usuario WHERE correo = 'lzambrano@fixmanager.ec');

-- CAJEROS
SET @cajero1 = (SELECT id FROM usuario WHERE correo = 'nbarzola@fixmanager.ec');
SET @cajero2 = (SELECT id FROM usuario WHERE correo = 'dvillamar@fixmanager.ec');
SET @cajero3 = (SELECT id FROM usuario WHERE correo = 'fcedeno@fixmanager.ec');

-- ADMIN
SET @admin = (SELECT id FROM usuario WHERE correo = 'admin@fixmanager.ec');

INSERT INTO cliente (nombre, correo, telefono, direccion) VALUES
('Jefferson Mendoza', 'jmendoza.ec@gmail.com', '0981234567', 'Guayaquil - Sauces 4'),
('Glenda Holguín', 'glen_holguin@hotmail.com', '0997654321', 'Guayaquil - Urdesa Central'),
('Bryan Caicedo', 'bcaicedo99@gmail.com', '0961472583', 'Guayaquil - Alborada'),
('Estefanía Moreira', 'emoreira_est@outlook.com', '0953698521', 'Duran - Cdla. El Recreo'),
('Santiago Yánez', 'syanez_tech@gmail.com', '0932581476', 'Guayaquil - Centro'),
('Ingrid Solórzano', 'isolorzano@gmail.com', '0978523641', 'Guayaquil - Mapasingue Oeste'),
('Kevin Villalta', 'kvillalta.94@gmail.com', '0941239874', 'Guayaquil - Mucho Lote 1'),
('Roxana Lindao', 'rlindao_c@hotmail.com', '0929874561', 'Guayaquil - Barrio Cuba'),
('Marlon Intriago', 'mintriago_eng@gmail.com', '0985214763', 'Samborondón - La Puntilla'),
('Tatiana Bajaña', 'tbajana_makeup@outlook.com', '0963214587', 'Guayaquil - Suburbio'),
('Alejandro Giler', 'agiler_99@gmail.com', '0957412369', 'Guayaquil - Kennedy Norte');

SET @cl_id = (SELECT id FROM cliente WHERE correo = 'jmendoza.ec@gmail.com');

INSERT INTO equipo_movil (marca, modelo, imei, tipo, cliente_id) VALUES
('Samsung', 'Galaxy A54', '359874123654120', 'CELULAR', @cl_id),
('Apple', 'iPhone 14 Pro', '354125896321475', 'CELULAR', @cl_id + 1),
('Xiaomi', 'Redmi Note 12 Pro', '357412589632144', 'CELULAR', @cl_id + 2),
('Samsung', 'Galaxy Tab S8', '352147896325411', 'TABLET', @cl_id + 3),
('Motorola', 'Moto G84', '358963214752148', 'CELULAR', @cl_id + 4),
('Honor', 'Magic 5 Lite', '356321478596214', 'CELULAR', @cl_id + 5),
('Infinix', 'Hot 30i', '351478523698412', 'CELULAR', @cl_id + 6),
('Apple', 'iPad Air 5', '359632147854123', 'TABLET', @cl_id + 7),
('Tecno', 'Pova 5', '354785214796321', 'CELULAR', @cl_id + 8),
('Xiaomi', 'Poco F5 Pro', '358741236985214', 'CELULAR', @cl_id + 9),
('Samsung', 'Galaxy S23 Ultra', '352369874125478', 'CELULAR', @cl_id + 10),
('Apple', 'iPhone 11', '351122334455667', 'CELULAR', @cl_id),
('Xiaomi', 'Redmi 10', '352233445566778', 'CELULAR', @cl_id + 1),
('Samsung', 'Galaxy A34', '353344556677889', 'CELULAR', @cl_id + 2),
('Motorola', 'Edge 40', '354455667788990', 'CELULAR', @cl_id + 3),
('Huawei', 'P30 Lite', '355566778899001', 'CELULAR', @cl_id + 4),
('Realme', 'C55', '356677889900112', 'CELULAR', @cl_id + 5),
('Google', 'Pixel 7 Pro', '357788990011223', 'CELULAR', @cl_id + 6),
('Samsung', 'Galaxy A14', '358899001122334', 'CELULAR', @cl_id + 7),
('Apple', 'iPhone 13', '359900112233445', 'CELULAR', @cl_id + 8),
('Xiaomi', 'Note 11S', '350011223344556', 'CELULAR', @cl_id + 9),
('Oppo', 'Reno 10', '351234567890123', 'CELULAR', @cl_id + 10),
('Samsung', 'Galaxy Tab A8', '352345678901234', 'TABLET', @cl_id),
('Motorola', 'Moto G54', '353456789012345', 'CELULAR', @cl_id + 1),
('Honor', 'X8a', '354567890123456', 'CELULAR', @cl_id + 2);

SET @eq_id = (SELECT id FROM equipo_movil WHERE imei = '359874123654120');

INSERT INTO recepcion_entrega (equipo_id, usuario_id, problema_reportado) VALUES
(@eq_id, @recep1, 'Cliente indica que el equipo se apagó repentinamente y ya no enciende'),
(@eq_id + 1, @recep1, 'Cliente reporta que el teléfono se descarga muy rápido y se apaga al 30%'),
(@eq_id + 2, @recep1, 'Cliente menciona que el equipo se reinicia constantemente sin razón aparente'),
(@eq_id + 3, @recep1, 'Cliente indica que el dispositivo no carga al conectarlo al cargador'),
(@eq_id + 4, @recep2, 'Cliente reporta que la pantalla no muestra imagen pero el equipo vibra'),

(@eq_id + 5, @recep2, 'Cliente menciona daño en la cámara trasera (vidrio roto)'),
(@eq_id + 6, @recep2, 'Cliente indica que el botón de encendido no responde correctamente'),
(@eq_id + 7, @recep3, 'Cliente reporta que el equipo no detecta redes WiFi ni Bluetooth'),
(@eq_id + 8, @recep3, 'Cliente indica sobrecalentamiento excesivo al cargar el dispositivo'),
(@eq_id + 9, @recep1, 'Cliente menciona que el equipo quedó en logo y no inicia sistema'),

(@eq_id + 10, @recep2, 'Cliente reporta daño físico en la tapa trasera del equipo'),
(@eq_id + 11, @recep1, 'Cliente indica que el micrófono no funciona durante llamadas'),
(@eq_id + 12, @recep3, 'Cliente menciona que el puerto de carga está flojo o intermitente'),
(@eq_id + 13, @recep1, 'Cliente reporta batería inflada y tapa despegada'),
(@eq_id + 14, @recep2, 'Cliente indica que la pantalla está rota y no responde al tacto'),

(@eq_id + 15, @recep3, 'Cliente reporta que no reconoce la tarjeta SIM'),
(@eq_id + 16, @recep2, 'Cliente menciona fallas en la iluminación de la pantalla'),
(@eq_id + 17, @recep1, 'Cliente indica problemas en la cámara trasera (imagen borrosa)'),
(@eq_id + 18, @recep2, 'Cliente reporta bloqueo del dispositivo por cuenta o patrón'),
(@eq_id + 19, @recep3, 'Cliente indica que el auricular se escucha muy bajo'),

(@eq_id + 20, @recep3, 'Cliente menciona que el equipo no enciende después de descarga total'),
(@eq_id + 21, @recep1, 'Cliente reporta daño en el vidrio o pantalla externa'),
(@eq_id + 22, @recep2, 'Cliente indica que la pantalla táctil no responde correctamente'),
(@eq_id + 23, @recep3, 'Cliente menciona humedad interna en el dispositivo'),
(@eq_id + 24, @recep3, 'Cliente reporta que el chasis está doblado o deformado');

SET @rec_id = (SELECT id FROM recepcion_entrega WHERE equipo_id = @eq_id);

INSERT INTO reparacion 
(diagnostico, solucion, costo_servicio, costo_repuestos, piezas_usadas, estado, recepcion_id, usuario_id)
VALUES
('Pantalla OLED rota internamente', 'Instalación de nueva pantalla original', 40.00, 65.00, 'Pantalla Samsung A54', 'PENDIENTE', @rec_id, @tecnico1),
('Batería degradada al 68%', 'Reemplazo de batería homologada', 20.00, 30.00, 'Batería iPhone 14P', 'PENDIENTE', @rec_id + 1, @tecnico2),
('Cortocircuito menor en línea secundaria', 'Baño químico ultrasónico y resoldaje', 10.00, 15.00, 'Alcohol Isopropílico', 'PENDIENTE', @rec_id + 2, @tecnico1),
('Pistas del pin de carga desprendidas', 'Micro-soldadura de puerto tipo C', 5.00, 8.00, 'Puerto Tipo C Genérico', 'PENDIENTE', @rec_id + 3, @tecnico4),
('Flex de pantalla desconectado', 'Limpieza de conectores y sujeción', 3.00, 5.00, 'Cinta térmica', 'PENDIENTE', @rec_id + 4, @tecnico1),
('Lente protector fisurado', 'Extracción manual e instalación repuesto', 2.00, 4.00, 'Lente de cámara Honor', 'PENDIENTE', @rec_id + 5, @tecnico3),
('Flex de encendido roto en base', 'Reemplazo de componente completo', 4.00, 7.00, 'Flex Power Infinix', 'PENDIENTE', @rec_id + 6, @tecnico3),
('Módulo IC de Wi-Fi desoldado', 'Proceso de reballing al chip', 0.00, 0.00, 'Esferas de estaño', 'PENDIENTE', @rec_id + 7, @tecnico2),
('IC de carga dañado por voltaje', 'Reemplazo del integrado en placa', 8.00, 12.00, 'Chip IC de carga', 'PENDIENTE', @rec_id + 8, @tecnico4),
('Bucle de sistema por actualización', 'Carga de sistema operativo EDL', 15.00, 0.00, 'Firmware Oficial', 'PENDIENTE', @rec_id + 9, @tecnico2),
('Tapa de vidrio pulverizada', 'Instalación de tapa con B7000', 10.00, 18.00, 'Tapa trasera S23U', 'PENDIENTE', @rec_id + 10, @tecnico3),
('Micrófono obstruido por sarro', 'Cambio físico de micrófono SMD', 2.00, 3.00, 'Micrófono iPhone 11', 'PENDIENTE', @rec_id + 11, @tecnico1),
('Pin con desgaste físico interno', 'Cambio de placa de carga inferior', 3.00, 6.00, 'Subplaca Redmi 10', 'PENDIENTE', @rec_id + 12, @tecnico2),
('Batería inflada y tapa despegada', 'Instalación de repuestos nuevos', 12.00, 22.00, 'Batería y Tapa A34', 'PENDIENTE', @rec_id + 13, @tecnico3),
('Pantalla rota en esquinas curvas', 'Reemplazo de panel curvo completo', 60.00, 95.00, 'Pantalla Edge 40', 'PENDIENTE', @rec_id + 14, @tecnico4);

SET @rep_id = (SELECT id FROM reparacion WHERE recepcion_id = @rec_id);

UPDATE reparacion SET estado = 'FINALIZADO' WHERE id IN (@rep_id, @rep_id + 1, @rep_id + 2, @rep_id + 3, @rep_id + 4, @rep_id + 5, @rep_id + 6, @rep_id + 7, @rep_id + 8, @rep_id + 9);
UPDATE reparacion SET estado = 'EN_PROCESO' WHERE id IN (@rep_id + 10, @rep_id + 11, @rep_id + 12);

INSERT INTO factura
(reparacion_id, usuario_id, estado, observaciones, metodo_pago)
VALUES
(@rep_id,     @cajero1, 'PAGADA', 'Garantía de 3 meses por pantalla', 'EFECTIVO'),
(@rep_id + 1, @cajero3, 'PENDIENTE', 'Retiro pactado fin de semana', NULL),
(@rep_id + 2, @cajero3, 'PAGADA', 'Recomendación estuche impermeable', 'TRANSFERENCIA'),
(@rep_id + 3, @cajero2, 'PAGADA', 'Pin reforzado con epóxica', 'EFECTIVO'),
(@rep_id + 4, @cajero2, 'PAGADA', 'Solo mano de obra', 'EFECTIVO'),
(@rep_id + 5, @cajero2, 'PAGADA', 'Limpieza general de cortesía', 'TRANSFERENCIA'),
(@rep_id + 6, @cajero3, 'PAGADA', 'Pulsadores probados', 'EFECTIVO'),
(@rep_id + 7, @cajero1, 'PENDIENTE', 'Trabajo complejo microelectrónica', NULL),
(@rep_id + 8, @cajero1, 'PENDIENTE', 'No usar cargador genérico', NULL),
(@rep_id + 9, @cajero2, 'PAGADA', 'Flasheo exitoso', 'EFECTIVO');

SET @fac_id = (SELECT id FROM factura WHERE reparacion_id = @rep_id);

SELECT * FROM usuario;