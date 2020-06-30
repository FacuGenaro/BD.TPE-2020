--set search_path = unc_248270;
set search_path = unc_248580;
/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

RESTRICCIONES

B.a. La fecha del primer comentario tiene que ser anterior a la fecha del último comentario si este
no es nulo.

*/

alter table gr10_comenta
    add constraint GR10_CHK_PRIMER_COMENTARIO
        check ((fecha_primer_com < fecha_ultimo_com) or (fecha_ultimo_com is null));

/*
Para esta prueba tomamos como ejemplo el usuario 101 cuya fecha_primer_com es 2020_08_31 que posee comentarios en todos los juegos e
intentaremos insertar un comentario con una fecha anterior
*/

--insert into gr10_comentario(id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 1, 1, '2020-05-31', 'este comentario falla');

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

B. b. Cada usuario sólo puede comentar una vez al día cada juego.


 */

create or replace function FN_GR10_COMENTARIO_DIARIO()
    returns trigger as
$$
begin
    if exists(
            select 1
            from gr10_comentario
            where id_usuario = new.id_usuario
              and fecha_comentario = new.fecha_comentario
              and id_juego = new.id_juego
        )
    then
        raise exception 'El usuario % ya comentó este juego hoy %', new.id_usuario, new.fecha_comentario;
    end if;
    return new;
end
$$
    language 'plpgsql';

create trigger TR_GR10_COMENTARIO_DIARIO
    before insert or update of fecha_comentario
    on gr10_comentario
    for each row
execute procedure FN_GR10_COMENTARIO_DIARIO();

/*
CASO DE PRUEBA:

Si intento insertar un comentario, el trigger verifica en cada fila si existe un comentario del mismo
usuario con la nueva fecha del comentario y si existe, no permite
la insercion del comentario
*/
--Este insert cumple la condición del trigger

--insert into gr10_comentario(id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 1, 2, '2020-09-01', 'este comentario funciona');

/*
El siguiente insert no cumple la condicion del trigger ya que la fecha cargada en la bd para
el comentario del usuario 101 en el juego 1 es 2020-08-31 por lo tanto dará error
*/

--insert into gr10_comentario(id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 1, 3, '2020-08-31', 'este comentario falla');

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

 B.c. Un usuario no puede recomendar un juego si no ha votado previamente dicho juego.

 */

create or replace function FN_GR10_VERIF_RECOM_VOTO()
    -- En esta funcion verifico si el usuario votó el juego para poder recomendarlo
    returns trigger as
$$
begin
    if (not exists(select 1
                   from gr10_voto v
                   where v.id_usuario = new.id_usuario
                     and v.id_juego = new.id_juego
        ))
    then
        raise exception 'El usuario % no puede recomendar porque no votó previamente en el juego %', new.id_usuario, new.id_juego;
    end if;
    return new;
end
$$
    language 'plpgsql';

create trigger TR_GR10_VERIF_RECOM_VOTO
    before insert or update of id_usuario, id_juego
    on gr10_recomendacion
    for each row
execute procedure FN_GR10_VERIF_RECOM_VOTO();


/*
CASO DE PRUEBA:

Si intento insertar una recomendacion pero no tiene voto asociado da error, en esta caso intento
insertar una recomendacion de parte del usuario 1 al juego 2 pero se activa la excepcion del
trigger ya que el juego no posee un voto del usuario
*/

--insert into gr10_recomendacion (id_recomendacion, email_recomendado, id_usuario, id_juego) values (5, 'RecoError', 1, 2);

/*
En cambio si intento insertar una recomendacion de la cual existe el voto, puedo hacerlo
sin problemas. Acá tomamos como ejemplo el id usuario 1 y el juego 23
 */

--insert into gr10_recomendacion (id_recomendacion, email_recomendado, id_usuario, id_juego) values (5, 'RecoSuccess', 1, 23);

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

B.d. Un usuario no puede comentar un juego que no ha jugado.

Es una restriccion de tabla ya que debo verificar en la tabla juega para luego insertar el comentario en la tabla comentario
 */

create or replace function FN_GR10_VERIF_JUGO_JUEGO()
    /*
    En esta funcion verifico si el usuario jugó al juego para poder comentario, asumo que
    para considerarse "jugado" la variable finalziado tiene que ser true
    */
    returns trigger as
