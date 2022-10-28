#!/bin/bash

# -------------------------- ENCABEZADO --------------------------

# Nombre del script: ejercicio5.sh
# Número de APL: 1
# Número de ejercicio: 5
# Número de entrega: Entrega

# ---------------- INTEGRANTES DEL GRUPO ----------------

#       Apellido, Nombre          | DNI
#       Agostino, Matías          | 43861796
#       Colantonio, Bruno Ignacio | 43863195
#       Fernández, Rocío Belén    | 43875244
#       Galo, Santiago Ezequiel   | 43473506
#       Panigazzi, Agustín Fabián | 43744593

# -------------------- FIN DE ENCABEZADO --------------------

# FUNCIÓN DE AYUDA

ayuda() {
    echo "-------------- AYUDA - DESCRIPCIÓN DEL SCRIPT --------------"
    echo "Dados dos archivos, uno de notas y otro de materias, se pide obtener la cantidad de alumnos que han"
    echo "promocionado (ambos parciales/recuperatorio con nota mayor o igual a 7), aptos para rendir final"
    echo "(sin final y con ambos parciales/recuperatorio con nota mayor o igual a 4),"
    echo "que recursaran (nota menor a 4 en final o en parciales y/o recuperatorios),"
    echo "y que abandonaron la materia (sin nota en algun parcial y sin recuperatorio)"
    echo "La salida del script será en formato de documento JSON (\"salida.json\") en el directorio donde se encuentre posicionado el usuario al ejecutar el script."
    echo "---------------- AYUDA - FORMATO DEL SCRIPT ----------------"
    echo "./ejercicio5.sh [-h / -? / --help]: Muestra la ayuda"
    echo "./ejercicio5.sh [--notas \"<nombre_arch_notas>\" --materias \"<nombre_arch_materias>\"]: Realiza los cálculos anteriormente mencionados sobre los archivos enviados"
    echo "Ejemplos para ejecutar el script con el set de pruebas brindado (estando posicionados en la carpeta \"Ejercicio 5\"):"
    echo "./ejercicio5.sh --notas \"notas.txt\" --materias \"materias.txt\""
    echo "./ejercicio5.sh --notas \"notas2.txt\" --materias \"materias2.txt\""
    echo "./ejercicio5.sh --notas \"notas3.txt\" --materias \"materias3.txt\""
    echo "--------------------- AYUDA - ACLARACIÓN ---------------------"
    echo "Para correr el script es necesario descargar la funcion jq ((comando: sudo apt install jq))"
    return 0
}

validarArchivos() {
    if [[ (! -f "$notas") || (! -f "$materias") ]]
    then
        echo "Error: Archivo inexistente."
        exit
    elif ! test -r "$notas"
    then
        echo "Error:  No se poseen permisos de lectura sobre el archivo."
        exit
    elif ! test -r "$materias"
    then
        echo "Error:  No se poseen permisos de lectura sobre el archivo."
        exit
    
    fi
}

calcularSalida() {

#leer archivo materias y obtener ID


    while IFS="|" read -r idMat desc depto
    do
        #Id de materia
        arr_id[$idMat]=$idMat
        
        #Nombre de materia
        arr_desc[$idMat]=$desc
        
        #idDepto
        arr_depto[$idMat]=$depto        
    done < "$materias"
    
    while IFS="|" read -r dni id pp sp rec final
    do

        if [[ "${arr_id[$id]}" -eq "$id" ]]
            then
    
                #procesamos los promocionados
    
                    if [[ ("$pp" -ge 7 && "$sp" -ge 7) || ("$pp" -ge 7 && "$rec" -ge 7) || ("$sp" -ge 7 && "$rec" -ge 7) ]]
                        then 
                            (( cantProm[$id]++ ))
    
                #procesamos los que van a final
                    elif [[ ( ("$pp" -ge 4 && "$sp" -ge 4 ) || ("$pp" -ge 4 && "$rec" -ge 4 ) || ("$sp" -ge 4 && "$rec" -ge 4) ) && "$final" == "" ]]
                        then 
                            (( cantFinal[$id]++ ))
    
                #procesamos los que abandonan
                        elif [[  ("$pp" == "" && "$sp" == "") ||  ("$pp" == "" && "$rec" == "")  ||  ("$sp" == "" && "$rec" == "") ]]
                            then
                                (( cantAband[$id]++ ))
    
                #procesamos recursantes
                        elif [[  "$final" == "" || "$final" -lt 4 ]]
                            then
                                (( cantRecu[$id]++ ))
                    fi
        fi

    done < "$notas"
	
    for idMateria in ${!arr_depto[*]}
	   do
	    if ! [ ${cantFinal[$idMateria]} ]
	    then
	    	cantFinal[$idMateria]=0
	    fi
	    if ! [ ${cantRecu[$idMateria]} ]
	    then
	    	cantRecu[$idMateria]=0
	    fi
	    if ! [ ${cantAband[$idMateria]} ]
	    then
	    	cantAband[$idMateria]=0
	    fi
	    if ! [ ${cantProm[$idMateria]} ]
	    then
	    	cantProm[$idMateria]=0
	    fi
   done
	
    #idMateria  ---> ID DE LA MATERIA
    #arr_depto[$idMateria] ---> NUMERO DE DEPTO
    for idMateria in ${!arr_depto[*]}
    do
    	lastIdMateria=$idMateria
    	lastIdDepto=${arr_depto[$idMateria]}
    done
    
    ultimoDepto=0
    flag=1
    ((lastIdDepto=lastIdDepto-1))
    
    string="{
    \"departamentos\":["
    
    for idMateria in ${!arr_depto[*]}
    do
    	if ! [ $idMateria -eq 0 ]
    		then
    		
    		if ! [ $ultimoDepto -eq ${arr_depto[$idMateria]} ]
    			then
    			#Hacemos el cierre de etiqueta
    			#Si no es el primer depto
    			if ! [ $ultimoDepto -eq 0 ]
    			then
    				#Si es el ante ultimo depto pone la coma
    				if ! [ ${arr_depto[$idMateria]} -eq $lastIdDepto ]
    				then
    				string+="]},"
    				else
    				string+="]}"
    				fi
    			fi
    			#realizamos el string de inicio
    			string+="{  \"id\": ${arr_depto[$idMateria]} , \"notas\": ["
    			ultimoDepto=${arr_depto[$idMateria]}
    		else
    			string+=","
    		fi
    		
    		#realizamos la conversion
    		string+="{  
    		\"id_materia\": $idMateria,
    		\"descripcion\": \"${arr_desc[$idMateria]}\",
    		\"final\": ${cantFinal[$idMateria]},
    		\"recursan\": ${cantRecu[$idMateria]},
    		\"abandonaron\": ${cantAband[$idMateria]},
    		\"promocionaron\": ${cantProm[$idMateria]}
    		}"
    	fi
    done
    
    string+="]}]}"
    

	
   echo "${string}" | jq '.'
} > "salida.json"


if [[  "$1" == "--notas" && "$3" == "--materias"  ]]
    then
        notas="$2"
        materias="$4"
        validarArchivos
        calcularSalida
elif [[ "$1" == "--help" || "$1" == "-h" || "$1" == "--?"  ]]
    then 
        ayuda
else
    echo "Error de sintaxis en la entrada."
    ayuda
fi

# -------------------- FIN DE ARCHIVO --------------------