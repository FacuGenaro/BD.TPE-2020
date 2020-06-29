set search_path = unc_248270;
--set search_path = unc_248580;
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

--insert into gr10_comentario(id_usuario, id_juego, id_comentario, fecha_comentario, comentario) values (101, 1, 1, '2020-08-31', 'este comentario falla');

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
tabla Comenta como indica la consigna
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
