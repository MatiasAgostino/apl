<#
-------------------------- ENCABEZADO --------------------------
Nombre del script: ejercicio2.ps1
Número de APL: 2
Número de ejercicio: 2
Número de entrega: Entrega
---------------- INTEGRANTES DEL GRUPO ----------------
Apellido, Nombre          | DNI
Agostino, Matías          | 43861796
Colantonio, Bruno Ignacio | 43863195
Fernández, Rocío Belén    | 43875244
Galo, Santiago Ezequiel   | 43473506
Panigazzi, Agustín Fabián | 43744593
-------------------- FIN DE ENCABEZADO --------------------
#>

<#
	.Synopsis
	Dados archivos de log donde se registraron todas las llamadas realizadas en una semana por un call center, el script obtiene y muestra por pantalla los siguientes datos:
	1. Promedio de tiempo de las llamadas realizadas por día
	2. Promedio de tiempo y cantidad por usuario por día
	3. Los 3 usuarios con más llamadas en la semana
	4. Cuántas llamadas no superan la media de tiempo por día
	5. El usuario que tiene más cantidad de llamadas por debajo de la media en la semana
    .DESCRIPTION
    El script cuenta con un parametro obligatorio:
    La ruta, en la cual se le indica la direccion de los archivos a analizar.
	.Example
	.\ejercicio2.ps1 -logs "logs"
#>

Param (
	[Parameter(Position = 1, Mandatory = $true)]
    [String] $logs
)


function validarDirectorio(){
    if(!(Test-Path $logs)){
        Write-Host "---¡EL DIRECTORIO INDICADO NO EXISTE!---" -ForegroundColor Red
        exit
    }
}


function mostrarResultadosDia(){

param(
    [hashtable] $cantLlamadasXUsuarioDia,
    [hashtable]$promedioTiempoXUsuarioDia,
    [string]$fechaAnterior,
    [int]$promedioTiempoDia,
    [int]$cantLlamadasBajoMediaDia
    )


    $usuariosDelDia = $cantLlamadasXUsuarioDia.Keys

    foreach($usuario in $usuariosDelDia){
        $promedioTiempoXUsuarioDia[$usuario]/= $cantLlamadasXUsuarioDia[$usuario]
    }

    Write-Host 
   Write-Host "--------------- Fecha: $fechaAnterior ---------------" -ForegroundColor Green
   Write-Host 

   #Convierto los segundos a una hora real
    $promDia = New-TimeSpan -Seconds $promedioTiempoDia 


    Write-Host "1. Promedio de tiempo de las llamadas realizadas en el dia: $promDia"-ForegroundColor Green
    Write-Host "2. Usuario | Promedio de tiempo | Cantidad de llamadas"-ForegroundColor Green

    #Para cada usuario del dia muestro el nombre, promedio y cant de llamadas
    foreach($usuario in $usuariosDelDia){
     $prom = New-TimeSpan -Seconds $promedioTiempoXUsuarioDia[$usuario]
        Write-Host $usuario '|' $prom '|' $cantLlamadasXUsuarioDia[$usuario]-ForegroundColor Green
    }


    Write-Host "4. Cantidad de llamadas que no superan la media de tiempo por día: $cantLlamadasBajoMediaDia"-ForegroundColor Green

    Write-Host
    Write-Host
}

function mostmostrarResultadosSemana(){

   param(
    [hashtable] $cantLlamadasXUsuarioSemana,
    [hashtable] $cantLlamadasBajoMediaXUsuarioSemana
    )

   Write-Host "------------------------------------------------------ Resumen de la Semana ------------------------------------------------------" -ForegroundColor Yellow
   Write-Host

   #Ordeno la hashtable por valor en orden descendente(en las primeras 3 posiciones tengo a los 3 usuarios con mas llamadas en la semana)
   $usuariosDeLaSemana = $cantLlamadasXUsuarioSemana.GetEnumerator() | sort -Property Value -Descending
   #Ordeno la hashtable por valor en orden descendente (en el primer lugar tengo al que mas llamadas por debajo de la media tuvo)
   $masLlamadasPorDebajo = $cantLlamadasBajoMediaXUsuarioSemana.GetEnumerator() | sort -Property Value -Descending

   Write-Host "3. Los 3 usuarios con más llamadas en la semana:"-ForegroundColor Yellow
   Write-Host
   Write-Host "Usuario | Cantidad de llamadas"-ForegroundColor Yellow
   
   Write-Host $usuariosDeLaSemana[0].Key '|' $usuariosDeLaSemana[0].Value-ForegroundColor Yellow
   Write-Host $usuariosDeLaSemana[1].Key '|' $usuariosDeLaSemana[1].Value-ForegroundColor Yellow
   Write-Host $usuariosDeLaSemana[2].Key '|' $usuariosDeLaSemana[2].Value-ForegroundColor Yellow

   Write-Host 

   Write-Host "5. Usuario con más cantidad de llamadas por debajo de la media en la semana:"-ForegroundColor Yellow
   Write-Host
   Write-Host "Usuario | Cantidad de llamadas por debajo de la media en la semana"-ForegroundColor Yellow

   Write-Host $masLlamadasPorDebajo[0].Key '|' $masLlamadasPorDebajo[0].Value-ForegroundColor Yellow

   Write-Host
   Write-Host

   }


