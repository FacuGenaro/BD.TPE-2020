set search_path = unc_248270;

insert into gr10_tipo_usuario (id_tipo_usuario, descripcion)
values (1, 'tipoUsuario1'),
       (2, 'tipoUsuario2');

insert into gr10_usuario (id_usuario, apellido, nombre, email, id_tipo_usuario, password)
values (1, 'nombre1', 'apellido1', 'email1', 1, 'pass1'),
       (2, 'nombre2', 'apellido2', 'email2', 2, 'pass2'),
       (3, 'nombre3', 'apellido3', 'email3', 1, 'pass3'),
       (4, 'nombre4', 'apellido4', 'email4', 2, 'pass4');

insert into gr10_nivel (id_nivel_juego, descripcion)
values (1, 'desc1'),
       (2, 'desc2');

insert into gr10_categoria (id_categoria, descripcion, id_nivel_juego)
values (1, 'desc1', 1),
       (2, 'desc2', 2),
       (3, 'desc3', 1),
       (4, 'desc4', 2);

insert into gr10_juego (id_juego, nombre_juego, descripcion_juego, id_categoria)
values (1, 'juego1', 'desc1', 1),
       (2, 'juego2', 'desc2', 2),
       (3, 'juego3', 'desc3', 3),
       (4, 'juego4', 'desc4', 4);

insert into gr10_comenta (id_usuario, id_juego, fecha_primer_com, fecha_ultimo_com)
values (1, 1, '2020-06-20', null),
       (2, 2, '2020-06-21',  null),
       (3, 3, '2020-06-22', null),
       (4, 4, '2020-06-23', null);

insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario)
values (1, 1, 1, current_date, 'comentario1'),
       (2, 2, 2, '2020-06-21', 'comentario2'),
       (3, 3, 3, '2020-06-22', 'comentario3');

insert into gr10_juega (finalizado, id_usuario, id_juego)
values (null, 1, 1),
       (null, 2, 2),
       (null, 3, 3),
       (null, 4, 4);

insert into gr10_voto (id_voto, valor_voto, id_usuario, id_juego)
values (1, 6, 1, 1),
       (2, 7, 2, 2),
       (3, 8, 3, 3),
       (4, 9, 4, 4);

insert into gr10_recomendacion (id_recomendacion, email_recomendado, id_usuario, id_juego)
values (1, 'email1', 2, 2),
       (2, 'email2', 3, 3),
       (3, 'email3', 4, 4);

