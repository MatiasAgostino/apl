#!/bin/bash

# -------------------------- ENCABEZADO --------------------------

# Nombre del script: ejercicio3.sh
# Número de APL: 1
# Número de ejercicio: 3
# Número de entrega: Entrega

# ---------------- INTEGRANTES DEL GRUPO ----------------

#       Apellido, Nombre       	  | DNI
# 	Agostino, Matías          | 43861796
# 	Colantonio, Bruno Ignacio | 43863195
#    	Fernández, Rocío Belén    | 43875244
#    	Galo, Santiago Ezequiel   | 43473506
#  	Panigazzi, Agustín Fabián | 43744593

# -------------------- FIN DE ENCABEZADO --------------------

# ------------ FUNCIONES PRINCIPALES ------------

ayuda(){
	echo " "

	echo "------------ AYUDA - DESCRIPCION DEL SCRIPT -----------"
	
	echo " "	
	
	echo "El script ejecuta un sistema de integracion continua. Cada vez que se detecta un cambio en alguno de los archivos del directorio especificado, se ejecutan las siguientes acciones (las cuales deben ser especificadas, tambien, por el usuario entre comas):

- listar: muestra por pantalla los nombres de los archivos que sufrieron modificaciones.

- peso: muestra por pantalla el peso de los archivos modificados.
	
- compilar: concatena el contenido de todos los archivos dentro del directorio en cuestion y guarda el resultado en una carpeta 'bin' dentro del mismo.
	
- publicar: copia  el contenido del 'proceso de compilacion' en una carpeta especificada por el usuario - solo podra ejecutarse si se ha especificado anteriormente la accion de compilar."
	
	echo " "
	
	echo "------------ AYUDA - FORMATO DEL SRCIPT ------------"
	echo "**Para asegurar el correcto funcionamiento del script, es necesario que antes ejecute los siguientes comandos**"
	echo "I)  sudo apt update"
	echo "II) sudo apt install inotify-tools"
	echo " "

	echo "./ejercicio3.sh [-h / -? / --help] => Muestra ayuda"
	echo "./ejercicio3.sh [-c <path> -a [listar,peso,compilar,publicar] -s <path_final>] => inicio"	  
	
	echo "----------- AYUDA - CIERRE DEFINITIVO DEL SCRIPT ------------"
	
	echo "1) Para cerrar definitivamente el script, ingrese el comnado ps"
	echo "2) Tome nota de los PID de los procesos con nombre 'ejercicio3.sh' y 'inotifywait'"
	echo "3) Ejecute el comando: kill -10 [PID_de_'ejercicio3.sh']"
	echo "4) Ejecute el comando: kill -10 [PID_de_'inotifywait']"
}

function finalizar(){

        echo "finalizado..."
}

function demonio(){
	
	# Mientras inotifywait este detectando un "cambio" en algun archivo del directorio
	# dir, se ejecuta el siguiente codigo.
	while out=$(inotifywait -e modify,create,delete,move -r -q --format "%w%f" "$dir")
	do

		# Se verifica que se haya especificado la accion "listar" para ejecutarse cuando 
		# se detecte un cambio.
		if [[ ${map["listar"]} -eq 1 ]]; then
			echo "Archivo modificado"
			echo "$out"
			echo " "
		fi
		
		# Lo mismo que para "listar".
		if [[ ${map["peso"]} -eq 1 ]]; then
			echo "Peso"
			echo $(du -sh $out)
			echo " "
		fi
		
		# Aqui, ademas de verificar que se haya especificado esta accion, se verifica que
		# el directorio "$dir/bin" exista. Si no existe, lo crea.
		if [[ ${map["compilar"]} -eq 1 ]]; then
			echo "Compilando..."
			
			# Si el directorio existe, no lo crea. Si no existe, lo crea.
			mkdir -p "$dir/bin"

			# Se recorren todos los archivos del directorio y se los concatena
			# en un archivo llamado "merged", dentro del directorio "$dir/bin"
			find $dir -type f -exec cat {} + > "$dir/bin/merged"
			
			echo " "
		fi
		
		# Aqui, ocurre algo similar. Luego, se copia el archivo "merged" al directorio
		# especificado.
		if [[ ${map["publicar"]} -eq 1 ]]; then
			echo "Publicando..."
			
			# Si el directorio existe, no lo crea. Si no existe, lo crea.
			mkdir -p "$dirFin"
			
			# Copia el contenido del arhcivo "merged" al directorio destino.
			cp "$dir/bin/merged" "$dirFin"				
			
			echo "[Publicado]"
			echo " "
		fi
	done
}

