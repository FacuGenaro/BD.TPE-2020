--DROP DE TABLAS
Drop table gr10_categoria cascade;
Drop table gr10_comenta cascade;
Drop table gr10_comentario cascade;
Drop table gr10_juega cascade;
Drop table gr10_juego cascade;
Drop table gr10_nivel cascade;
Drop table gr10_recomendacion cascade;
Drop table gr10_tipo_usuario cascade;
Drop table gr10_usuario cascade;
Drop table gr10_voto cascade;

--DROP DE TRIGGERS Y FUNCIONES
Drop trigger if exists TR_GR10_COMENTARIO_DIARIO on gr10_comentario;
Drop function if exists fn_gr10_comentario_diario();
Drop trigger if exists TR_GR10_VERIF_RECOM_VOTO on gr10_recomendacion;
Drop function if exists FN_GR10_VERIF_RECOM_VOTO();
Drop trigger if exists TR_GR10_VERIF_JUGO_JUEGO on gr10_comentario;
Drop function if exists FN_GR10_VERIF_JUGO_JUEGO();
Drop trigger if exists TR_GR10_SINCRONIZAR_COMENTA_COMENTARIO on gr10_comentario;
Drop function if exists FN_GR10_SINCRONIZAR_COMENTA_COMENTARIO();

--DROP DE VISTAS
Drop view if exists GR10_COMENTARIOS_ULTIMO_MES;
Drop view if exists GR10_COMENTARIOS_USUARIOS_TODOS_JUEGOS_JUGADOS;
Drop view if exists GR10_RANKING_MEJOR_PUNTUADOS;
Drop view if exists GR10_JUEGOS_MAS_VOTADOS;
