<#
-------------------------- ENCABEZADO --------------------------

Nombre del script: Ejercicio5.ps1
Número de APL: 2
Número de ejercicio: 5
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

# FUNCIÓN DE AYUDA
<#
.SYNOPSIS
	Dados dos archivos, uno de notas y otro de materias, se pide obtener la cantidad de alumnos que han 
	promocionado, aprobado o desaprobado

.DESCRIPTION
	Dados dos archivos, uno de notas y otro de materias, se pide obtener la cantidad de alumnos que han
	promocionado (ambos parciales/recuperatorio con nota mayor o igual a 7), aptos para rendir final
	(sin final y con ambos parciales/recuperatorio con nota mayor o igual a 4),
	que recursaran (nota menor a 4 en final o en parciales y/o recuperatorios),
	y que abandonaron la materia (sin nota en algun parcial y sin recuperatorio).
	

.PARAMETER notas
	Este parametro corresponde al archivo "notas" y es de caracter obligatorio.
	

.PARAMETER materias
	Este parametro corresponde al archivo "materias" y es de caracter obligatorio.

.EXAMPLE
	./ejercicio5.ps1 [-notas <nombre_arch_notas> -materias <nombre_arch_materias>]
#>


Param (
	[Parameter(Position = 1, Mandatory = $true)]
	[String] $notas,
	[Parameter(Position = 2, Mandatory = $true)]
	[String] $materias
)

function existeDirect([string] $archivo){
   if(!(Test-Path $archivo)){
    Write-Host "No existe el archivo: $archivo"
    return $false
   }
   else{
    return $true
   }
}


 if(!(existeDirect($notas)) -or !(existeDirect($materias))){
    return $false
 }

 $a_materias = Get-Content "$materias"

 $idMateria = @{}
 $descripcion = @{}
 $departamento = @{}

 foreach($linea in $a_materias) {
    $arr = $linea.Split('|')

    if(!($arr[0] -eq "IdMateria")){
        
        $idMateria.Add($arr[0],$arr[2])
        $descripcion.Add($arr[0],$arr[1])
        $departamento.Add($arr[0],$arr[2])
    }
 }


 
 $a_notas = Get-Content "$notas"

 $promocionados = @{}
 $final = @{}
 $abandono = @{}
 $recursa = @{}

 foreach ($linea in $a_notas) {
    $arr = $linea.Split('|') 
    
    #procesamos promocionados
    if( ($arr[2] -ge 7 -and $arr[3] -ge 7) -or ($arr[2] -ge 7 -and $arr[4] -ge 7) -or ($arr[3] -ge 7 -and $arr[4] -ge 7) ){
    #verifica que existe el id de la materia
        if( $idMateria.Contains($arr[1])){

            if($promocionados.ContainsKey($arr[1])){

                $promocionados[$arr[1]]++
            }
            else{
                $promocionados.Add($arr[1],1)
            }
        }
    }

    #procesamos los que van a final
    elseif( (($arr[2] -ge 4 -and $arr[3] -ge 4) -or ($arr[2] -ge 4 -and $arr[4] -ge 4) -or ($arr[3] -ge 4 -and $arr[4] -ge 4)) -and $arr[5] -eq "" ){
        #verifica que existe el id de la materia
        if( $idMateria.Contains($arr[1])){
            if($final.ContainsKey($arr[1])){
                
                $final[$arr[1]]++
            }
            else{
                $final.Add($arr[1],1)
            }
        }
    }

    #procesamos los que abandonan
    elseif( ($arr[2] -eq "" -and $arr[3] -eq "") -or ($arr[2] -eq "" -and $arr[4] -eq "") -or ($arr[3] -eq "" -and $arr[4] -eq "") ){
        #verifica que existe el id de la materia
        if( $idMateria.Contains($arr[1])){
            if($abandono.ContainsKey($arr[1])){
                
                $abandono[$arr[1]]++
            }
            else{
                $abandono.Add($arr[1],1)
            }
        }
    }

    #procesamos recursantes

    elseif( $arr[5] -eq "" ){
        #verifica que existe el id de la materia
        if( $idMateria.Contains($arr[1])){
            if($recursa.ContainsKey($arr[1])){

                $recursa[$arr[1]]++
            }
            else{
                $recursa.Add($arr[1],1)
            }
        }
    }

}


#Creo un nuevo elemento con valor 0 para cada materia que no tenga
#alumnos de dicha condicion (para que en la salida muestre 0 y no null) 

$ids = $idMateria.Keys

foreach($elemento in $ids){
    if(!($promocionados.ContainsKey($elemento))){
        $promocionados.Add($elemento,0)
    }
    if(!($final.ContainsKey($elemento))){
        $final.Add($elemento,0)
    }
    if(!($recursa.ContainsKey($elemento))){
        $recursa.Add($elemento,0)
    }
    if(!($abandono.ContainsKey($elemento))){
        $abandono.Add($elemento,0)
    }
}

#Obtengo todos los numeros de departamento
$deptos = $departamento.Values | sort -Unique
#Obtengo todos los ids de las materias
$ids = $idMateria.Keys | sort

$arrayDeptos = @()

foreach($depto_index in $deptos){

     #$salida+= "departamento: = $depto_index"

     $contenidoDepto = @()
     $contenidoDepto = @{"id" = $depto_index}

     $notasPorDepto = @()
     foreach($id_index in $ids){
      
        #Si el depto de la materia es igual al depto actual
        if($idMateria[$id_index] -eq $depto_index){

            $notasPorDepto += [ordered]@{
                'idMateria' = $id_index
                'descripcion' = $descripcion[$id_index]
                'final' = $final[$id_index]
                'recursaron' = $recursa[$id_index]
                'abandonaron' = $abandono[$id_index]
                'promocionados' = $promocionados[$id_index]
                }
       }
       
    }

    $contenidoDepto += @{"notas" = $notasPorDepto}
    $arrayDeptos += $contenidoDepto
}

$final = @{"departamentos" = $arrayDeptos}

$final | ConvertTo-Json -depth 10

$final | ConvertTo-Json -depth 10 | Out-File salida.json

# -------------------- FIN DE ARCHIVO --------------------