# ---------- INGRESO DE PARAMETROS ----------

declare -A map
valido=false
cantAcciones=0
comandoIncorrecto=false
dirFinIn=false

if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-?" ]]
then
	ayuda
	exit
fi

while getopts "c:a:s:" opcion
do
	case $opcion in
		c)	# Comando para soportar lineas de la forma dir1/  dir2"
			# dT=$(echo "$OPTARG" | tr -d "[:space:]")
			dir=$(realpath "$OPTARG")
			valido=true
		;;
		a)	auxIFS=$IFS
			
			IFS=','

			acciones=($OPTARG)
			
			IFS=$AUXIFS

			for i in ${acciones[*]}
			do
				if [[ $i == "listar" || $i == "peso" || $i == "compilar" || 
			      	      $i == "publicar" ]]; then
					(( map[$i]++ ))
					valido=true
					(( cantAcciones++ ))	
				else
					comandoIncorrecto=true
				fi
			done
			
			# Se verifica que se hayan ingresado acciones a realizar.
                	if [[ cantAcciones -eq 0 ]]; then
                        	echo "No se han ingresado acciones a realizar. Pruebe ingresando ./ejercicio3.sh [-h, --help, -?]"
                        	exit
                	fi
			
			if [[ $comandoIncorrecto == true ]]; then
				echo "Comando invalido ingresado. Pruebe con ./ejercicio3.sh [-h,--help, -?]"
				exit
			fi
			
			if [[ ${map["publicar"]} -ge 1 && ${map["compilar"]} -eq 0 ]]; then
				echo "Solo se puede publicar, si y solo si, antes se ha compilado. Pruebe con ./ejercicio3.sh [-h, --help, -?]"
				exit
			fi
			
			for i in ${map[*]}
			do
				if [[ $i -gt 1 ]]; then
					echo "Los parametros se repiten. Pruebe con ./ejercicio3.sh [-h, --help, -?]"
					exit
				fi
			done
		;;
		s)	# Comando para soportar lineas de la forma dir1/  dir2"
			# dFT=$(echo "$OPTARG" | tr -d "[:space:]")
			dirFin=$(realpath -m "$OPTARG")
			echo "$dirFin"
			valido=true
			dirFinIn=true
		;;
		*)
			echo "Error: Parametro invalido. Pruebe ingresando ./ejercicio3.sh [-h, --help, -?]"
			exit
		;;
	esac
done

# ------------ EJECUCION EN MODO "DEMONIO" ------------

# Se verifica que se hayan ingresado parametros validos.
if [[ "$valido" == true ]]; then
	
	# Se verifica que el directorio exista y tenga los permisos de lectura.
	if [[ -d "$dir" && -r "$dir" ]]; then
	
		# Se verifica que el directorio a destino exista, si la accion publicar fue
		# especificada.
		if [[ ${map["publicar"]} -eq 1 &&  "$dirFinIn" == false ]]; then
			echo "No se ingreso la ruta a destino necesaria para ejecutar la accion de publicar. Pruebe ingresando ./ejercicio3.sh [-h, --help, -?]"
                	exit
		fi

		# Se ejecuta la funcion "demonio" en segundo plano.
		# Asi, se da la ilusion de un script demonio.
	       	# Cabe aclarar que este script no es un demonio 100%, ya que si bien corre en segundo plano,
		# informa por stdout.	
		demonio &
		trap finalizar SIGUSR1
	else
		echo "$dir no es un directorio o no posee los permiso de lectura"
		exit
	fi
else
	echo "No se ingresaron parametros validos. Pruebe ingresando ./ejercicio3.sh [-h, --help, -?]"
	exit
fi

# -------------------- FIN DE ARCHIVO --------------------
