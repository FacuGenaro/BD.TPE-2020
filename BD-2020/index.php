<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TPE BD 2020</title>
    <link rel="stylesheet" href="Css/style.css">
</head>
<body>
    
<h1> Consigna 1 </h1>
<?php
require_once "MVC/model.php";

    $db = new model();

    $juegosMasVotados = $db->getJuegosVotados();

echo '<table>
        <tr>
            <th>Juego</th>
            <th>Id Juego</th>
            <th>Cantidad de votos</th>
        </tr>';
    foreach ($juegosMasVotados as $juego){
        echo ' <tr>
                <th>' . $juego['nombre_juego'] . '</th>'.
                '<th>' . $juego['id_juego'] . '</th>'.
                '<th>' . $juego['votos'] . '</th>';
                
    }
echo '</table>'
?>

<h1> Consigna 2 </h1>
<!-- <form method="get" action="http://dbases.exa.unicen.edu.ar:8080/grupos/grp10/resultadosBusqueda.php"> -->
<form method="get" action="filtrar">
    <label>Inserte el id de usuario a buscar</label>
    <input type="text" name="id"><br>
    <input type="submit" value="Submit">
</form>
</body>
</html>