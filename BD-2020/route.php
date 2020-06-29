<?php
require_once "MVC/controller.php";
require_once "index.php";

define('HOME', 'Location: http://' . $_SERVER["SERVER_NAME"] . dirname($_SERVER["PHP_SELF"]));


$controller = new controller();

$action = $_GET["action"];

if ($action == "")
    header('HOME');
else if (isset ($action)){
    $controller->getData();
}
     
?>