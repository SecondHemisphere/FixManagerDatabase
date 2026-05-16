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

INSERT INTO equipo_movil (marca, modelo, imei, tipo, descripcion_danio, cliente_id) VALUES
('Samsung', 'Galaxy A54', '359874123654120', 'Celular', 'Pantalla trizada y líneas verdes', @cl_id),
('Apple', 'iPhone 14 Pro', '354125896321475', 'Celular', 'Batería inflada, bucle de logo', @cl_id + 1),
('Xiaomi', 'Redmi Note 12 Pro', '357412589632144', 'Celular', 'Caída en agua sulfatado', @cl_id + 2),
('Samsung', 'Galaxy Tab S8', '352147896325411', 'Tablet', 'Pin de carga tipo C roto', @cl_id + 3),
('Motorola', 'Moto G84', '358963214752148', 'Celular', 'No da imagen, vibra y timbra', @cl_id + 4),
('Honor', 'Magic 5 Lite', '356321478596214', 'Celular', 'Vidrio de cámara posterior roto', @cl_id + 5),
('Infinix', 'Hot 30i', '351478523698412', 'Celular', 'Botón encendido hundido', @cl_id + 6),
('Apple', 'iPad Air 5', '359632147854123', 'Tablet', 'No reconoce Wi-Fi ni Bluetooth', @cl_id + 7),
('Tecno', 'Pova 5', '354785214796321', 'Celular', 'Se recalienta al cargar', @cl_id + 8),
('Xiaomi', 'Poco F5 Pro', '358741236985214', 'Celular', 'Error de software modo brick', @cl_id + 9),
('Samsung', 'Galaxy S23 Ultra', '352369874125478', 'Celular', 'Tapa trasera de vidrio rota', @cl_id + 10),
('Apple', 'iPhone 11', '351122334455667', 'Celular', 'Micrófono principal no funciona', @cl_id),
('Xiaomi', 'Redmi 10', '352233445566778', 'Celular', 'Puerto de carga flojo', @cl_id + 1),
('Samsung', 'Galaxy A34', '353344556677889', 'Celular', 'Cambio de tapa y batería', @cl_id + 2),
('Motorola', 'Edge 40', '354455667788990', 'Celular', 'Pantalla rota por presión', @cl_id + 3),
('Huawei', 'P30 Lite', '355566778899001', 'Celular', 'No detecta tarjeta SIM', @cl_id + 4),
('Realme', 'C55', '356677889900112', 'Celular', 'Luz de pantalla parpadea', @cl_id + 5),
('Google', 'Pixel 7 Pro', '357788990011223', 'Celular', 'Cámara trasera borrosa', @cl_id + 6),
('Samsung', 'Galaxy A14', '358899001122334', 'Celular', 'Olvido de patrón de desbloqueo', @cl_id + 7),
('Apple', 'iPhone 13', '359900112233445', 'Celular', 'Auricular llamadas suena muy bajo', @cl_id + 8),
('Xiaomi', 'Note 11S', '350011223344556', 'Celular', 'No enciende tras descarga total', @cl_id + 9),
('Oppo', 'Reno 10', '351234567890123', 'Celular', 'Vidrio templado pegado con brujita', @cl_id + 10),
('Samsung', 'Galaxy Tab A8', '352345678901234', 'Tablet', 'Pantalla táctil no responde', @cl_id),
('Motorola', 'Moto G54', '353456789012345', 'Celular', 'Parches de humedad internos', @cl_id + 1),
('Honor', 'X8a', '354567890123456', 'Celular', 'Carcasa intermedia doblada', @cl_id + 2);

SET @eq_id = (SELECT id FROM equipo_movil WHERE imei = '359874123654120');

