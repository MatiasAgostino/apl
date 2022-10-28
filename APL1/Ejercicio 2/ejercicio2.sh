#!/bin/bash

# -------------------------- ENCABEZADO --------------------------

# Nombre del script: ejercicio2.sh
# Número de APL: 1
# Número de ejercicio: 2
# Número de entrega: Entrega

# ---------------- INTEGRANTES DEL GRUPO ----------------

#          Apellido, Nombre         | DNI
#           Agostino, Matías          | 43861796
# Colantonio, Bruno Ignacio | 43863195
#    Fernández, Rocío Belén    | 43875244
#    Galo, Santiago Ezequiel    | 43473506
#  Panigazzi, Agustín Fabián  | 43744593

# -------------------- FIN DE ENCABEZADO --------------------

# FUNCIÓN DE AYUDA

ayuda() {
	echo "-------------- AYUDA - DESCRIPCIÓN DEL SCRIPT --------------"
	echo "Dados archivos de log donde se registraron todas las llamadas realizadas en una semana por un call center, el script obtiene y muestra por pantalla los siguientes datos:"
	echo "1. Promedio de tiempo de las llamadas realizadas por día"
	echo "2. Promedio de tiempo y cantidad por usuario por día"
	echo "3. Los 3 usuarios con más llamadas en la semana"
	echo "4. Cuántas llamadas no superan la media de tiempo por día"
	echo "5. El usuario que tiene más cantidad de llamadas por debajo de la media en la semana"
	echo "---------------- AYUDA - FORMATO DEL SCRIPT ----------------"
	echo "./ejercicio2.sh [-h / -? / --help]: Muestra la ayuda"
	echo "./ejercicio2.sh [--logs]: Realiza los cálculos anteriormente realizados sobre el directorio actual"
	echo "./ejercicio2.sh [--logs \"<direccion_directorio>\"]: Realiza los cálculos anteriormente mencionados en el directorio cuya ubicación es ubicacion_directorio"
	echo "Ejemplo para ejecutar el script con el set de pruebas brindado (estando posicionados en la carpeta \"Ejercicio 2\"): ./ejercicio2.sh --logs \"logs\""
}

validarDirectorio() {
	if [ ! -d "$directorio" ]
	then
		echo "Error: Directorio inexistente."
		exit
	elif ! test -r "$directorio"
	then
		echo "Error:  No se poseen permisos de lectura sobre el directorio."
		exit
	fi
}

