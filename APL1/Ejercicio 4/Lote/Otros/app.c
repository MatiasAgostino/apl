#include "funciones.h"
#define ERROR_ARCHIVO -1
#define ES_CIERRE 5
#define ES_APERTURA 6
#define NO_ES_ETIQUETA -2
#define ES_BLANCO(X) ((X)==' ' || (X)=='\t' || (X)=='\n' || (X)=='\r')

int generarHTMLCorrecto(char *nombreArch)
{
    FILE *pf = fopen(nombreArch, "rt"),
         *pfNuevo;
    char linea[TAM], contenidoEtiqueta[TAM], contenidoPila[TAM],
         etiquetaNueva[TAM];
    int res;
    t_pila pila;

    crearPila(&pila);

    if(!pf)
        return ERROR_ARCHIVO;
    pfNuevo = fopen("htmlNuevo.txt", "wt");
    if(!pfNuevo)
    {
        fclose(pf);
        return ERROR_ARCHIVO;
    }

    while(fgets(linea, TAM, pf))
    {
        res = verificarSiHayEtiqueta(linea, contenidoEtiqueta);
        ///MODULARIZAR:
        if(res == ES_APERTURA)
        {
            apilar(&pila, contenidoEtiqueta, sizeof(contenidoEtiqueta));
            fprintf(pfNuevo, "%s", linea);
        }
        else if(res == ES_CIERRE)
        {
            verTope(&pila, contenidoPila, sizeof(contenidoPila));
            if(!strcmp(contenidoPila, contenidoEtiqueta))
            {
                desapilar(&pila, contenidoPila, sizeof(contenidoPila));
                fprintf(pfNuevo, "%s\n", linea);
            }
            else
            {
                generarEtiquetaApertura(contenidoEtiqueta, etiquetaNueva);
                fprintf(pfNuevo, "%s\n", etiquetaNueva);
                fprintf(pfNuevo, "%s\n", linea);
            }
        }
        else
        {
            fprintf(pfNuevo, "%s", linea);
        }
    }

    fclose(pf);
    fclose(pfNuevo);
    return 1;
}

//int trabajarLinea(t_pila *p)

void generarEtiquetaApertura(const char *cad, char *nueva)
{
    *nueva = '<';
    nueva++;
    while(*cad)
    {
        *nueva = *(char*)cad;
        (char*)cad++;
        nueva++;
    }

    *nueva = '>';
    *(nueva+1) = '\0';
}

int verificarSiHayEtiqueta(char *linea, char *contenido)
{
    char *ini = linea, aux;

    while(ES_BLANCO(*linea))
        linea++;

    if(*linea == '<' && *(linea+1)== '/')
    {
        linea+=2;
        while(*linea && *linea != '>')
            linea++;

        if(!*linea)
            return NO_ES_ETIQUETA;

        aux = *linea;
        *linea = '\0';
        strcpy(contenido, ini+2);
        *linea = aux;
        return ES_CIERRE;
    }
    if(*linea == '<')
    {
        while(*linea && *linea != '>')
                linea++;
        if(!*linea)
            return NO_ES_ETIQUETA;

        aux = *linea;
        *linea = '\0';
        strcpy(contenido, ini+1);
        *linea = aux;

        return ES_APERTURA;
    }

    return NO_ES_ETIQUETA;
}


