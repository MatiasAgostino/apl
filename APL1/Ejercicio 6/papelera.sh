#!/bin/bash

# -------------------------- ENCABEZADO --------------------------

# Nombre del script: papelera.sh
# Número de APL: 1
# Número de ejercicio: 6
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
	echo "Este script emula el comportamiento del comando rm, pero utilizando el concepto de "papelera de reciclaje", teniendo la posibilidad de recuperar un objeto en el futuro."
	echo "Dicha papelera es un archivo comprimido ZIP y se encuentra alojada en el home del usuario que ejecuta el comando."
	echo "---------------- AYUDA - FORMATO DEL SCRIPT ----------------"
	echo "./papelera.sh [-h / -? / --help]: Muestra la ayuda"
	echo "./papelera.sh [--listar]: Lista los archivos que contienen la papelera de reciclaje, informando nombre de archivo y su ubicación original."
	echo "./papelera.sh [--recuperar \"<nombre_archivo>\"]: Recupera el archivo pasado por parámetro a su ubicación original"
	echo "./papelera.sh [--vaciar]: Vacía la papelera de reciclaje (elimina definitivamente los archivos)"
	echo "./papelera.sh [--eliminar \"<direccion_archivo>\"]: Elimina el archivo, enviándolo a la papelera de reciclaje"
	echo "./papelera.sh [--borrar \"<nombre_archivo>\"]: Borra un archivo de la papelera, haciendo que no se pueda recuperar"
	echo "Ejemplos para ejecutar el script con el set de pruebas brindado (estando posicionados en la carpeta \"Ejercicio 6\"):"
	echo "./papelera.sh --eliminar \"files/descargas/Pepe\""
	echo "./papelera.sh --listar"
	echo "./papelera.sh --borrar \"Pepe\""
	echo "./papelera.sh --recuperar \"Pepe\""
	echo "./papelera.sh --vaciar"
}

validarPapelera() {
	# Busca si ya existe una papelera en el home del usuario
	papeleraAct="$(ls -a $dirPapelera | grep "papelera*.zip")"

	# Si ya existe una papelera y es de una versión distinta a la actual, se elimina para luego crear otra
	if [[ "$papeleraAct" && "$papeleraAct" != "$nombrePapelera" ]]
	then
		rm "$dirPapelera/$nombrePapelera"
	fi
}

# Función para listar los archivos al querer recuperar/borrar
mostrarArchivosCondicion() {
	# Busca los archivos con el nombre ingresado por el usuario para validar que existe
	if [[ "zipinfo -1 "$dirPapelera/$nombrePapelera" |  tr "~" "/" | grep "$archivo" | wc -l" == 0 ]]
	then
		echo "Error: No se encontró ningún archivo $archivo en la papelera."
		exit 1
	fi

	# Busca los archivos con el nombre ingresado para mostrarlos en el formato brindado por la consigna
	# numeroArchivo - nombreArchivo direccionArchivo
	zipinfo -1 "$dirPapelera/$nombrePapelera" |  tr "~" "/" | grep "$archivo" | awk '
	BEGIN{
		FS=OFS="/"
		i=1
	}
	{
		printf("%d - %s ", i, $NF)
		NF--
		print
		(( i++ ))
	}'
	
	cantArch=$(zipinfo -1 "$dirPapelera/$nombrePapelera" |  tr "~" "/" | grep "$archivo" | wc -l)
}

listarArchivos() {
	# Verifica que la papelera no se encuentre vacía antes de listar su contenido
	if ! zipinfo "$dirPapelera/$nombrePapelera" > /dev/null
	then
		echo "Error: La papelera se encuentra vacía."
		exit 1
	fi

	# A diferencia de la función anterior, se lista la totalidad del contenido de la papelera con el formato
	# nombreArchivo direccionArchivo
	zipinfo -1 "$dirPapelera/$nombrePapelera" |  tr "~" "/" | awk '
	BEGIN{
		FS=OFS="/"
	}
	{
		printf("%s ", $NF)
		NF--
		print
	}'
}

