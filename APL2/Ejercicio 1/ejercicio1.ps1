<#
-------------------------- ENCABEZADO --------------------------

Nombre del script: ejercicio1.ps1
Número de APL: 2
Número de ejercicio: 1
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

# Determinación de parámetros
Param (
	[Parameter(Position = 1, Mandatory = $false)]
	[String] $pathSalida = ".\procesos.txt ",
	[int] $cantidad = 3
)
# Se guarda en la variable "existe" el resultado de probar la existencia del path de salida
$existe = Test-Path $pathSalida
if ($existe -eq $true) {
	# Se guardan en la variable "procesos" los procesos activos al momento de ejecutar el script
	# cuyo consumo de memoria sea mayor a 100MB
	$procesos = Get-Process | Where-Object { $_.WorkingSet -gt 100MB }

	# Se guardan el id y el nombre de dichos procesos en formato de lista en el archivo del path de salida
	$procesos | Format-List -Property Id,Name >> $pathSalida

	# Ciclo que se ejecuta la cantidad de veces determinada por la variable "cantidad"
	for ($i = 0; $i -lt $cantidad ; $i++) {
		# Muestra en pantalla el id y el nombre de los primeros "cantidad" procesos
		Write-Host $procesos[$i].Id - $procesos[$i].Name
	}
} else {
	Write-Host "El path no existe"
}

<#
--------------------------- RESPUESTAS -------------------------

1) ¿Cuál es el objetivo del script?

El objetivo del script es guardar en formato de lista, en un archivo cuyo path es fue ingresado por
parámetro en "pathSalida" (en caso contrario, toma su valor por default; siempre verificando que exista
dicho path), los ID y nombres de los procesos activos al momento de ejecutar el script cuyo consumo de
memoria sea mayor a 100 MB. Luego, se muestra en pantalla una lista de los ID y nombres de los primeros
"cantidad" procesos que cumplieron con la condición, siendo la cantidad determinada como parámetro del
script.

2) ¿Agregaría alguna otra validación a los parámetros?

Agregaríamos una validación sobre la cantidad de procesos a listar. La cantidad nunca puede ser negativa.
(Podría pedirse que siempre sea positiva mayor a 0, ya que no tiene sentido ejecutar el script para listar
0 procesos). Otra validación que se podría agregar a los parámetros es que la cantidad de procesos a
imprimir en pantalla no sea mayor a los procesos que se guardaron en pathSalida, ya que no sería posible.

3) ¿Qué sucede si se ejecuta el script sin ningún parámetro?

Si se ejecuta el script sin ningún parámetro, como los parámetros tienen valores por default, el script
recurre a los mismos, establecidos en Param() (pathSalida sería el path ".\procesos.txt " y cantidad sería
3). Dichos parámetros fueron establecidos como no obligatorios, por lo que no aparecería un mensaje de
error al omitirlos.

-------------------- FIN DE ARCHIVO --------------------
#>