<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css" integrity="sha384-9aIt2nRpC12Uk9gS9baDl411NQApFmC26EwAOH8WgZl5MYYxFfc+NcPb1dKGj7Sk" crossorigin="anonymous">
    <title>TPE BD 2020</title>
</head>

<body>
    <?php
    class View
    {
        function __construct()
        {
        }

        function show($data)
        {
            echo '<div class="container mt-3">
    
        <table class="table table-striped">
        <thead>
        <tr>
            <th scope="col">Nombre</th>
            <th scope="col">Apellido</th>
            <th scope="col">Id Usuario</th>
            <th scope="col">Tipo usuario</th>
            <th scope="col">Juegos jugados</th>
            <th scope="col">Juegos votados</th>
        </tr>
        </thead>
        <tbody>';
            foreach ($data as $datos) {
                echo ' <tr>
                <th>' . $datos['nombre'] . '</th>' .
                    '<th>' . $datos['apellido'] . '</th>' .
                    '<th>' . $datos['id_usuario'] . '</th>' .
                    '<th>' . $datos['id_tipo_usuario'] . '</th>' .
                    '<th>' . $datos['cantidadjuegos'] . '</th>' .
                    '<th>' . $datos['cantidadvotos'] . '</th>';

                echo ' </tbody></table> </div>';
            }
        }
    }

    ?>
</body>

</html>