<?php
require_once "MVC/controller.php";

$id_usuario = $_GET["id"];

$controller = new controller();

if (isset ($id_usuario)){
    $controller->getData($id_usuario);
}
     
?>