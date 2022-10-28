<#
-------------------------- ENCABEZADO --------------------------
Nombre del script: ejercicio3.ps1
Número de APL: 2
Número de ejercicio: 3
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
    El script ejecuta un sistema de integracion continua. 

    .Description
    Cada vez que se detecta un cambio en alguno de los archivos del directorio especificado, se ejecutan las siguientes acciones (las cuales deben ser especificadas, tambien, por el usuario entre comas):
    
    - listar: muestra por pantalla los nombres de los archivos que sufrieron modificaciones.

    - peso: muestra por pantalla el peso de los archivos modificados.
	
    - compilar: concatena el contenido de todos los archivos dentro del directorio en cuestion y guarda el resultado en una carpeta 'bin' dentro del mismo.
	
    - publicar: copia  el contenido del 'proceso de compilacion' en una carpeta especificada por el usuario - solo podra ejecutarse si se ha especificado anteriormente la accion de compilar.

    NOTA: Si se desea publicar, es obligacion haber compilado previamente. Ademas, se debe de haber especificado una ruta destino. 

    .Example
    .\ejercicio3.ps1 -codigo "pathAMonitorear" -acciones listar, peso, compilar

    .Example
    .\ejercicio3.ps1 -codigo "pathAMonitorear" -acciones listar, peso, compilar, publicar -salida "pathDestino"
#>

param(
        [ validateScript( {
            if ( !(Test-Path -path $_) ) {
                throw "No existe la ruta $_"
            } elseif ( ! (Get-Acl $_).Access ) {
                throw "No se tienen los permisos necesarios para trabajar sobre el directirio $_"
            } else {
                $true
            }
        }
        ) ]
        [ parameter(mandatory = $true) ]
        [ string ]$codigo,
           
        [ validateScript({
            $accionesCorrectas = $true
            
            if ($_.equals("listar") -or $_.equals("peso") -or $_.equals("compilar") -or $_.equals("publicar")) {
                $accionesCorrectas = $true
            } else {
                $accionesCorrectas = $false
            }
        
            if ( !$accionesCorrectas ) {
                throw "No se ingresaron acciones validas. Pruebe con Get-Help .\ejercicio3 para obtener ayuda sobre el script."
            } else {
                $true
            }
        }) ]
        [ validateNotNullOrEmpty() ]
        [ parameter(mandatory = $true) ]
        [ string[] ]$acciones, 
                
        [ string ]$salida
)

# variables globales

$map = New-Object System.Collections.Hashtable

# funciones principales

function validacionProfundaDeParametros() {
    $repetidos = $false

    for ($i = 0; $i -lt $acciones.Length; $i++) {
       $map[$acciones[$i]]++
    }

    for ($i = 0; $i -lt $acciones.Length; $i++) {
        if ( $map[$acciones[$i]] -gt 1) {
            $repetidos = $true;
        }
    }

    if ( $repetidos ) {
        throw "Se repetieron acciones. Ingrese 'Get-Help .\ejercicio3.ps1' para obtener ayuda sobre el script."
    }

    if ( $map["publicar"] -eq 1 -and $map["compilar"] -lt 1) {
        throw "No se puede publicar si antes no se ha compilado. Ingrese 'Get-Help .\ejercicio3.ps1' para obtener ayuda sobre el script."
    }

    if ($map["publicar"] -eq 1 -and $salida.Length -eq 0) {
        throw "No se puede publicar si no se ha especificado una ruta destino. Ingrese 'Get-Help .\ejercicio3.ps1' para obtener ayuda sobre el script."
    }
}

function global:comenzarAcciones($info, $archivo) {
    if ($map["listar"] -eq 1) {
        Write-host " "
        Write-host "Listando..."
        Write-host $info -ForegroundColor DarkGreen
        Write-host " "
    }

    if ($map["peso"] -eq 1) {
        $peso = [Math]::Ceiling((Get-ChildItem $archivo).Length / 1024)

        Write-host "Peso..."
        Write-host $archivo ":" $peso "kb" -ForegroundColor DarkGreen 
    }

    if ($map["compilar"] -eq 1) {
        Write-host " "
        Write-host "Compilando..."
            
        if (! (Test-Path -Path "$PSScriptRoot\bin") ) {
            New-Item "$PSScriptRoot\bin" -ItemType Directory
        }

        Get-ChildItem -Path $codigo -Recurse | Where-Object {! $_.PSIsContainer } | Where-Object { ($_.Name).Contains(".txt") } | ForEach-Object { Out-File -FilePath "$PSScriptRoot\bin\merged.txt" -InputObject (Get-Content $_.FullName) -Append }
            
        Write-Host "Compilado" -ForegroundColor DarkGreen
        Write-Host " "
    }

    if ($map["publicar"] -eq 1) {
        Write-Host "Publicando..."
        
        if ( !(Test-Path -Path $salida) ) {
            New-Item "$salida" -ItemType Directory    
        }

        Copy-Item -Path "$PSScriptRoot\bin\merged.txt" -Destination $salida

        Write-Host "Publicado" -ForegroundColor DarkGreen
        Write-Host " "
    }
}

# main

function main() {
    validacionProfundaDeParametros
    
    try {
        $pathAbsoluto = Resolve-Path $codigo
        
        $fsw = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
                Path = $pathAbsoluto
                Filter = '*'
                IncludeSubdirectories = $true
                NotifyFilter = [IO.NotifyFilters]::FileName,
                               [IO.NotifyFilters]::LastWrite
        }
        
        $action = {
            $details = $event.SourceEventArgs
            
            $FullPath = $details.FullPath
            $ChangeType = $details.ChangeType
            $TimeStamp = $event.TimeGenerated

            $text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $TimeStamp

            comenzarAcciones $text $FullPath
        }

        $handlers = . {
            Register-ObjectEvent -InputObject $fsw -EventName Changed -Action $action -MessageData 1
            Register-ObjectEvent -InputObject $fsw -EventName Created -Action $action -MessageData 2
            Register-ObjectEvent -InputObject $fsw -EventName Renamed -Action $action -MessageData 3
            Register-ObjectEvent -InputObject $fsw -EventName Deleted -Action $action -MessageData 4
        }

        $fsw.EnableRaisingEvents = $true

        Write-host "Esperando por cambios en $pathAbsoluto"

        do {
            Wait-Event -Timeout 1
        } while($true)

    } finally {
        $fsw.EnableRaisingEvents = $false

        $handlers | ForEach-Object {
            Unregister-Event -SourceIdentifier $_.Name
        }

        $handlers | Remove-Job

        $fsw.Dispose()

        Write-Host " "
        write-host "Finalizado"
    }
}

main

# -------------------- FIN DE ARCHIVO -------------------- #