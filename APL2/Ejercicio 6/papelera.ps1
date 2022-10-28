<#
-------------------------- ENCABEZADO --------------------------

Nombre del script: papelera.ps1
Número de APL: 2
Número de ejercicio: 6
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
	Este script emula el comportamiento del comando rm, pero utilizando el concepto de "papelera de reciclaje", teniendo la posibilidad de recuperar un objeto en el futuro."
	Dicha papelera es un archivo comprimido ZIP y se encuentra alojada en el home del usuario que ejecuta el comando."
	
	Funcionamiento
	.\papelera.ps1 [-listar]: Lista los archivos que contienen la papelera de reciclaje, informando nombre de archivo y su ubicación original.
	.\papelera.ps1 [-recuperar "<nombre_archivo>"]: Recupera el archivo pasado por parámetro a su ubicación original.
	.\papelera.ps1 [-vaciar]: Vacía la papelera de reciclaje (elimina definitivamente todos los archivos contenidos en la misma).
	.\papelera.ps1 [-eliminar "<direccion_archivo>"]: Elimina el archivo, enviándolo a la papelera de reciclaje.
	.\papelera.ps1 [-borrar "<nombre_archivo>"]: Borra un archivo de la papelera, haciendo que no se pueda recuperar.

	.Example
	.\papelera.ps1 -eliminar "files\descargas\Pepe"

	.Example
	.\papelera.ps1 -listar

	.Example
	.\papelera.ps1 -borrar "Pepe"

	.Example
	.\papelera.ps1 -recuperar "Pepe"

	.Example
	.\papelera.ps1 -vaciar
#>

Param (
	# Distintos parameter sets permiten verificar que no se utilice más de uno a la vez
	[Parameter(ParameterSetName='Listar')][Switch]$listar,
	[Parameter(ParameterSetName='Recuperar')][Switch]$recuperar,
	[Parameter(ParameterSetName='Vaciar')][Switch]$vaciar,
	[Parameter(ParameterSetName='Eliminar')][Switch]$eliminar,
	[Parameter(ParameterSetName='Borrar')][Switch]$borrar,

	# Obligatoriedad del nombre del archivo en el caso de desear recuperar o borrar
	# En este caso no debe ser necesariamente una ruta, y no se deberá validar que es un archivo ya que no se encuentra fuera de la papelera
	[Parameter(ParameterSetName='Recuperar', Position = 1, Mandatory=$true)]
	[Parameter(ParameterSetName='Borrar', Position = 1, Mandatory=$true)]
	[ValidateNotNullOrEmpty()][String]$nomArchivo,

	# Obligatoriedad del archivo en el caso de desear eliminar
	# Validación de que la ruta existe y es un archivo
	[Parameter(ParameterSetName='Eliminar', Position = 1, Mandatory=$true)]
	[ ValidateScript(  {
		if( Test-Path $_ ){ $True } else{ Throw "La ruta al archivo no es válida." }
		if( (Get-Item $_ ) -is [System.IO.FileInfo] ){ $True } else{ Throw $_+" no es un archivo" }
		} )
	]
	[ValidateNotNullOrEmpty()][String]$dirArchivo
)

function Validar-Papelera([String]$nombrePapelera) {
    # Busca si ya existe una papelera en el home del usuario
    Get-ChildItem "$HOME\papelera*.zip" | ForEach-Object {
        # Si ya existe una papelera y es de una versión distinta a la actual, se elimina para luego crear otra
        if( $_.Name -and ($_.Name -ne $nombrePapelera) )
        {
	        Remove-Item $_
        }
    }
}

