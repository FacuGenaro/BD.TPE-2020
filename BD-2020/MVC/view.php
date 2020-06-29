<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TPE BD 2020</title>
</head>
<body>
<h1> Resultados consigna 2 </h1>
<?php
class View{
    function __construct(){

    }

    function show($data){
        echo '<table>
        <tr>
            <th>Nombre</th>
            <th>Apellido</th>
            <th>Id Usuario</th>
            <th>Tipo usuario</th>
            <th>Juegos jugados</th>
            <th>Juegos votados</th>
        </tr>';
    foreach ($data as $datos){
        echo ' <tr>
                <th>' . $datos['nombre'] . '</th>'.
                '<th>' . $datos['apellido'] . '</th>'.
                '<th>' . $datos['id_usuario'] . '</th>'.
                '<th>' . $datos['id_tipo_usuario'] . '</th>'.
                '<th>' . $datos['cantidadjuegos'] . '</th>'.
                '<th>' . $datos['cantidadvotos'] . '</th>';           
   
        echo '</table>';
        }
    }
}

?>
</body>
</html>