recuperarArchivo() {
	# Ingreso de número de archivo que se desea recuperar para evitar ambigüedades
	echo -n "¿Qué archivo desea recuperar? "
	read -r numArch

	# Verifica que el número seleccionado exista (mayor a 1 y menor/igual a la cantidad de archivos)
	if [[ $numArch -gt $cantArch  || $numArch -lt 1 ]]
	then
		echo "Error: El número de archivo seleccionado no existe."
		exit 1
	fi

	# Busca el número de archivo en la papelera con el formato /directorio1/directorio2/archivo
	# Se vuelve a pasar al formato ~directorio1~directorio2~archivo para respetar el formato de la papelera
	nombreArchZip="$(zipinfo -1 "$dirPapelera/$nombrePapelera" |  tr "~" "/" | grep "$archivo" | head -"$numArch" | tail -1 | tr "/" "~")"

	# Busca el path del directorio padre del archivo con el formato /directorio1/directorio2
	pathRelativo="$(echo $nombreArch | tr "~" "/")"
	pathRelativo="$(dirname "$pathRelativo")"

	# Descomprime el archivo existente en la papelera hacia el directorio padre original
	unzip "$dirPapelera/$nombrePapelera" "$nombreArchZip" -d "$pathRelativo">/dev/null
	# Elimina el archivo de la papelera de reciclaje
	zip -d "$dirPapelera/$nombrePapelera" "$nombreArchZip">/dev/null

	# Renombra al archivo con su ruta original, no hace falta calcular el basename porque el comando mv lo interpreta como dirección absoluta
	nombreArch="$(echo "$nombreArchZip" | tr "~" "/")"
	mv "$nombreArchZip" "$nombreArch"

	echo "$nombreArch fue recuperado de manera exitosa."
}

vaciarPapelera() {
	# Elimina el archivo .zip de la papelera para vaciarla, es más eficiente que eliminar todos los archivos que contiene
	rm "$dirPapelera/$nombrePapelera"
	echo "Papelera vaciada de manera exitosa."
}

eliminarArchivo() {
	# Verifica que el archivo exista
	if ! test -f "$archivo"
	then
		echo "Error: $archivo no existe."
		exit 1
	fi

	# Obtiene el path absoluto del archivo
	pathCompleto="$(realpath "$archivo")"

	# A fin de evitar las ambigüedades de archivos de diferentes directorios con el mismo nombre
	# El nombre del archivo de la papelera será ~directorio1~directorio2~archivo
	# Obtiene el path del directorio padre del archivo
	pathRelativo="$(dirname "$pathCompleto" | tr "/" "~")"
	# Obtiene el nombre del archivo sin considerar directorios para saber el nombre original y luego cambiarlo
	nombreArchivo="$(basename "$pathCompleto")"
	# Concatena para lograr el nombre final
	nombreFinal="$pathRelativo~$nombreArchivo"

	# Añade a la papelera de reciclaje el nuevo archivo
	# El archivo .zip de la papelera de reciclaje se crea al eliminar el primer elemento
	zip -mj "$dirPapelera/$nombrePapelera" "$pathCompleto">/dev/null

	# Cambia el nombre del archivo al formato anteriormente descrito
	printf "@ $nombreArchivo\n@=$nombreFinal\n" | zipnote -w "$dirPapelera/$nombrePapelera"

	echo "$archivo enviado a la papelera de manera exitosa."
}

borrarArchivo() {
	# Ingreso de número de archivo que se desea borrar para evitar ambigüedades
	echo -n "¿Qué archivo desea borrar definitivamente? "
	read -r numArch
	
	# Verifica que el número seleccionado exista (mayor a 1 y menor/igual a la cantidad de archivos)
	if [[ $numArch -gt $cantArch  || $numArch -lt 1 ]]
	then
		echo "Error: El número de archivo seleccionado no existe."
		exit 1
	fi

	# Busca el nombre del archivo con el número ingresado
	nombreArch=$(zipinfo -1 "$dirPapelera/$nombrePapelera" |  tr "~" "/" | grep "$archivo" | head -"$numArch" | tail -1 | tr "/" "~")
	
	# Se elimina de la papelera el archivo
	zip -d "$dirPapelera/$nombrePapelera" "$nombreArch">/dev/null

	echo "$nombreArch fue eliminado de manera exitosa." | tr "~" "/"
}

dirPapelera="$HOME"
nombrePapelera="papelera v1.0.zip"

validarPapelera

# A partir de la opción recibida en la línea de comandos, es la acción a realizar
case $1 in
	'--listar')
		listarArchivos
		exit
	;;
	'--recuperar')
		archivo="$2"
		mostrarArchivosCondicion
		recuperarArchivo
		exit
	;;
	'--vaciar')
		vaciarPapelera
		exit
	;;
	'--eliminar')
		archivo="$2"
		eliminarArchivo
		exit
	;;
	'--borrar')
		archivo="$2"
		mostrarArchivosCondicion
		borrarArchivo
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