function calcularSalida(){

#Obtengo todos los archivos del directorio
$files = Get-ChildItem -Path $logs | Select-Object -ExpandProperty FullName

foreach($elemento in $files){

#Proceso solo archivos dentro del directorio (si es un sub-directorio, no lo tengo en cuenta)
if(!((Get-Item $elemento).PSIsContainer)){

#Proceso solo archivos que contengan algo (si es un archivo vacio, no lo tengo en cuenta)
if((Get-Item $elemento).Length -gt 0){

    Write-Host "Procesando $elemento" -ForegroundColor magenta

#Para cada archivo, creo un objeto nuevo con sus propiedades, para luego poder ordenarlo
$registros = @()

$contenido = Get-Content $elemento | % {
  $dia = $($_ -split ' ')[0]
  $horaAux = $($_ -split ' ')[1]
  $hora = $horaAux -split '-'[0]
  $persona = $($_ -split '-')[3]

  $obj = New-Object PSObject -property @{dia=$dia;persona=$persona;hora=$hora;reg=$_}
  $registros += ,$obj
}


#Ordeno los registros por dia, por persona y por hora
$contenido = $registros | sort dia,persona,hora | select -ExpandProperty reg

#Variables donde voy a almacenar los resultados por dia
[int]$cantLlamadasDia = 0
[double]$promedioTiempoDia = 0
[int]$cantLlamadasBajoMediaDia = 0

#Hashtables donde cada key es un usuario
$cantLlamadasXUsuarioDia = @{}
$promedioTiempoXUsuarioDia = @{}
$cantLlamadasXUsuarioSemana = @{}
$cantLlamadasBajoMediaXUsuarioSemana = @{}



#Obtengo la primera fecha para luego cortar por dia y mostrar los resultados
$fechaAux = $contenido[0].Split(" ")
[string]$fechaAnterior = $fechaAux[0]

#Recorro todos los registros del archivo de logs
for( $i=0; $i -lt $contenido.Length; $i+=2){

#Guardo la fecha para procesar por dia
$fechaAux = $contenido[$i].Split(" ")
[string]$fecha = $fechaAux[0]


#-------SI TERMINO EL DIA, ENTONCES PROCESO LOS DATOS DEL DIA------
if($fechaAnterior -ne $fecha){

    #Obtengo el promedio del dia
    $promedioTiempoDia /= $cantLlamadasDia

    #Hago el mismo ciclo que abajo, para obtener los que esten debajo de la media
    for( $k=0; $k -lt $contenido.Length; $k+=2){

        $fechaAux_ = $contenido[$k].Split(" ")
        $fechaAux2 = $fechaAux_[0]

        #Solo proceso los que se encuentren en el dia procesado
        if($fechaAux2 -eq $fechaAnterior){

        $hora1 = $contenido[$k].Split("-")
        $nombreAux = $hora1[3]
        $hora1 = $hora1[2].Split(" ")
        $hora1 = $hora1[1]
        $hora1 = $hora1.Split(":")
        [int]$horasAux=[int]$hora1[0]*3600
        [int]$minAux=[int]$hora1[1]*60
        [int]$segAux=[int]$hora1[2]
        $hora1 = $horasAux+$minAux+$segAux

        $hora2 = $contenido[$k+1].Split("-")
        $hora2 = $hora2[2].Split(" ")
        $hora2 = $hora2[1]
        $hora2 = $hora2.Split(":")
        [int]$horasAux=[int]$hora2[0]*3600
        [int]$minAux=[int]$hora2[1]*60
        [int]$segAux=[int]$hora2[2]
        $hora2 = $horasAux+$minAux+$segAux

        [int]$duracion = $hora2-$hora1

        if($duracion -lt $promedioTiempoDia){
            $cantLlamadasBajoMediaDia++
            #Si no existe la key, creo un nuevo elemento en la tabla
            if(!($cantLlamadasBajoMediaXUsuarioSemana.ContainsKey($nombreAux))){

            $cantLlamadasBajoMediaXUsuarioSemana.Add($nombreAux,1)
            }
            #Si existe, lo sumo
        else{
    
            $cantLlamadasBajoMediaXUsuarioSemana[$nombreAux]++
            }
        }
      }
    }


    mostrarResultadosDia $cantLlamadasXUsuarioDia $promedioTiempoXUsuarioDia $fechaAnterior $promedioTiempoDia $cantLlamadasBajoMediaDia

    #Borro los datos del dia anterior, ya que comienzo a procesar otro dia
    $cantLlamadasDia = 0
    $promedioTiempoDia = 0
    $cantLlamadasBajoMediaDia = 0

    $cantLlamadasXUsuarioDia.Clear()
    $promedioTiempoXUsuarioDia.Clear()

    #Actualizo la fecha anterior por la actual (dado a que ya estoy procesando una nueva)
    $fechaAnterior = $fecha
    Write-Host $contenido[$i] -ForegroundColor Green
    Write-Host $contenido[$i+1] -ForegroundColor Green

    }
else{
    #Actualizo la fecha anterior
    $fechaAnterior = $fecha
    Write-Host $contenido[$i] -ForegroundColor Green
    Write-Host $contenido[$i+1] -ForegroundColor Green
    }


$hora1 = $contenido[$i].Split("-")
#Guardo el nombre para luego usar de key
$nombre = $hora1[3]
#Me quedo solo con la hora y la transformo a segundos
$hora1 = $hora1[2].Split(" ")
$hora1 = $hora1[1]
$hora1 = $hora1.Split(":")
[int]$horasAux=[int]$hora1[0]*3600
[int]$minAux=[int]$hora1[1]*60
[int]$segAux=[int]$hora1[2]
$hora1 = $horasAux+$minAux+$segAux

#Hago lo mismo para la hora de fin de la llamada
$hora2 = $contenido[$i+1].Split("-")
$hora2 = $hora2[2].Split(" ")
$hora2 = $hora2[1]
$hora2 = $hora2.Split(":")
[int]$horasAux=[int]$hora2[0]*3600
[int]$minAux=[int]$hora2[1]*60
[int]$segAux=[int]$hora2[2]
$hora2 = $horasAux+$minAux+$segAux


#Duracion de la llamada en segundos
[int]$duracion = $hora2-$hora1

#Sumo a los promedios
$promedioTiempoDia+=$duracion
#Si no existe la key, creo un nuevo elemento
if(!($promedioTiempoXUsuarioDia.ContainsKey($nombre))){

    $promedioTiempoXUsuarioDia.Add($nombre,$duracion)
    }
#Si existe, lo sumo
else{
    
    $promedioTiempoXUsuarioDia[$nombre]+=$duracion
    }

#Incremento cantidad de llamadas por dia, por usuario por dia, y por usuario por semana
$cantLlamadasDia++


if(!($cantLlamadasXUsuarioDia.ContainsKey($nombre))){
    $cantLlamadasXUsuarioDia.Add($nombre,1)
    }
else{
    $cantLlamadasXUsuarioDia[$nombre]++
    }


if(!($cantLlamadasXUsuarioSemana.ContainsKey($nombre))){
    $cantLlamadasXUsuarioSemana.Add($nombre,1)
    }
else{
    $cantLlamadasXUsuarioSemana[$nombre]++
    }

}

#----- FIN DEL CICLO QUE RECORRE POR ARCHIVO (MUESTRO ULTIMA FECHA DEL ARCHIVO)-----


$promedioTiempoDia /= $cantLlamadasDia

for( $k=0; $k -lt $contenido.Length; $k+=2){

    $fechaAux_ = $contenido[$k].Split(" ")
    $fechaAux2 = $fechaAux_[0]

    if($fechaAux2 -eq $fecha){

    $hora1 = $contenido[$k].Split("-")
    $nombreAux = $hora1[3]
    $hora1 = $hora1[2].Split(" ")
    $hora1 = $hora1[1]
    $hora1 = $hora1.Split(":")
    [int]$horasAux=[int]$hora1[0]*3600
    [int]$minAux=[int]$hora1[1]*60
    [int]$segAux=[int]$hora1[2]
    $hora1 = $horasAux+$minAux+$segAux

    $hora2 = $contenido[$k+1].Split("-")
    $hora2 = $hora2[2].Split(" ")
    $hora2 = $hora2[1]
    $hora2 = $hora2.Split(":")
    [int]$horasAux=[int]$hora2[0]*3600
    [int]$minAux=[int]$hora2[1]*60
    [int]$segAux=[int]$hora2[2]
    $hora2 = $horasAux+$minAux+$segAux

    [int]$duracion = $hora2-$hora1

    if($duracion -lt $promedioTiempoDia){
        $cantLlamadasBajoMediaDia++
        if(!($cantLlamadasBajoMediaXUsuarioSemana.ContainsKey($nombreAux))){
            $cantLlamadasBajoMediaXUsuarioSemana.Add($nombreAux,1)
            }
        else{
            $cantLlamadasBajoMediaXUsuarioSemana[$nombreAux]++
            }
    }
  }
  
}

   mostrarResultadosDia $cantLlamadasXUsuarioDia $promedioTiempoXUsuarioDia $fechaAnterior $promedioTiempoDia $cantLlamadasBajoMediaDia

   #Como termino el archivo, termino una semana. Por ende, muestro el resumen semanal

   mostmostrarResultadosSemana $cantLlamadasXUsuarioSemana $cantLlamadasBajoMediaXUsuarioSemana

}
else{
    Write-Host "---El archivo $elemento esta vacio---" -ForegroundColor magenta

}
}
}

}

validarDirectorio
calcularSalida

# -------------------- FIN DE ARCHIVO --------------------