$$
begin
    if (not exists(select 1
                   from gr10_juega
                   where id_usuario = new.id_usuario
                     and id_juego = new.id_juego
        ))
    then
        raise exception 'El usuario % no puede comentar porque nunca jugó al juego %', new.id_usuario, new.id_juego;
    end if;
    return new;
end
$$
    language 'plpgsql';

create trigger TR_GR10_VERIF_JUGO_JUEGO
    before insert or update of id_usuario, id_juego
    on gr10_comentario
    for each row
execute procedure FN_GR10_VERIF_JUGO_JUEGO();

/*
CASO DE PRUEBA:

Este insert funciona ya que la combinación id_usuario= 38 e id_juego = 24 están cargados en la tabla juega, eso
implica que el usuarió jugó al juego, por lo tanto el comentario se agrega correctamente
 */

--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (38, 24, 28, '2020-09-17', 'comentarioFunciona');

/*
Este insert no funciona ya que la combinación id_usuario= 100 e id_juego = 24 No están cargados en la tabla juega, eso
implica que el usuarió nunca jugó al juego, por lo tanto el comentario no se agrega a la tabla Comentario

 */

--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (100, 24, 31, '2020-09-20', 'comentarioFalla');

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

C) a. La primera vez que se inserta un comentario de un usuario para un juego se debe
hacer el insert conjunto en ambas tablas, colocando la fecha del primer comentario y
último comentario en en nulo.
   b. Los posteriores comentarios para sólo deben modificar la fecha de último comentario
e insertar en COMENTARIO


La primera vez que se inserta un comentario de un usuario para un juego se debe
hacer el insert conjunto en ambas tablas, colocando la fecha del primer comentario y
último comentario en en nulo.

Los posteriores comentarios para sólo deben modificar la fecha de último comentario
e insertar en COMENTARIO
*/

-- Incisos A y B

create or replace function FN_GR10_SINCRONIZAR_COMENTA_COMENTARIO()
    returns trigger as
$$
begin
    if (not exists(
            select 1
            from gr10_comenta
            where id_usuario = new.id_usuario
              and id_juego = new.id_juego
        --si no existe un comentario del usuario X en el juego Y entonces lo inserto en la tabla
        --comenta y pongo su fecha_ultimo_com en null (Inciso A)
        )) then
        insert into gr10_comenta(id_usuario, id_juego, fecha_primer_com, fecha_ultimo_com)
        values (new.id_usuario, new.id_juego, new.fecha_comentario, null);
        return new;
    else
        update gr10_comenta
        set fecha_ultimo_com = new.fecha_comentario
        where id_usuario = new.id_usuario
          and id_juego = new.id_juego;
        return new;
    end if;
end
$$ language 'plpgsql';

create trigger TR_GR10_SINCRONIZAR_COMENTA_COMENTARIO
    before insert or update of id_juego, id_usuario
    on gr10_comentario
    for each row
execute procedure FN_GR10_SINCRONIZAR_COMENTA_COMENTARIO();


/*
Tomando como ejemplo el usuario 62 en el juego 62

Inserto un comentario para disparar el trigger, en este caso ya que el trigger detecta que hay
un comentario previo de un usuario, entonces procede a insertar el comentario y a actualizar la
tabla Comenta como indica la consigna.
 */

--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (62, 62, 1, '2020-08-31', 'comentario funcional');

/*
Este comentario se insertó correctamente ya que no tiene conflictos con otros triggers y si no
existe la entrada en la tabla Comenta, se genera automaticamente como lo indica el inciso A
 */

--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (62, 62, 2, '2020-09-01', 'comentario actualizado en tabla comenta');

/*
Este comentario se insertó correctamente tambien, y ademas se actualizó la fecha de ultimo comentario en
la tabla Comenta para el par id_usuario = 62 e id_juego = 62

Dejo los select acá para verificar
 */

--select *
--from gr10_comentario
--where id_usuario = 62;

--select *
--from gr10_comenta
--where id_usuario = 62;

/*
 ----------------------------------------------------------------------------------------------------------------------------------------
 VISTAS
 */

/*
D.1. Listar Todos los comentarios realizados durante el último mes descartando aquellos juegos
de la Categoría “Sin Categorías”.
 */

CREATE VIEW GR10_COMENTARIOS_ULTIMO_MES AS
SELECT c.*
FROM gr10_comentario c
         JOIN gr10_juego j ON (c.id_juego = j.id_juego)
         JOIN gr10_categoria ca ON (ca.id_categoria = j.id_categoria)
