<#
-------------------------- ENCABEZADO --------------------------

Nombre del script: ejercicio4.ps1
N�mero de APL: 2
N�mero de ejercicio: 4
N�mero de entrega: Entrega

---------------- INTEGRANTES DEL GRUPO ----------------

Apellido, Nombre          | DNI
Agostino, Mat�as          | 43861796
Colantonio, Bruno Ignacio | 43863195
Fern�ndez, Roc�o Bel�n    | 43875244
Galo, Santiago Ezequiel   | 43473506
Panigazzi, Agust�n Fabi�n | 43744593

-------------------- FIN DE ENCABEZADO --------------------
#>

<#
	.Synopsis
	Este es un script que cuenta la cantidad de lineas de codigo y de comentarios que poseen los archivos en la ruta pasada
	Solo analiza los archivos con las extensiones pasadas por parametro, y lo hace recursivamente para cada subdirectorio

    .DESCRIPTION
    El script cuenta con dos parametros obligatorios:
    La ruta, en la cual se le indica la direccion de los archivos a analizar.
    Las extensiones, en donde se le indica las extensiones de los archivos a analizar. 
    Solo tendr� en cuenta archivos con esas extensiones.
    Las extensiones deben estar pasadas separadas por coma como se muestra en los ejemplos.
    En caso de no proporcionarlas correctamente se pedira que las ingrese una por una, finalizando con un doble enter.

	.Example
	.\ejercicio4.ps1 -ruta "lote\js" -ext js 

	.Example
	.\ejercicio4.ps1 -ruta "lote\c" -ext c

	.Example
	.\ejercicio4.ps1 -ruta "lote" -ext js,c,java
#>

Param (
	[Parameter(Position = 1, Mandatory = $true)]
    [String] $ruta,
    [Parameter(Position = 2, Mandatory = $true)]
    [String[]] $ext
)

function validarDirectorio(){
    if(!(Test-Path $ruta)){
        Write-Host "---LA RUTA INDICADA NO EXISTE!---"
        exit
    } 
    elseif ( ! (Get-Acl $ruta).Access ) {
        Write-Host "No se tienen los permisos necesarios para trabajar sobre el directirio" $ruta
        exit
    }
}

function calcularComentariosMultilinea([ref]$comentarios, [ref]$codigos, [string]$linea, [ref]$multilineaActivada, [boolean]$dobleTipoDeComentario){
    #Ejemplo: ALGO /* ALGO */ ALGO
    if($linea -match "(.*)\/\*(.*)\*\/(.*)"){
        $match = select-string "(.*)\/\*(.*)\*\/(.*)" -inputobject $linea 
        if(!$dobleTipoDeComentario){
            if(![string]::IsNullOrWhiteSpace($match.Matches.groups[1])){
                $codigos.value++
            } elseif(![string]::IsNullOrWhiteSpace($match.Matches.groups[3])){
                $codigos.value++
            }
        }
        $comentarios.value++
    #Ejemplo: ALGO /* ALGO
    }else{
        $match = select-string "(.*)\/\*(.*)" -inputobject $linea 
        if(![string]::IsNullOrWhiteSpace($match.Matches.groups[1])){
            $codigos.value++
        }
        $multilineaActivada.value = $True
        $comentarios.value++
    }
}

function calcularComentariosDobleBarra([ref]$comentarios, [ref]$codigos, [string]$linea){
    $match = select-string "(.*)\/\/(.*)" -inputobject $linea 
        if(![string]::IsNullOrWhiteSpace($match.Matches.groups[1])){
            $codigos.value++      
        }
        $comentarios.value++
}