INSERT INTO recepcion_entrega (equipo_id, usuario_id, problema_reportado) VALUES
(@eq_id, @cajero1, 'Cambio de módulo de pantalla completo por golpe'),
(@eq_id + 1, @cajero1, 'Cambio de batería de alta calidad'),
(@eq_id + 2, @cajero1, 'Mantenimiento preventivo por humedad'),
(@eq_id + 3, @cajero1, 'Reemplazo de pin de carga soldado a placa'),
(@eq_id + 4, @cajero2, 'Diagnóstico de pantalla o posible daño flex'),
(@eq_id + 5, @cajero2, 'Reemplazo del cristal protector de cámara'),
(@eq_id + 6, @cajero2, 'Cambio de flex interno de botones físicos'),
(@eq_id + 7, @cajero1, 'Revisión de antena IC de Wi-Fi'),
(@eq_id + 8, @cajero2, 'Cambio de puerto de carga y regulador'),
(@eq_id + 9, @cajero1, 'Flasheo de firmware oficial'),
(@eq_id + 10, @cajero2, 'Instalación de tapa trasera original'),
(@eq_id + 11, @cajero1, 'Reemplazo de micrófono inferior'),
(@eq_id + 12, @cajero2, 'Cambio de subplaca de carga completa'),
(@eq_id + 13, @cajero1, 'Cambio estético y funcional de batería y tapa'),
(@eq_id + 14, @cajero2, 'Cambio de pantalla OLED curva'),
(@eq_id + 15, @cajero1, 'Reparación de lector de SIM card'),
(@eq_id + 16, @cajero2, 'Revisión de circuito integrado de retroiluminación'),
(@eq_id + 17, @cajero1, 'Cambio de módulo de cámaras traseras'),
(@eq_id + 18, @cajero2, 'Remoción de cuenta e instalación limpia'),
(@eq_id + 19, @cajero1, 'Limpieza profunda y cambio de auricular'),
(@eq_id + 20, @cajero2, 'Revivió de batería estática por fuente externa'),
(@eq_id + 21, @cajero1, 'Remoción de vidrio con calor controlado'),
(@eq_id + 22, @cajero2, 'Cambio de digitalizador de pantalla'),
(@eq_id + 23, @cajero1, 'Mantenimiento completo por sudor/humedad'),
(@eq_id + 24, @cajero2, 'Enderezado de chasis estructural');

SET @rec_id = (SELECT id FROM recepcion_entrega WHERE equipo_id = @eq_id);

INSERT INTO reparacion (diagnostico, solucion, costo_repuestos, piezas_usadas, estado, recepcion_id, usuario_id) VALUES
('Pantalla OLED rota internamente', 'Instalación de nueva pantalla original', 65.00, 'Pantalla Samsung A54', 'PENDIENTE', @rec_id, @tecnico1),
('Batería degradada al 68%', 'Reemplazo de batería homologada', 30.00, 'Batería iPhone 14P', 'PENDIENTE', @rec_id + 1, @tecnico2),
('Cortocircuito menor en línea secundaria', 'Baño químico ultrasónico y resoldaje', 15.00, 'Alcohol Isopropílico', 'PENDIENTE', @rec_id + 2, @tecnico1),
('Pistas del pin de carga desprendidas', 'Micro-soldadura de puerto tipo C', 8.00, 'Puerto Tipo C Genérico', 'PENDIENTE', @rec_id + 3, @tecnico2),
('Flex de pantalla desconectado', 'Limpieza de conectores y sujeción', 5.00, 'Cinta térmica', 'PENDIENTE', @rec_id + 4, @tecnico1),
('Lente protector fisurado', 'Extracción manual e instalación repuesto', 4.00, 'Lente de cámara Honor', 'PENDIENTE', @rec_id + 5, @tecnico3),
('Flex de encendido roto en base', 'Reemplazo de componente completo', 7.00, 'Flex Power Infinix', 'PENDIENTE', @rec_id + 6, @tecnico3),
('Módulo IC de Wi-Fi desoldado', 'Proceso de reballing al chip', 0.00, 'Esferas de estaño', 'PENDIENTE', @rec_id + 7, @tecnico2),
('IC de carga dañado por voltaje', 'Reemplazo del integrado en placa', 12.00, 'Chip IC de carga', 'PENDIENTE', @rec_id + 8, @tecnico1),
('Bucle de sistema por actualización', 'Carga de sistema operativo EDL', 0.00, 'Firmware Oficial', 'PENDIENTE', @rec_id + 9, @tecnico2),
('Tapa de vidrio pulverizada', 'Instalación de tapa con B7000', 18.00, 'Tapa trasera S23U', 'PENDIENTE', @rec_id + 10, @tecnico3),
('Micrófono obstruido por sarro', 'Cambio físico de micrófono SMD', 3.00, 'Micrófono iPhone 11', 'PENDIENTE', @rec_id + 11, @tecnico1),
('Pin con desgaste físico interno', 'Cambio de placa de carga inferior', 6.00, 'Subplaca Redmi 10', 'PENDIENTE', @rec_id + 12, @tecnico2),
('Batería inflada y tapa despegada', 'Instalación de repuestos nuevos', 22.00, 'Batería y Tapa A34', 'PENDIENTE', @rec_id + 13, @tecnico3),
('Pantalla rota en esquinas curvas', 'Reemplazo de panel curvo completo', 95.00, 'Pantalla Edge 40', 'PENDIENTE', @rec_id + 14, @tecnico1);

