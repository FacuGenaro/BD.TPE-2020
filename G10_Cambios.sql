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
        check ( (fecha_primer_com < fecha_ultimo_com) or (fecha_ultimo_com is null));

--Test
--update gr10_comenta
--set fecha_primer_com = '2020-06-24', fecha_ultimo_com = '2020-06-26'
--where id_usuario = 1;

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

 B. b. Cada usuario sólo puede comentar una vez al día cada juego.

 Esta restricción es de tabla ya que afecta a toda la tabla en vez de solo una tupla
 */

--Verificar esta RI (esta hay que rehacerla directamente creo)

--alter table gr10_comentario
--add constraint GR10_CHK_COMENTARIO_DIARIO
--check ( exists(
--select 1
--from gr10_comentario
--where (fecha_comentario = current_date)
--group by id_usuario;
--                    )
--    );

create or replace function FN_GR10_COMENTARIO_DIARIO()
    returns trigger as
$$
begin
    if exists(
            select 1
            from gr10_comentario
            where id_usuario = new.id_usuario
              and fecha_comentario = new.fecha_comentario
        )
    then
        raise exception 'El usuario % ya comentó este juego hoy %', new.id_usuario, new.fecha_comentario;
    end if;
    return new;
end
$$
    language 'plpgsql';

create trigger TR_GR10_COMENTARIO_DIARIO
    before insert
    on gr10_comentario
    for each row
execute procedure FN_GR10_COMENTARIO_DIARIO();

/*
CASO DE PRUEBA:

Si intento insertar un comentario, el trigger verifica en cada fila si existe un comentario del mismo
usuario con la nueva fecha del comentario (que sería la fecha actual) y si existe, no permite
la insercion del comentario

El siguiente insert no cumple la condicion del trigger ya que la fecha cargada en la bd para
el comentario del usuario 1 en el juego 1 es current_date por lo tanto dará error
 */

--insert into gr10_comentario(id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (1, 1, 5, current_date, 'este comentario falla');

/*
En cambio esta sentencia quiere insertar un comentario con una fecha futura a la cargada en la bd
por eso será insertado sin errores
 */

--insert into gr10_comentario(id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (1, 1, 5, '2020-07-15', 'este comentario funciona');

/*
Para verificar:
 */

--select *
--from gr10_comentario;

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

 B.c. Un usuario no puede recomendar un juego si no ha votado previamente dicho juego.

 Esta es una restriccion global ya que involucra más de una tabla
 */

--Verificar esta RI Tambien
--create
--assertion G10_CHK_VOTO
--check(exists(
--select *
--from gr10_voto v
--         join gr10_recomendacion r on v.id_usuario = r.id_usuario and v.id_juego = r.id_juego
--where (v.id_usuario = r.id_usuario)
--  and (v.id_juego = r.id_juego)
--));

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
    before insert
    on gr10_recomendacion
    for each row
execute procedure FN_GR10_VERIF_RECOM_VOTO();

/*
CASO DE PRUEBA:

Si intento insertar una recomendacion pero no tiene voto asociado da error, en esta caso intento
insertar una recomendacion de parte del usuario 2 al juego 3 pero se activa la excepcion del
trigger ya que el juego no posee un voto del usuario
*/

--insert into gr10_recomendacion (id_recomendacion, email_recomendado, id_usuario, id_juego) values (5, 'RecoError', 2, 3);

/*
En cambio si intento insertar una recomendacion de la cual existe el voto, puedo hacerlo
sin problemas como debería ser
 */

--insert into gr10_recomendacion (id_recomendacion, email_recomendado, id_usuario, id_juego) values (5, 'RecoSuccess', 2, 2);

/*
 Para verificar
 */

--select *
--from gr10_recomendacion;

--select *
--from gr10_voto;

/*
##############################################################################################################
##############################################################################################################
##############################################################################################################

B.d. Un usuario no puede comentar un juego que no ha jugado.

Es una restriccion de tabla ya que debo verificar en la tabla juega para luego insertar el comentario en la tabla comentario
 */

--Verificar esta RI Tambien
--create
--assertion G10_CHK_VOTO
--check(exists(
--select *
--from gr10_juega j
--        join gr10_usuario u on j.id_usuario = u.id_usuario
--         join gr10_comenta c1 on u.id_usuario = c1.id_usuario
--         join gr10_comentario c2 on c1.id_usuario = c2.id_usuario and c1.id_juego = c2.id_juego
--where (j.id_usuario = c2.id_usuario)
--  and (j.id_juego = c2.id_juego)
--  and (j.finalizado = 't')));

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
                     and finalizado = 't'
        ))
    then
        raise exception 'El usuario % no puede comentar porque nunca jugó al juego %', new.id_usuario, new.id_juego;
    end if;
    return new;
end
$$
    language 'plpgsql';

create trigger TR_GR10_VERIF_JUGO_JUEGO
    before insert
    on gr10_comentario
    for each row
execute procedure FN_GR10_VERIF_JUGO_JUEGO();

/*
CASO DE PRUEBA:

Este insert funciona ya que el usuario 3 está cargado en la tabla juega con el valor
finalizado = true por lo tanto se agrega correctamente
 */


--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (3, 3, 28, '2020-08-17', 'comentarioFunciona');

/*
Este insert no funciona ya que el usuario 3 está cargado en la tabla juega con el valor
finalizado = false, por lo tanto se muestra la excepción del trigger ya que no se cumple la condicion
establecida
 */

--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (2, 2, 23, '2020-08-17', 'comentarioFalla');

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
--

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
tabla Comenta como indica la consigna
 */

--insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (62, 62, 1, '2020-08-31', 'comentario funcional');

/*
Este comentario se insertó correctamente ya que no tiene conflictos con otros triggers y si no
existe la entrada en la tabla Comenta, se genera automaticamente como lo indica el inciso A
 */

insert into gr10_comentario (id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (62, 62, 2, '2020-09-01', 'comentario actualizado en tabla comenta');

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
    FROM gr10_usuario u, (SELECT id_usuario
                          FROM (SELECT id_usuario, id_juego
                                FROM gr10_comentario
                                GROUP BY id_usuario, id_juego) AS t1
                          GROUP BY t1.id_usuario
                          HAVING COUNT(*) = (SELECT COUNT(*) FROM gr10_juego)) AS u1
    WHERE u.id_usuario = u1.id_usuario;