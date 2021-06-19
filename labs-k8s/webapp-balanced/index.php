<html>
 <head>
   <title>Webapp (PHP powered)</title>
 </head>

  <body>
<?php

 echo "¡Hola mundo! <br><br>";

 $ipaddress=$_SERVER['SERVER_ADDR'];
 echo "Esta petición está siendo atendida por el contenedor con ip: ".$ipaddress.".<br><br>";

?>

</body>
</html>
