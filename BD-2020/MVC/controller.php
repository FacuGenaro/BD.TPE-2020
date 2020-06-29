<?php
require_once "MVC/model.php";
require_once "MVC/view.php";

class Controller{
    private $model;
    private $view;


    function __construct(){
        $this->model = new model();
        $this->view = new view();
    }

    function getData($id_usuario){
       $data = $this->model->getUsuariosFiltrados($id_usuario);
       $this->view->show($data);
    }
}
?>