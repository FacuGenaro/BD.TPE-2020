-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-06-26 03:59:31.104

-- tables
-- Table: GR10_CATEGORIA
CREATE TABLE GR10_CATEGORIA (
    id_categoria int  NOT NULL,
    descripcion varchar(200)  NOT NULL,
    id_nivel_juego int  NOT NULL,
    CONSTRAINT PK_GR10_CATEGORIA PRIMARY KEY (id_categoria)
);

-- Table: GR10_COMENTA
CREATE TABLE GR10_COMENTA (
    id_usuario int  NOT NULL,
    id_juego int  NOT NULL,
    fecha_primer_com timestamp  NOT NULL,
    fecha_ultimo_com timestamp  NULL,
    CONSTRAINT PK_GR10_COMENTA PRIMARY KEY (id_usuario,id_juego)
);

-- Table: GR10_COMENTARIO
CREATE TABLE GR10_COMENTARIO (
    id_usuario int  NOT NULL,
    id_juego int  NOT NULL,
    id_comentario int  NOT NULL,
    fecha_comentario timestamp  NOT NULL,
    comentario varchar(200)  NOT NULL,
    CONSTRAINT PK_GR10_COMENTARIO PRIMARY KEY (id_usuario,id_juego,id_comentario)
);

-- Table: GR10_JUEGA
CREATE TABLE GR10_JUEGA (
    finalizado boolean  NULL,
    id_usuario int  NOT NULL,
    id_juego int  NOT NULL,
    CONSTRAINT PK_GR10_JUEGA PRIMARY KEY (id_usuario,id_juego)
);

-- Table: GR10_JUEGO
CREATE TABLE GR10_JUEGO (
    id_juego int  NOT NULL,
    nombre_juego varchar(100)  NOT NULL,
    descripcion_juego varchar(2048)  NOT NULL,
    id_categoria int  NOT NULL,
    CONSTRAINT PK_GR10_JUEGO PRIMARY KEY (id_juego)
);

-- Table: GR10_NIVEL
CREATE TABLE GR10_NIVEL (
    id_nivel_juego int  NOT NULL,
    descripcion varchar(200)  NOT NULL,
    CONSTRAINT PK_GR10_NIVEL PRIMARY KEY (id_nivel_juego)
);

-- Table: GR10_RECOMENDACION
CREATE TABLE GR10_RECOMENDACION (
    id_recomendacion int  NOT NULL,
    email_recomendado varchar(30)  NOT NULL,
    id_usuario int  NOT NULL,
    id_juego int  NOT NULL,
    CONSTRAINT PK_GR10_RECOMENDACION PRIMARY KEY (id_recomendacion)
);

-- Table: GR10_TIPO_USUARIO
CREATE TABLE GR10_TIPO_USUARIO (
    id_tipo_usuario int  NOT NULL,
    descripcion varchar(30)  NOT NULL,
    CONSTRAINT PK_GR10_TIPO_USUARIO PRIMARY KEY (id_tipo_usuario)
);

-- Table: GR10_USUARIO
CREATE TABLE GR10_USUARIO (
    id_usuario int  NOT NULL,
    apellido varchar(50)  NOT NULL,
    nombre varchar(50)  NOT NULL,
    email varchar(30)  NOT NULL,
    id_tipo_usuario int  NOT NULL,
    password varchar(32)  NOT NULL,
    CONSTRAINT PK_GR10_USUARIO PRIMARY KEY (id_usuario)
);

-- Table: GR10_VOTO
CREATE TABLE GR10_VOTO (
    id_voto int  NOT NULL,
    valor_voto int  NOT NULL,
    id_usuario int  NOT NULL,
    id_juego int  NOT NULL,
    CONSTRAINT PK_GR10_VOTO PRIMARY KEY (id_voto)
);

-- foreign keys
-- Reference: FK_GR10_CATEGORIA_JUEGO (table: GR10_JUEGO)
ALTER TABLE GR10_JUEGO ADD CONSTRAINT FK_GR10_CATEGORIA_JUEGO
    FOREIGN KEY (id_categoria)
    REFERENCES GR10_CATEGORIA (id_categoria)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_COMENTA_COMENTARIO (table: GR10_COMENTARIO)
ALTER TABLE GR10_COMENTARIO ADD CONSTRAINT FK_GR10_COMENTA_COMENTARIO
    FOREIGN KEY (id_usuario, id_juego)
    REFERENCES GR10_COMENTA (id_usuario, id_juego)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_JUEGA_RECOMENDACION (table: GR10_RECOMENDACION)
ALTER TABLE GR10_RECOMENDACION ADD CONSTRAINT FK_GR10_JUEGA_RECOMENDACION
    FOREIGN KEY (id_usuario, id_juego)
    REFERENCES GR10_JUEGA (id_usuario, id_juego)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_JUEGA_VOTO (table: GR10_VOTO)
ALTER TABLE GR10_VOTO ADD CONSTRAINT FK_GR10_JUEGA_VOTO
    FOREIGN KEY (id_usuario, id_juego)
    REFERENCES GR10_JUEGA (id_usuario, id_juego)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_JUEGO_COMENTA (table: GR10_COMENTA)
ALTER TABLE GR10_COMENTA ADD CONSTRAINT FK_GR10_JUEGO_COMENTA
    FOREIGN KEY (id_juego)
    REFERENCES GR10_JUEGO (id_juego)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_JUEGO_JUEGA (table: GR10_JUEGA)
ALTER TABLE GR10_JUEGA ADD CONSTRAINT FK_GR10_JUEGO_JUEGA
    FOREIGN KEY (id_juego)
    REFERENCES GR10_JUEGO (id_juego)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_NIVEL_CATEGORIA (table: GR10_CATEGORIA)
ALTER TABLE GR10_CATEGORIA ADD CONSTRAINT FK_GR10_NIVEL_CATEGORIA
    FOREIGN KEY (id_nivel_juego)
    REFERENCES GR10_NIVEL (id_nivel_juego)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_TIPO_USUARIO_USUARIO (table: GR10_USUARIO)
ALTER TABLE GR10_USUARIO ADD CONSTRAINT FK_GR10_TIPO_USUARIO_USUARIO
    FOREIGN KEY (id_tipo_usuario)
    REFERENCES GR10_TIPO_USUARIO (id_tipo_usuario)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_USUARIO_COMENTA (table: GR10_COMENTA)
ALTER TABLE GR10_COMENTA ADD CONSTRAINT FK_GR10_USUARIO_COMENTA
    FOREIGN KEY (id_usuario)
    REFERENCES GR10_USUARIO (id_usuario)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_GR10_USUARIO_JUEGA (table: GR10_JUEGA)
ALTER TABLE GR10_JUEGA ADD CONSTRAINT FK_GR10_USUARIO_JUEGA
    FOREIGN KEY (id_usuario)
    REFERENCES GR10_USUARIO (id_usuario)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- End of file.