WHERE (ca.descripcion NOT LIKE 'Sin categorías')
  AND extract(month FROM c.fecha_comentario) = extract(month FROM CURRENT_DATE)
  AND extract(year FROM c.fecha_comentario) = extract(year FROM CURRENT_DATE);

/*
D.2. Identificar aquellos usuarios que han comentado todos los juegos durante el último año,
teniendo en cuenta que sólo pueden comentar aquellos juegos que han jugado.
 */

CREATE VIEW GR10_COMENTARIOS_USUARIOS_TODOS_JUEGOS_JUGADOS AS
SELECT u.id_usuario
FROM gr10_usuario u,
     (SELECT id_usuario
      FROM (SELECT id_usuario, id_juego
            FROM gr10_comentario c
            WHERE (extract(year FROM c.fecha_comentario) = (extract(year FROM CURRENT_DATE)))
            GROUP BY id_usuario, id_juego) AS t1
      GROUP BY t1.id_usuario
      HAVING COUNT(*) = (SELECT COUNT(*)
                            FROM gr10_juego)) AS u1
WHERE u.id_usuario = u1.id_usuario;

/*
 D.3. Realizar el ranking de los 20 juegos mejor puntuados por los Usuarios. El ranking debe ser
generado considerando el promedio del valor puntuado por los usuarios y que el juego
hubiera sido calificado más de 5 veces.
 */

CREATE VIEW GR10_RANKING_MEJOR_PUNTUADOS AS
SELECT j.*
FROM gr10_juego j
         JOIN gr10_voto v ON (v.id_juego = j.id_juego)
GROUP BY j.id_juego

HAVING (count(j.id_juego) > 5)
ORDER BY (avg(v.valor_voto)) DESC
LIMIT 20;

/*
 Para verificar:
 La siguiente implementacion imprime los id de los juegos con su puntaje
 */

--select id_juego, avg(valor_voto)
--from gr10_voto
--group by id_juego
--having count(*) > 5
--order by avg(valor_voto) DESC;

