<html>
  <!--
  # Copyright 2022 (c) José Ángel de Bustos Pérez 
  #   Author: José Ángel de Bustos Pérez <jadebustos@gmail.com>
  #
  # This workshop is free software: you can redistribute it and/or modify it under the terms of 
  # the GNU General Public License v3 as published by the Free Software Foundation.
  # This workshop is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
  # without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  # See the GNU General Public License v3 for more details.

  # You should have received a copy of the GNU General Public License.
  # If not, see https://www.gnu.org/licenses/gpl-3.0.en.html.
  -->  
 <head>
   <title>Webapp (PHP powered)</title>
 </head>

  <body>
<?php

 echo "¡Hola mundo! <br><br>";

 $port=$_ENV["PORT"];
 echo "No importa en que puerto me busques, en realidad estoy escuchando en el puerto ".$port.".<br><br>";

 echo "Eran ";
 for($i = 1; $i < 4; $i++) {
   echo $i.", ";
 }

 echo "los tres Mosqueteros.";

?>

</body>
</html>