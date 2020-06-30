<?php
    class model{
        private $db;

        function __construct(){
            $this->db = $this->connect();
        }

        function connect(){
           return new PDO ('pgsql: host=dbases.exa.unicen.edu.ar; port=6432; dbname =cursada; user=unc_248580; password=abuelo123');
        }
    
        public function getJuegosVotados(){
            $sentencia = $this->db->prepare("
                SELECT * FROM unc_248270.gr10_juegos_mas_votados;");
            $sentencia -> execute();
            $juegos = $sentencia->fetchAll();
            return $juegos;
        }

        public function getUsuariosFiltrados($datos){
            $sentencia = $this->db->prepare ("
                select u.id_usuario, u.nombre, u.apellido, u.id_tipo_usuario, count(v.id_voto) as cantidadVotos, count(j.id_juego) as cantidadJuegos
                from gr10_usuario u
                    join gr10_juega j on u.id_usuario = j.id_usuario
                    join gr10_voto v on j.id_usuario = v.id_usuario and j.id_juego = v.id_juego
                where u.id_usuario = ?
                group by u.id_usuario, u.nombre, u.apellido, u.id_tipo_usuario;");
            $sentencia->execute(array($datos));
            $datosUsuario = $sentencia->fetchAll();
            return $datosUsuario;
        }
    
    }

?>
