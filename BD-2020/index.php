<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TPE BD 2020</title>
    <link rel="stylesheet" href="Css/style.css">
</head>

<body>

    <div class="container">
        <h1>Publicidad de juegos</h1>

        <h3> Consigna 1 </h3>
        <?php

        require_once "MVC/model.php";

        $db = new model();

        $juegosMasVotados = $db->getJuegosVotados();

        echo '<table class="table table-striped">
        <thead>
        <tr>
            <th scope="col">Juego</th>
            <th scope="col">Id Juego</th>
            <th scope="col">Cantidad de votos</th>
        </tr>
        </thead>
        <tbody>';

        foreach ($juegosMasVotados as $juego) {

            echo ' <tr>
                <th>' . $juego['nombre_juego'] . '</th>' .
                '<th>' . $juego['id_juego'] . '</th>' .
                '<th>' . $juego['votos'] . '</th>';
        }

        echo '</tbody></table>'
        ?>

        <h3> Consigna 2 </h3>
        <!-- <form method="get" action="http://dbases.exa.unicen.edu.ar:8080/grupos/grp10/resultadosBusqueda.php"> -->
        <form method="get" action="filtrar">
            <label>Inserte el id de usuario a buscar</label>
            <input type="text" name="id">
            <input class="btn btn-secondary" type="submit" value="Submit">
        </form>
    </div>
</body>

</html>