function calcularSalida(){
    $cantArchivos=0
    $comentariosTotales=0
    $codigosTotales=0
    $lineasTotales=0
    
    if($ext.Count -lt 1){
        return
    }

    foreach($extension in $ext){
        #varExtension es una variable a simple modo de ayuda para ejecutar el comando Where-Object
        $varExtension = "."+$extension
        #conjunto representa un listado de todos los archivos que cumplan con la extension actual del foreach
        $conjunto = Get-ChildItem -Path $ruta -Recurse -ErrorAction SilentlyContinue -Filter *.$extension | Select-Object -ExpandProperty FullName
    
        #Se hace un foreach de conjunto para obtener el contenido de cada archivo y analizar los comentarios
        foreach($elemento in $conjunto){
            Write-Host "`nAnalizando archivo: " $elemento
            
            $cantArchivos++
            $comentarios = 0
            $codigos = 0
            $multilineaActivada = $False
    
            $contenidoDelArchivo = Get-Content $elemento
           
            #Recorre linea por linea el archivo
            foreach($linea in $contenidoDelArchivo){
                $lineaVacia=$false
                #$match = select-string "(.*)\/\*(.*)" -inputobject $linea
                #Write-Host $match.Matches.groups[1]
                
                if(!$multilineaActivada){
                    $dobleTipoDeComentario = $False
                    #Si hay dos tipos de comentarios en una misma linea
                    if( ($linea -match "\/\*") -and ($linea -match "\/\/") ){
                        $dobleTipoDeComentario = $true
                        $largoComentarioBarras = $linea.IndexOf("//")
                        $largoComentarioMultiple = $linea.IndexOf("/*")
                        #Si se encuentra primero /*
                        if($largoComentarioBarras -gt $largoComentarioMultiple){
                            calcularComentariosMultilinea ([ref]$comentarios) ([ref]$codigos) $linea ([ref]$multilineaActivada) $dobleTipoDeComentario
                        }
                        else{
                            calcularComentariosDobleBarra ([ref]$comentarios) ([ref]$codigos) $linea
                        }
                    } 
                    #Si hay del tipo /*
                    elseif($linea -match "\/\*"){
                        calcularComentariosMultilinea ([ref]$comentarios) ([ref]$codigos) $linea ([ref]$multilineaActivada) $dobleTipoDeComentario
                    } 
                    #Si hay del tipo //
                    elseif($linea -match "\/\/"){
                        calcularComentariosDobleBarra ([ref]$comentarios) ([ref]$codigos) $linea
                    }
                    else{
                        $match = select-string "(.*)" -inputobject $linea 
                        if(![string]::IsNullOrWhiteSpace($match.Matches.groups[1])){
                            $codigos++     
                        } else {
                            $lineaVacia=$true
                        }
                    }
                }
                elseif($multilineaActivada){
                    if(($linea -match "\*\/") -and ($linea -match "\/\/") ){
                        $multilineaActivada = $False
                        if($linea -match "(.*)\*\/(.*)\/\/"){
                            $match = select-string "(.*)\*\/(.*)\/\/" -inputobject $linea
                            if(![string]::IsNullOrWhiteSpace($match.Matches.groups[2])){
                                $codigos++
                            }
                        }
                    }
                    elseif($linea -match "\*\/"){
                        $multilineaActivada = $False
                        #Ejemplo: ALGO */ ALGO
                        $match = select-string "(.*)\*\/(.*)" -inputobject $linea
                        if(![string]::IsNullOrWhiteSpace($match.Matches.groups[2])){
                            $codigos++
                        }
                    }
                    $comentarios++
                }
                
                if(!$lineaVacia){
                    $lineasTotales++
                }
           }
    
           Write-Host "Cantidad de comentarios: " $comentarios
           Write-Host "Lineas de codigo: " $codigos
           Write-Host "`n"
           $comentariosTotales += $comentarios
           $codigosTotales += $codigos
        }
    }
    
    if($lineasTotales -gt 0){
        $porcentajeComentarios = ($comentariosTotales/$lineasTotales)*100
        $porcentajeCodigo = ($codigosTotales/$lineasTotales)*100
    } else {
        $porcentajeCodigo = 0
        $porcentajeComentarios = 0
    }
    
    if($cantArchivos -gt 0){
        Write-Host "---------Informacion total---------"
        Write-Host "Archivos totales analizados: " $cantArchivos
        Write-Host "Lineas totales analizadas: " $lineasTotales
        Write-Host "Comentarios totales: " $comentariosTotales "(" $porcentajeComentarios "%)"
        Write-Host "Codigos totales: " $codigosTotales "(" $porcentajeCodigo "%)"
    } else {
        Write-Host "No hay archivos para analizar con las extensiones indicadas"
    }
    
}

validarDirectorio
calcularSalida
# -------------------- FIN DE ARCHIVO --------------------