calcularSalida() {
	# Ciclo para cada archivo existente en el directorio
	for dir in "$directorio"/*
	do
		echo "--------------------- Analizando Archivo: $(basename "$dir") ---------------------"
		
		# Declaración de arrays acumuladores por usuario por semana
		declare -A cantLlamadasXUsuarioSemana
		declare -A cantLlamadasBajoMediaXUsuarioSemana

		# Se crea un array fechas a partir de todas las fechas existentes en el archivo
		mapfile -t fechas < <(cut -d" " -f1 "$dir" | sort -u)
		
		# Ciclo por cada fecha existente en el archivo
		for fecha in "${fechas[@]}"
		do
			# Se crea un array usuarios a partir de todos las usuarios existentes en la fecha
			mapfile -t usuarios < <(grep "$fecha" "$dir" | cut -d"-" -f4 | sort -u)

			# Inicialización de variables acumuladoras por día por todos los usuarios
			cantLlamadasDia=0
			promedioTiempoDia=0
			cantLlamadasBajoMediaDia=0

			# Ciclo por cada usuario existente en la fecha
			for usuario in "${usuarios[@]}"
			do
				# Declaración de arrays acumuladores por usuario por día
				declare -A cantLlamadasXUsuarioDia
				declare -A promedioTiempoXUsuarioDia

				# Se crea un array llamadas a partir de todos las llamadas realizadas por el usuario en la fecha
				mapfile -t llamadas < <(grep "$fecha[[:space:]][0-9][0-9]:[0-9][0-9]:[0-9][0-9]-$usuario" "$dir")

				# Ciclo por cada par de inicio y fin de llamada del usuario en la fecha
				for (( k=0; k<${#llamadas[@]}; k+=2 ))
				do
					# Obtención de las fechas y hora de inicio (hora1) y fin (hora2) de la llamada
					hora1=$(echo ${llamadas[$k]} | cut -d'-' -f1-3)
					hora2=$(echo ${llamadas[(($k+1))]} | cut -d'-' -f1-3)

					# Obtención de la duración de la llamada en segundos
					duracion=$(( $(date -d "$hora2" "+%s") - $(date -d "$hora1" "+%s") ))

					# Se añade la duración de la llamada a los promedios de tiempo por día y por usuario por día
					((promedioTiempoDia += $duracion ))
					((promedioTiempoXUsuarioDia[ $usuario ] += $duracion ))

					# Se incrementan la cantidad de llamadas por día, por usuario por día y por usuario por semana
					((cantLlamadasDia++))
					((cantLlamadasXUsuarioDia[ $usuario ]++))
					((cantLlamadasXUsuarioSemana[ $usuario ]++))
				done
				
				# Se calcula el promedio de tiempo por usuario por día dividiendo el acumulador de duración por la cantidad de llamadas
				((promedioTiempoXUsuarioDia[ $usuario ] /= cantLlamadasXUsuarioDia[ $usuario ]))

			done
			
			# Se calcula el promedio de tiempo por día dividiendo el acumulador de duración por la cantidad de llamadas
			((promedioTiempoDia /= $cantLlamadasDia))

			# Búsqueda de llamadas por debajo de la media en el día
			# Se vuelve a realizar el mismo ciclo anteriormente hecho
			for usuario in "${usuarios[@]}"
			do
				mapfile -t llamadas < <(grep "$fecha[[:space:]][0-9][0-9]:[0-9][0-9]:[0-9][0-9]-$usuario" "$dir")
				for (( k=0; k<${#llamadas[@]}; k+=2 ))
				do
					hora1=$(echo ${llamadas[$k]} | cut -d'-' -f1-3)
					hora2=$(echo ${llamadas[(($k+1))]} | cut -d'-' -f1-3)
					duracion=$(( $(date -d "$hora2" "+%s") - $(date -d "$hora1" "+%s") ))

					# Se compara la duración de la llamada con el promedio diario para saber si se encuentra debajo de la media
					if [ $duracion -lt $promedioTiempoDia ]
					then
						((cantLlamadasBajoMediaDia++))
						# El usuario que tiene más cantidad de llamadas por debajo de la media en la semana
						# Al anteriormente estar analizando "Cuántas llamadas no superan la media de tiempo por día"
						# Se considera que se refiere a la cantidad de llamadas por debajo de la media diaria durante la semana analizada
						((cantLlamadasBajoMediaXUsuarioSemana[ $usuario ]++))
					fi
				done
			done

			echo "---------------------------- Fecha: $fecha ----------------------------"

			# Se pasa la duración de la llamada en segundos al formato horas:minutos:segundos
			tiempoHMS=$(date -d@$promedioTiempoDia -u +%H:%M:%S)
			echo "1. Promedio de tiempo de las llamadas realizadas en el día: $tiempoHMS"

			echo "2. Usuario | Promedio de tiempo | Cantidad de llamadas"
			# Recorrida por el array de promedio de tiempo por usuario por día
			for i in ${!promedioTiempoXUsuarioDia[*]}
			do
				tiempoHMS=$(date -d@${promedioTiempoXUsuarioDia[ $i ]} -u +%H:%M:%S)
				echo $i $tiempoHMS  ${cantLlamadasXUsuarioDia[ $i ]}
			done

			echo "4. Cantidad de llamadas que no superan la media de tiempo por día: $cantLlamadasBajoMediaDia"

			# Se eliminan los valores de los array al final del día para comenzar el siguiente
			unset promedioTiempoXUsuarioDia
			unset cantLlamadasXUsuarioDia
		done

		echo "--------------------------- Resumen de la Semana ---------------------------"

		# Para conocer los usuarios con más llamadas en la semana, se recorre el array de cantidad de llamadas por usuario por semana
		# La salida de la recorrida es redireccionada al comando sort para acomodar en orden descendente y luego al comando head para obtener los 3 mayores valores
		echo "3. Los 3 usuarios con más llamadas en la semana"
		echo "Usuario | Cantidad de llamadas"
		for i in ${!cantLlamadasXUsuarioSemana[*]}
		do
			echo $i ${cantLlamadasXUsuarioSemana[ $i ]}
		done | sort -k 2 -t" " -nr | head -3
		
		# Para conocer los usuarios con más llamadas en la semana, se recorre el array de cantidad de llamadas por usuario por semana
		# La salida de la recorrida es redireccionada al comando sort para acomodar en orden descendente y luego al comando head para obtener el mayor valor
		echo "5. Usuario con más cantidad de llamadas por debajo de la media en la semana"
		echo "Usuario | Cantidad de llamadas por debajo de la media en la semana"
		for i in ${!cantLlamadasBajoMediaXUsuarioSemana[*]}
		do
			echo $i ${cantLlamadasBajoMediaXUsuarioSemana[ $i ]}
		done | sort -k 2 -t" " -nr | head -1

		# Se eliminan los valores de los array al final de la semana para comenzar la siguiente
		unset cantLlamadasXUsuarioSemana
		unset cantLlamadasBajoMediaXUsuarioSemana
	done
}

# A partir de la opción recibida en la línea de comandos, es la acción a realizar
case $1 in
	'--logs')
		if [ "$2" ]
		then
			directorio="$2"
		else
			directorio=.
		fi
		validarDirectorio
		directorio="$(realpath "$directorio")"
		calcularSalida
		exit
	;;
	'-h' | '--help' | '-?')
		ayuda
		exit
	;;
	*)
		echo "Error: Comando inexistente."
		ayuda
		exit
	;;
esac

# ------------------------ FIN DE ARCHIVO ------------------------