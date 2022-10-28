#!/bin/bash

# -------------------------- ENCABEZADO --------------------------

# Nombre del script: ejercicio1.sh
# Número de APL: 1
# Número de ejercicio: 1
# Número de entrega: Entrega

# ---------------- INTEGRANTES DEL GRUPO ----------------

#          Apellido, Nombre         | DNI
#           Agostino, Matías          | 43861796
# Colantonio, Bruno Ignacio | 43863195
#    Fernández, Rocío Belén    | 43875244
#    Galo, Santiago Ezequiel    | 43473506
#  Panigazzi, Agustín Fabián  | 43744593

# -------------------- FIN DE ENCABEZADO --------------------

ErrorS()
{
	echo "Error. La sintaxis del script es la siguiente:"
	echo "Para saber la cantidad de líneas: $0 nombre_archivo L" # COMPLETAR
	echo "Para saber la cantidad de caracteres: $0 nombre_archivo C" # COMPLETAR
	echo "Para saber la línea de mayor longitud: $0 nombre_archivo M" # COMPLETAR
}

ErrorP()
{
	echo "Error. nombre_archivo no existe o no tiene permisos de lectura." # COMPLETAR
}

# Se verifica que la cantidad de parámetros sea la esperada (2). De lo contrario,
# ejecuta una función de error de sintaxis.
if test $# -lt 2; then
	ErrorS
fi

# Se verifica que el archivo existe y se tienen permisos de lectura. De lo contrario,
# ejecuta una función de error de permisos.
if !test $1 -r; then
	ErrorP

# Se verifica que el archivo sea uno regular y el segundo parámetro corresponda a
# una letra válida.
elif test -f $1 && (test $2 = "L" || test $2 = "C" || test $2 = "M"); then
# Luego de verificar, dependiendo el caracter indicado, guarda en la variable res
# el resultado de calcular lo indicado y luego lo muestra por pantalla.
	if test $2 = "L" then
		res=`wc -l $1`
		echo"Cantidad de líneas: $res" # COMPLETAR
	elif test $2 ="C"; then
		res=`wc -m $1`
		echo"Cantidad de caracteres: $res" # COMPLETAR
	elif test $2 = "M"; then
		res=`wc -L $1`
		echo"Tamaño de la línea con mayor longitud: $res" # COMPLETAR
	fi
# De no tratarse de ninguna de las letras válidas o si es un archivo no regular,
# ejecuta la función de error de entrada.
else
	ErrorS
fi

# --------------------------- RESPUESTAS -------------------------

# 1) El objetivo de este script es, dado un archivo y un caracter como parámetros,
# determina la cantidad de líneas, caracteres y el tamaño de la línea con mayor longitud.

# 2) Los parámetros que recibe son un nombre de archivo y un caracter como
# modificador (L si se desea calcular la cantidad de líneas, C si se desea calcular la
# cantidad de caracteres y M si se desea averiguar el tamaño de la línea de mayor
# longitud).

# 5) La variable "$#" es una variable automática que indica la cantidad de parámetros
# pasados al script. Otras variables similares son:
# $0 Contiene el nombre del script.
# $n (1-9) Contiene los parámetros de entrada
# $@ Lista de todos los parámetros pasados al script
# $* Cadena con todos los parámetros pasados al script
# $? Resultado del último comando ejecutado
# $$ El PID (Process ID) de la shell actual o proceso ejecutado
# $! El PID del último comando ejecutado en segundo plano

# 6) Los distintos tipos de comillas que se pueden utilizar en Shell scripts son:
# Comilla invertida (`): Permite la ejecución de comandos para luego almacenar su
# salida en una variable. Se utiliza como reemplazo del $().
# Comilla doble ("): Se utiliza para indicar que la variable es del tipo string. Además,
# puede utilizarse para indicar el caracter delimitador en comandos como cut.
# Su contenido se toma como un literal exceptuando los caracteres "$", "`" y "/".
# Comilla simple ('): Toma el contenido de dichas comillas como un literal, sin excepción.

# --------------------- FIN DE ARCHIVO ---------------------