function Listar-Archivos([String]$dirPapelera, [String]$nomArchivo) {
    # Adaptamos el nombre de archivo que se recibe como parámetro en caso de que sea una ruta
    $newNomArch = $nomArchivo.Replace('\','~')
    $newNomArch = $newNomArch.Replace(':','~')

    $coincidencias = 0

    # Abre la papelera de reciclaje en modo lectura
    $papelera = [System.IO.Compression.ZipFile]::Open($dirPapelera, 'read')

    # Inicio de ciclo para tratar cada registro del contenido de la papelera de reciclaje que coincidan con el nombre ingresado por el usuario
    $papelera.Entries.Name | Where-Object {$_ -Match "$newNomArch"} | ForEach-Object {
        # Encuentro un archivo que coincide, incremento la cantidad de coincidencias
        $coincidencias++

        # Creación de una expresión regular
        [regex]$pattern = "~"
        # La expresión regular permite reemplazar la primera ocurrencia de "~" para reemplazarla por ":" y comenzar a obtener el path original
        $pathAbsoluto = $pattern.replace($_, ":", 1)
        # Segundo reemplazo del resto de ocurrencias de "~" por "\" para obtener definitivamente el path original
        $pathAbsoluto = $pathAbsoluto.Replace('~','\')

        # Divide el path en archivo y path del directorio padre para mostrar en pantalla como en el ejemplo de la consigna
        $nomArchAct = Split-Path -Path $pathAbsoluto -Leaf
        $dirArchAct = Split-Path -Path $pathAbsoluto -Parent

        Write-Host "$coincidencias - $nomArchAct $dirArchAct"
    }

    $papelera.Dispose()
    
    # Verifica si encontró algún archivo 
    if( !$coincidencias )
    {
        Write-Host "Error: No se encontró ningún archivo $nomArchivo en la papelera."
        exit
    }

    return $coincidencias
}

function Listar-Papelera([String]$dirPapelera) {
    # Abre la papelera de reciclaje en modo lectura
    $papelera = [System.IO.Compression.ZipFile]::Open($dirPapelera, 'read')

    # Inicio de ciclo para tratar cada nombre de archivo que se encuentra en la papelera de reciclaje
    $papelera.Entries.Name | ForEach-Object {
        if( !$_ )
        {
            Write-Host "Error: La papelera se encuentra vacía."
            exit
        }
        
        # Creación de una expresión regular
        [regex]$pattern = "~"
        # La expresión regular permite reemplazar la primera ocurrencia de "~" para reemplazarla por ":" y comenzar a obtener el path original
        $pathAbsoluto = $pattern.replace($_, ":", 1)
        # Segundo reemplazo del resto de ocurrencias de "~" por "\" para obtener definitivamente el path original
        $pathAbsoluto = $pathAbsoluto.Replace('~','\')

        # Divide el path en archivo y path del directorio padre para mostrar en pantalla como en el ejemplo de la consigna
        $nomArchAct = Split-Path -Path $pathAbsoluto -Leaf
        $dirArchAct = Split-Path -Path $pathAbsoluto -Parent

        Write-Host "$nomArchAct $dirArchAct"
    }

    $papelera.Dispose()
}

function Recuperar-Archivo([String]$dirPapelera, [String]$nomArchivo, [int]$cantArchivos) {
    $numArchivo = Read-Host "¿Qué archivo desea recuperar?"
    if( ( $numArchivo -gt $cantArchivos ) -or ( $numArchivo -lt 1 ) )
    {
        Write-Host "Error: El número de archivo seleccionado no existe."
        exit
    }

    # Inicializa contador para número de archivo actual
    $i = 0

    # Abre la papelera de reciclaje en modo update
    $papelera = [System.IO.Compression.ZipFile]::Open($dirPapelera, 'update')

    # Inicio de ciclo para tratar cada registro del contenido de la papelera de reciclaje que coincidan con el nombre ingresado por el usuario
    $papelera.Entries | Where-Object {$_.Name -Match "$newNomArch"} | ForEach-Object {
        # Encuentro un archivo que coincide, incremento el número de archivo actual
        $i++

        # En caso de encontrar coincidencia, procede a recuperar el archivo
        if( $i -eq $numArchivo )
        {
            # Creación de una expresión regular
            [regex]$pattern = "~"
            # La expresión regular permite reemplazar la primera ocurrencia de "~" para reemplazarla por ":" y comenzar a obtener el path original
            $pathAbsoluto = $pattern.replace($_.Name, ":", 1)
            # Segundo reemplazo del resto de ocurrencias de "~" por "\" para obtener definitivamente el path original
            $pathAbsoluto = $pathAbsoluto.Replace('~','\')

            # Descomprime el archivo y lo envía al path recuperado del nombre del archivo en la papelera de reciclaje
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, “$pathAbsoluto”, $true)
            # Se elimina el archivo de la papelera de reciclaje
            $_.Delete()

            # Se cierra el archivo de la papelera de reciclaje en modo update
            $papelera.Dispose()

            Write-Host "$pathAbsoluto fue recuperado de manera exitosa."

            # Finalización del ciclo
            exit
        }
    }
}

function Vaciar-Papelera([String]$dirPapelera) {
	# Elimina el archivo .zip de la papelera para vaciarla, es más eficiente que eliminar todos los archivos que contiene
    Remove-Item $dirPapelera
    
    Write-Host "Papelera vaciada de manera exitosa."
}

function Eliminar-Archivo([String]$dirPapelera, [String]$dirArchivo) {
    # Obtiene la dirección absoluta del archivo
	$dirArchivo = Resolve-Path $dirArchivo

    # El nuevo nombre del archivo será la dirección absoluta con ~ en vez de \ para conocer dónde se encontraba el archivo
    $newNomArch = $dirArchivo.Replace('\','~')
    $newNomArch = $newNomArch.Replace(':','~')

    # Abre la papelera de reciclaje en modo update
    $papelera = [System.IO.Compression.ZipFile]::Open($dirPapelera, 'update')

    # Definimos el nivel de compresión del archivo
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Fastest

    # Envía el archivo a la papelera de reciclaje
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($papelera, $dirArchivo, $newNomArch, $compressionLevel)> $null

    # Elimina el archivo de su ubicación original
	Remove-Item -Path $dirArchivo

    Write-Host "$dirArchivo enviado a la papelera de manera exitosa."

    $papelera.Dispose()
}

function Borrar-Archivo([String]$dirPapelera, [String]$nomArchivo, [int]$cantArchivos) {
	$numArchivo = Read-Host "¿Qué archivo desea borrar definitivamente?"
    if( ( $numArchivo -gt $cantArchivos ) -or ( $numArchivo -lt 1 ) )
    {
        Write-Host "Error: El número de archivo seleccionado no existe."
        exit
    }

    # Inicializa contador para número de archivo actual
    $i = 0

    # Abre la papelera de reciclaje en modo update
    $papelera = [System.IO.Compression.ZipFile]::Open($dirPapelera, 'update')

    # Inicio de ciclo para tratar cada registro del contenido de la papelera de reciclaje que coincidan con el nombre ingresado por el usuario
    $papelera.Entries | Where-Object {$_.Name -Match "$newNomArch"} | ForEach-Object {
        # Encuentro un archivo que coincide, incremento el número de archivo actual
        $i++

        # En caso de encontrar coincidencia, procede a borrar el archivo
        if( $i -eq $numArchivo )
        {
            # Creación de una expresión regular
            [regex]$pattern = "~"
            # La expresión regular permite reemplazar la primera ocurrencia de "~" para reemplazarla por ":" y comenzar a obtener el path original
            $pathAbsoluto = $pattern.replace($_.Name, ":", 1)
            # Segundo reemplazo del resto de ocurrencias de "~" por "\" para obtener definitivamente el path original
            $pathAbsoluto = $pathAbsoluto.Replace('~','\')

            # Se elimina el archivo de la papelera de reciclaje
            $_.Delete()

            # Se cierra el archivo de la papelera de reciclaje en modo update
            $papelera.Dispose()

            Write-Host "$pathAbsoluto fue eliminado de manera exitosa."

            # Finalización del ciclo
            exit
        }
    }
}

$nombrePapelera="papelera v1.0.zip"
$dirPapelera="$HOME\$nombrePapelera"

Validar-Papelera $nombrePapelera

# Carga el assembly que contiene la clase IO.Compression.ZipFile del framework .NET
Add-Type -Assembly 'System.IO.Compression.FileSystem'

# En caso de no existir, se crea la papelera
if( -not (Test-Path $dirPapelera) )
{
    # Se crea el archivo zip de la papelera de reciclaje
    $papelera = [System.IO.Compression.ZipFile]::Open($dirPapelera, 'create')

    # Se cierra el archivo de la papelera de reciclaje en modo creación
    $papelera.Dispose()
}

# Búsqueda de opción seleccionada por el usuario y la ejecución de funciones a partir de la misma
if( $listar )
{
	Listar-Papelera $dirPapelera
}
elseif( $recuperar )
{
	$cantArchivos = Listar-Archivos $dirPapelera $nomArchivo
	Recuperar-Archivo $dirPapelera $nomArchivo $cantArchivos
}
elseif( $vaciar )
{
	Vaciar-Papelera $dirPapelera
}
elseif( $eliminar )
{
	Eliminar-Archivo $dirPapelera $dirArchivo
}
else
{
	$cantArchivos = Listar-Archivos $dirPapelera $nomArchivo
	Borrar-Archivo $dirPapelera $nomArchivo $cantArchivos
}

exit

# -------------------- FIN DE ARCHIVO --------------------