SET @rep_id = (SELECT id FROM reparacion WHERE recepcion_id = @rec_id);

UPDATE reparacion SET estado = 'FINALIZADO' WHERE id IN (@rep_id, @rep_id + 1, @rep_id + 2, @rep_id + 3, @rep_id + 4, @rep_id + 5, @rep_id + 6, @rep_id + 7, @rep_id + 8, @rep_id + 9);
UPDATE reparacion SET estado = 'EN_PROCESO' WHERE id IN (@rep_id + 10, @rep_id + 11, @rep_id + 12);

INSERT INTO factura (reparacion_id, usuario_id, costo_total, estado, observaciones, metodo_pago) VALUES
(@rep_id, @cajero1, 110.00, 'PENDIENTE', 'Garantía de 3 meses por pantalla', 'EFECTIVO'),
(@rep_id + 1, @cajero1, 55.00, 'PENDIENTE', 'Retiro pactado fin de semana', 'TARJETA'),
(@rep_id + 2, @cajero1, 45.00, 'PENDIENTE', 'Recomendación estuche impermeable', 'TRANSFERENCIA'),
(@rep_id + 3, @cajero2, 30.00, 'PENDIENTE', 'Pin reforzado con epóxica', 'EFECTIVO'),
(@rep_id + 4, @cajero2, 25.00, 'PENDIENTE', 'Solo mano de obra', 'EFECTIVO'),
(@rep_id + 5, @cajero2, 15.00, 'PENDIENTE', 'Limpieza general de cortesía', 'TRANSFERENCIA'),
(@rep_id + 6, @cajero1, 25.00, 'PENDIENTE', 'Pulsadores probados', 'EFECTIVO'),
(@rep_id + 7, @cajero1, 60.00, 'PENDIENTE', 'Trabajo complejo microelectrónica', 'TARJETA'),
(@rep_id + 8, @cajero2, 40.00, 'PENDIENTE', 'No usar cargador genérico', 'TRANSFERENCIA'),
(@rep_id + 9, @cajero2, 20.00, 'PENDIENTE', 'Flasheo exitoso', 'EFECTIVO');

SET @fac_id = (SELECT id FROM factura WHERE reparacion_id = @rep_id);

UPDATE factura SET estado = 'PAGADA', metodo_pago = 'EFECTIVO' WHERE id IN (@fac_id, @fac_id + 3, @fac_id + 4, @fac_id + 6, @fac_id + 9);
UPDATE factura SET estado = 'PAGADA', metodo_pago = 'TRANSFERENCIA' WHERE id IN (@fac_id + 2, @fac_id + 5);

SELECT * FROM recepcion_entrega;