/*

Dejamos acá comentados los usuarios que creamos para hacer las pruebas con los comentarios ES SUPER IMPORTANTE QUE LOS INSERTEN ANTES DE PROBAR EL FUNCIONAMIENTO
DE LOS TRIGGERS EN COMENTARIOS

INSERT INTO GR10_USUARIO (id_usuario,nombre,apellido,email,id_tipo_usuario,password) VALUES (101,'Federico','Fuhr','fedef@hotmail.com',8,'LBV82AJZ0IW');
INSERT INTO GR10_USUARIO (id_usuario,nombre,apellido,email,id_tipo_usuario,password) VALUES (102,'Facundo','Genaro','facug@hotmail.com',8,'LBV82AJZ0IW');


INSERT INTO GR10_TIPO_USUARIO (id_tipo_usuario,descripcion) VALUES (101,'Normal');
INSERT INTO GR10_TIPO_USUARIO (id_tipo_usuario,descripcion) VALUES (102,'Normal');

INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,1, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,2, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,3, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,4, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,5, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,6, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,7, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,8, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,9, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,10, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,11, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,12, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,13, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,14, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,15, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,16, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,17, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,18, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,19, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,20, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,21, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,22, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,23, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,24, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,25, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,26, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,27, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,28, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,29, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,30, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,31, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,32, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,33, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,34, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,35, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,36, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,37, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,38, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,39, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,40, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,41, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,42, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,43, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,44, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,45, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,46, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,47, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,48, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,49, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,50, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,51, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,52, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,53, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,54, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,55, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,56, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,57, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,58, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,59, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,60, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,61, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,62, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,63, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,64, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,65, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,66, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,67, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,68, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,69, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,70, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,71, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,72, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,73, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,74, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,75, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,76, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,77, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,78, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,79, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,80, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,81, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,82, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,83, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,84, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,85, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,86, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,87, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,88, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,89, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,90, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,91, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,92, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,93, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,94, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,95, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,96, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,97, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,98, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,99, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,100, TRUE);

INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,1, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,2, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,3, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,4, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,5, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,6, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,7, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,8, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,9, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,10, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,11, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,12, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,13, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,14, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,15, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,16, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,17, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,18, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,19, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,20, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,21, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,22, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,23, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,24, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,25, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,26, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,27, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,28, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,29, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,30, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,31, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,32, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,33, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,34, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,35, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,36, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,37, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,38, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,39, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,40, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,41, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,42, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,43, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,44, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,45, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,46, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,47, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,48, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,49, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,50, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,51, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,52, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,53, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,54, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,55, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,56, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,57, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,58, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,59, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,60, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,61, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,62, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,63, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,64, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,65, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,66, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,67, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,68, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,69, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,70, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,71, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,72, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,73, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,74, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,75, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,76, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,77, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,78, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,79, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,80, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,81, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,82, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,83, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,84, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,85, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,86, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,87, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,88, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,89, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,90, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,91, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,92, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,93, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,94, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,95, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,96, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,97, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,98, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,99, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,100, TRUE);

insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 1, 1, '2017-01-01', 'Comentario 1');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 2, 2, '2017-08-31', 'Comentario 2');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 3, 3, '2017-08-31', 'Comentario 3');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 4, 4, '2017-08-31', 'Comentario 4');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 5, 5, '2017-08-31', 'Comentario 5');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 6, 6, '2017-08-31', 'Comentario 6');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 7, 7, '2017-08-31', 'Comentario 7');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 8, 8, '2017-08-31', 'Comentario 8');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 9, 9, '2017-08-31', 'Comentario 9');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 10, 10, '2017-08-31', 'Comentario 10');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 11, 11, '2017-08-31', 'Comentario 11');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 12, 12, '2017-08-31', 'Comentario 12');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 13, 13, '2017-08-31', 'Comentario 13');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 14, 14, '2017-08-31', 'Comentario 14');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 15, 15, '2017-08-31', 'Comentario 15');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 16, 16, '2017-08-31', 'Comentario 16');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 17, 17, '2017-08-31', 'Comentario 17');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 18, 18, '2017-08-31', 'Comentario 18');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 19, 19, '2017-08-31', 'Comentario 19');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 20, 20, '2017-08-31', 'Comentario 20');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 21, 21, '2017-08-31', 'Comentario 21');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 22, 22, '2017-08-31', 'Comentario 22');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 23, 23, '2017-08-31', 'Comentario 23');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 24, 24, '2017-08-31', 'Comentario 24');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 25, 25, '2017-08-31', 'Comentario 25');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 26, 26, '2017-08-31', 'Comentario 26');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 27, 27, '2017-08-31', 'Comentario 27');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 28, 28, '2017-08-31', 'Comentario 28');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 29, 29, '2017-08-31', 'Comentario 29');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 30, 30, '2017-08-31', 'Comentario 30');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 31, 31, '2017-08-31', 'Comentario 31');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 32, 32, '2017-08-31', 'Comentario 32');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 33, 33, '2017-08-31', 'Comentario 33');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 34, 34, '2017-08-31', 'Comentario 34');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 35, 35, '2017-08-31', 'Comentario 35');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 36, 36, '2017-08-31', 'Comentario 36');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 37, 37, '2017-08-31', 'Comentario 37');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 38, 38, '2017-08-31', 'Comentario 38');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 39, 39, '2017-08-31', 'Comentario 39');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 40, 40, '2017-08-31', 'Comentario 40');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 41, 41, '2017-08-31', 'Comentario 41');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 42, 42, '2017-08-31', 'Comentario 42');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 43, 43, '2017-08-31', 'Comentario 43');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 44, 44, '2017-08-31', 'Comentario 44');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 45, 45, '2017-08-31', 'Comentario 45');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 46, 46, '2017-08-31', 'Comentario 46');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 47, 47, '2017-08-31', 'Comentario 47');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 48, 48, '2017-08-31', 'Comentario 48');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 49, 49, '2017-08-31', 'Comentario 49');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 50, 50, '2017-08-31', 'Comentario 50');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 51, 51, '2017-08-31', 'Comentario 51');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 52, 52, '2017-08-31', 'Comentario 52');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 53, 53, '2017-08-31', 'Comentario 53');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 54, 54, '2017-08-31', 'Comentario 54');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 55, 55, '2017-08-31', 'Comentario 55');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 56, 56, '2017-08-31', 'Comentario 56');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 57, 57, '2017-08-31', 'Comentario 57');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 58, 58, '2017-08-31', 'Comentario 58');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 59, 59, '2017-08-31', 'Comentario 59');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 60, 60, '2017-08-31', 'Comentario 60');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 61, 61, '2017-08-31', 'Comentario 61');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 62, 62, '2017-08-31', 'Comentario 62');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 63, 63, '2017-08-31', 'Comentario 63');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 64, 64, '2017-08-31', 'Comentario 64');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 65, 65, '2017-08-31', 'Comentario 65');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 66, 66, '2017-08-31', 'Comentario 66');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 67, 67, '2017-08-31', 'Comentario 67');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 68, 68, '2017-08-31', 'Comentario 68');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 69, 69, '2017-08-31', 'Comentario 69');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 70, 70, '2017-08-31', 'Comentario 70');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 71, 71, '2017-08-31', 'Comentario 71');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 72, 72, '2017-08-31', 'Comentario 72');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 73, 73, '2017-08-31', 'Comentario 73');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 74, 74, '2017-08-31', 'Comentario 74');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 75, 75, '2017-08-31', 'Comentario 75');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 76, 76, '2017-08-31', 'Comentario 76');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 77, 77, '2017-08-31', 'Comentario 77');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 78, 78, '2017-08-31', 'Comentario 78');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 79, 79, '2017-08-31', 'Comentario 79');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 80, 80, '2017-08-31', 'Comentario 80');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 81, 81, '2017-08-31', 'Comentario 81');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 82, 82, '2017-08-31', 'Comentario 82');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 83, 83, '2017-08-31', 'Comentario 83');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 84, 84, '2017-08-31', 'Comentario 84');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 85, 85, '2017-08-31', 'Comentario 85');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 86, 86, '2017-08-31', 'Comentario 86');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 87, 87, '2017-08-31', 'Comentario 87');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 88, 88, '2017-08-31', 'Comentario 88');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 89, 89, '2017-08-31', 'Comentario 89');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 90, 90, '2017-08-31', 'Comentario 90');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 91, 91, '2017-08-31', 'Comentario 91');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 92, 92, '2017-08-31', 'Comentario 92');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 93, 93, '2017-08-31', 'Comentario 93');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 94, 94, '2017-08-31', 'Comentario 94');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 95, 95, '2017-08-31', 'Comentario 95');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 96, 96, '2017-08-31', 'Comentario 96');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 97, 97, '2017-08-31', 'Comentario 97');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 98, 98, '2017-08-31', 'Comentario 98');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 99, 99, '2017-08-31', 'Comentario 99');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 100, 100, '2017-08-31', 'Comentario 100');

insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 1, 1, '2020-08-31', 'Comentario 1');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 2, 2, '2020-08-31', 'Comentario 2');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 3, 3, '2020-08-31', 'Comentario 3');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 4, 4, '2020-08-31', 'Comentario 4');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 5, 5, '2020-08-31', 'Comentario 5');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 6, 6, '2020-08-31', 'Comentario 6');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 7, 7, '2020-08-31', 'Comentario 7');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 8, 8, '2020-08-31', 'Comentario 8');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 9, 9, '2020-08-31', 'Comentario 9');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 10, 10, '2020-08-31', 'Comentario 10');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 11, 11, '2020-08-31', 'Comentario 11');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 12, 12, '2020-08-31', 'Comentario 12');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 13, 13, '2020-08-31', 'Comentario 13');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 14, 14, '2020-08-31', 'Comentario 14');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 15, 15, '2020-08-31', 'Comentario 15');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 16, 16, '2020-08-31', 'Comentario 16');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 17, 17, '2020-08-31', 'Comentario 17');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 18, 18, '2020-08-31', 'Comentario 18');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 19, 19, '2020-08-31', 'Comentario 19');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 20, 20, '2020-08-31', 'Comentario 20');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 21, 21, '2020-08-31', 'Comentario 21');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 22, 22, '2020-08-31', 'Comentario 22');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 23, 23, '2020-08-31', 'Comentario 23');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 24, 24, '2020-08-31', 'Comentario 24');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 25, 25, '2020-08-31', 'Comentario 25');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 26, 26, '2020-08-31', 'Comentario 26');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 27, 27, '2020-08-31', 'Comentario 27');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 28, 28, '2020-08-31', 'Comentario 28');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 29, 29, '2020-08-31', 'Comentario 29');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 30, 30, '2020-08-31', 'Comentario 30');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 31, 31, '2020-08-31', 'Comentario 31');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 32, 32, '2020-08-31', 'Comentario 32');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 33, 33, '2020-08-31', 'Comentario 33');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 34, 34, '2020-08-31', 'Comentario 34');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 35, 35, '2020-08-31', 'Comentario 35');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 36, 36, '2020-08-31', 'Comentario 36');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 37, 37, '2020-08-31', 'Comentario 37');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 38, 38, '2020-08-31', 'Comentario 38');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 39, 39, '2020-08-31', 'Comentario 39');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 40, 40, '2020-08-31', 'Comentario 40');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 41, 41, '2020-08-31', 'Comentario 41');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 42, 42, '2020-08-31', 'Comentario 42');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 43, 43, '2020-08-31', 'Comentario 43');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 44, 44, '2020-08-31', 'Comentario 44');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 45, 45, '2020-08-31', 'Comentario 45');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 46, 46, '2020-08-31', 'Comentario 46');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 47, 47, '2020-08-31', 'Comentario 47');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 48, 48, '2020-08-31', 'Comentario 48');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 49, 49, '2020-08-31', 'Comentario 49');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 50, 50, '2020-08-31', 'Comentario 50');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 51, 51, '2020-08-31', 'Comentario 51');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 52, 52, '2020-08-31', 'Comentario 52');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 53, 53, '2020-08-31', 'Comentario 53');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 54, 54, '2020-08-31', 'Comentario 54');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 55, 55, '2020-08-31', 'Comentario 55');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 56, 56, '2020-08-31', 'Comentario 56');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 57, 57, '2020-08-31', 'Comentario 57');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 58, 58, '2020-08-31', 'Comentario 58');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 59, 59, '2020-08-31', 'Comentario 59');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 60, 60, '2020-08-31', 'Comentario 60');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 61, 61, '2020-08-31', 'Comentario 61');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 62, 62, '2020-08-31', 'Comentario 62');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 63, 63, '2020-08-31', 'Comentario 63');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 64, 64, '2020-08-31', 'Comentario 64');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 65, 65, '2020-08-31', 'Comentario 65');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 66, 66, '2020-08-31', 'Comentario 66');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 67, 67, '2020-08-31', 'Comentario 67');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 68, 68, '2020-08-31', 'Comentario 68');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 69, 69, '2020-08-31', 'Comentario 69');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 70, 70, '2020-08-31', 'Comentario 70');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 71, 71, '2020-08-31', 'Comentario 71');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 72, 72, '2020-08-31', 'Comentario 72');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 73, 73, '2020-08-31', 'Comentario 73');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 74, 74, '2020-08-31', 'Comentario 74');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 75, 75, '2020-08-31', 'Comentario 75');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 76, 76, '2020-08-31', 'Comentario 76');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 77, 77, '2020-08-31', 'Comentario 77');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 78, 78, '2020-08-31', 'Comentario 78');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 79, 79, '2020-08-31', 'Comentario 79');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 80, 80, '2020-08-31', 'Comentario 80');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 81, 81, '2020-08-31', 'Comentario 81');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 82, 82, '2020-08-31', 'Comentario 82');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 83, 83, '2020-08-31', 'Comentario 83');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 84, 84, '2020-08-31', 'Comentario 84');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 85, 85, '2020-08-31', 'Comentario 85');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 86, 86, '2020-08-31', 'Comentario 86');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 87, 87, '2020-08-31', 'Comentario 87');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 88, 88, '2020-08-31', 'Comentario 88');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 89, 89, '2020-08-31', 'Comentario 89');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 90, 90, '2020-08-31', 'Comentario 90');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 91, 91, '2020-08-31', 'Comentario 91');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 92, 92, '2020-08-31', 'Comentario 92');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 93, 93, '2020-08-31', 'Comentario 93');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 94, 94, '2020-08-31', 'Comentario 94');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 95, 95, '2020-08-31', 'Comentario 95');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 96, 96, '2020-08-31', 'Comentario 96');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 97, 97, '2020-08-31', 'Comentario 97');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 98, 98, '2020-08-31', 'Comentario 98');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 99, 99, '2020-08-31', 'Comentario 99');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 100, 100, '2020-08-31', 'Comentario 100');



INSERT INTO GR10_JUEGO (id_juego,nombre_juego,descripcion_juego,id_categoria) VALUES (101,'LOL','MOBA',18);

INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (101,101, TRUE);
INSERT INTO GR10_JUEGA (id_usuario,id_juego, finalizado) VALUES (102,101, TRUE);


insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 101, 101, '2020-06-01', 'Comentario 101');
insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (102, 101, 102, '2020-06-02', 'Comentario 102');
*/