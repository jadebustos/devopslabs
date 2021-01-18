<html>
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