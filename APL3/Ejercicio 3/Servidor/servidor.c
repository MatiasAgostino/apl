#include <stdio.h>
#include <stdlib.h> 
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>

#define TAM_COMANDO 100  
#define NOMBRE_ARCHIVO 50
#define LINEA_ARCHIVO 200
#define SIN_STOCK 1
#define LIST 2
#define QUIT 3
#define STOCK 4
#define REPO 5
#define INVALIDO 77
#define ES_BLANCO(X) ((X)==' ' || (X)=='\t' || (X)=='\n' || (X)=='\r')
#define TAM_DESC 50
#define MINIMO(X,Y) ((X) < (Y) ? (X) : (Y))

typedef struct {
	char comando[TAM_COMANDO];
	int parteNumerica;
}t_comando;

typedef struct {
	int id;
	char descripcion[TAM_DESC];
	int precio;
	int costo;
	int stock;
}t_producto;

//LISTA

typedef struct s_nodo 
{
	void *info;
	unsigned tam;
	struct s_nodo *siguiente;
}t_nodo;

typedef t_nodo* t_lista;

//EJERCICIO
int cantidadDeLineasArch(char *nombreArch);
int bajarArchivo(t_lista *lista, char *nombreArch);
int trozarLongitudVariable(t_producto *producto, char *s);
int mostrarProducto(const void *dato, int *fifo);
void ayuda();
void borrarFifos();
int crearFifos();

//COMANDOS
int stockPorId(const void *dato, int id, int *fifo);
int sinStock(const void *dato, int *fifo);
int listar(const void *dato, int *fifo);
int reponer(const void *dato, int cantidad, int *fifo);

//LISTA
void crearLista(t_lista *lista);
int insertarAlFinal(t_lista *lista, unsigned tam, void *dato);
int verUltimoLista(const t_lista *lista, unsigned tam, void *dato);
int recorrerLista(t_lista *lista, int(*accion)(const void *dato, int* fifo), int* fif);
int recorrerListaConParam(t_lista *lista, int id, int *fif, int(*accion)(const void *dato, int id, int *fifo));

//DEMONIO

void manejadorDemonio(int signal);
bool finDemonio = false;

int main(int argc, char *argv[]){
	
	char archivo[NOMBRE_ARCHIVO];
	char aux[NOMBRE_ARCHIVO] = "../Archivos/";
	int fifo1, fifo2;
	int cant;
	t_lista lista, inicio;
	t_comando comando;
	t_producto prodFinalizador;
	int retorno;
	bool fin = false;
	signal(SIGINT, SIG_IGN);
	
	
	//Se revisa si se recibió un parametro de ayuda     
	if(argc != 2){    
		printf("Error de parametros.\n\n");         
		ayuda();
		return 0;
	}
	     
	if(strcmp(argv[1],"-help") == 0 || strcmp(argv[1],"-h") == 0){             					ayuda();  
		return 1;         
	} 
	
	char archivoClientes[100] = "../Logs/cliente.txt";
	char archivoServidor[100] = "../Logs/servidor.txt";
	int seCrearonFifos;
		
	//SI HAY UN SERVIDOR, CIERRA EL PROGRAMA
	//SOLO SE PERMITE UNA INSTANCIA
	if(access(archivoServidor, F_OK) == 0) {
		printf("Solo se permite una instancia de servidor.\n\n");
		return 0;
	}
	
	strcpy(archivo, argv[1]);
	crearLista(&lista);
	strcat(aux, archivo);
	cant = cantidadDeLineasArch(aux);
			
	if(cant == 0){
		printf("ERROR. ARCHIVO VACIO\n");
		exit(0);
	} else if(cant == -1){
		printf("ERROR. ARCHIVO INEXISTENTE\n");
		exit(0);
	}
	
	//DEMONIO
	signal(SIGUSR2, manejadorDemonio);
	pid_t pid = fork();
	
	if(pid < 0)
		return 1;
	
	if(pid > 0){
		return 0;
	}
	
	pid_t sid = setsid();
	if(sid < 0){
		printf("Erorr al ejecutar setsid: %d\n", sid);
		return 1;
	}
			
	//SI YA HAY UN CLIENTE, NO CREA LAS FIFOS
	if((seCrearonFifos =  access(archivoClientes, F_OK)) != 0) {
		if(crearFifos() == -1){
			printf("ERROR AL CREAR LAS FIFOS\n\n");
			exit(1);
		}
	}
	
	//ESCRIBO EL PID PARA QUE CLIENTE ME CIERRE CUANDO MANDA QUIT		
	FILE *pf = fopen(archivoServidor, "wb");
	fwrite(&pid,1,sizeof(pid_t), pf);
			
	bajarArchivo(&lista, aux);
	inicio = lista;

	fifo1 = open("../Fifos/fifo1", O_RDONLY);
	fifo2 = open("../Fifos/fifo2", O_WRONLY);
			
	if(fifo1 == -1 || fifo2 == -1) {
		printf("Error al abrir las fifos.\n");
		exit(1);
	}
	
	read(fifo1, &comando, sizeof(t_comando));
			
	prodFinalizador.id = -1;
	while(strcmp(comando.comando, "QUIT") != 0){
		//lista = inicio;
						
		if(!strcmp(comando.comando, "SIN_STOCK")){
			retorno = recorrerLista(&lista, sinStock, &fifo2);
			write(fifo2, &prodFinalizador, sizeof(t_producto));
				
		} else if(!strcmp(comando.comando, "LIST")){
			
		recorrerLista(&lista, listar, &fifo2);
		write(fifo2, &prodFinalizador, sizeof(t_producto));
				
		} else if(!strcmp(comando.comando, "STOCK")){
				
		retorno = recorrerListaConParam(&lista, comando.parteNumerica,&fifo2, stockPorId);
		if(!retorno) 
			write(fifo2, &prodFinalizador, sizeof(t_producto));
				
		} else if(!strcmp(comando.comando, "REPO")){
			
		int total = recorrerListaConParam(&lista, comando.parteNumerica,&fifo2, reponer); 
		write(fifo2, &total, sizeof(int));
		}
		
		read(fifo1, &comando, sizeof(t_comando));
	}
	
	close(fifo1);
	close(fifo2);
			
	if(seCrearonFifos != 0)
		borrarFifos();
	fclose(pf);
	remove(archivoServidor);
	
	return 0;
}

int cantidadDeLineasArch(char *nombreArch){
	
	char linea[LINEA_ARCHIVO];
	char *aux;
	FILE *pf = fopen(nombreArch, "rt");
	if(!pf)
		return -1;
		
	int cant = 0, caracteres;
	
	while(fgets(linea, sizeof(linea), pf)){
		
		caracteres = 0;
		aux = linea;
		while(*aux && *aux != '\n'){
			if(!ES_BLANCO(*aux)){
				caracteres++;
			}
			aux++;		
		}
		
		if(caracteres > 0)
			cant++;
	}
	
	fclose(pf);
	return cant;
}

int trozarLongitudVariable(t_producto *producto, char *s){
 	char *aux = strchr(s, '\n');
    *aux = '\0';

    aux = strrchr(s, ';'); 
    *aux = '\0';
    sscanf(aux + 1, "%d", &producto->stock);

    aux = strrchr(s, ';');
    *aux = '\0';
    sscanf(aux + 1, "%d", &producto->costo);

    aux = strrchr(s, ';');
    *aux = '\0';
    sscanf(aux + 1, "%d", &producto->precio);
    
    aux = strrchr(s, ';');
    *aux = '\0';
    strcpy(producto->descripcion, aux + 1);

    sscanf(s, "%d", &producto->id);

    return 1;
}

int bajarArchivo(t_lista *lista, char *nombreArch){
	
	char linea[LINEA_ARCHIVO];
	char *aux;
	t_producto producto;
	
	FILE *pf = fopen(nombreArch, "rt");
	if(!pf)
		return -1;
		
	int flag = 0;
	while(fgets(linea, sizeof(linea), pf)){
		
		if(flag){
			trozarLongitudVariable(&producto, linea);
			insertarAlFinal(lista, sizeof(t_producto), &producto);
		}
		
		flag++;
	}
	
	fclose(pf);
	
	return 1;
}

int mostrarProducto(const void *dato, int *fifo){
	
	t_producto *prod = (t_producto*)dato;
	
	printf("ID: %d\n", prod->id);
	printf("Descripcion: %s\n", prod->descripcion);
	printf("Precio: %d\n", prod->precio);
	printf("Costo: %d\n", prod->costo);
	printf("Stock: %d\n", prod->stock);
	
	return 1;
}

//COMANDOS

int stockPorId(const void *dato, int id, int *fifo){
	
	t_producto *prod = (t_producto*)dato;
	
	if(prod->id == id){
		write(*fifo, prod, sizeof(t_producto));
		//printf("%s %du\n", prod->descripcion, prod->stock);
		
		return 1;
	}
	
	return 0;
}

int sinStock(const void *dato, int *fifo){
	
	t_producto *prod = (t_producto*)dato;
	
	if(prod->stock != 0)
		return 0;
	
	write(*fifo, prod, sizeof(t_producto));
	
	return 1;
}

int listar(const void *dato, int *fifo){

	t_producto *prod = (t_producto*)dato;
	write(*fifo, prod, sizeof(t_producto));
	return 1;
}

int reponer(const void *dato, int cantidad, int *fifo){
	
	t_producto *prod = (t_producto*)dato;
	
	if(prod->stock != 0){
		return 0;
	}
	
	return prod->costo * cantidad;
}

//LISTA

void crearLista(t_lista *lista){
	*lista = NULL;
}

int insertarAlFinal(t_lista *lista, unsigned tam, void *dato){

	t_nodo *nodo;
	while(*lista){
		lista = &(*lista)->siguiente;
	}
	
	nodo = (t_nodo*)malloc(sizeof(t_nodo));
	if(!nodo)
		return 0;
	
	nodo->info = malloc(tam);
	if(!nodo->info){
		free(nodo);
		return 0; 
	}
	
	memcpy(nodo->info, dato, tam);
	nodo->tam = tam;
	nodo->siguiente = NULL;
	(*lista) = nodo;
	return 1;
}

int recorrerLista(t_lista *lista, int(*accion)(const void*dato, int *fifo), int *fifo){
	
	int huboCambios = 0;
	int retorno;
	while(*lista){
		retorno = accion((*lista)->info, fifo);
		huboCambios += retorno;
		lista = &(*lista)->siguiente;
	}
	
	return huboCambios;
}

int recorrerListaConParam(t_lista *lista, int id, int *fifo, int(*accion)(const void*dato, int id, int *fifo)){
	
	int huboCambios = 0;
	int retorno;
	
	while(*lista){
		retorno = accion((*lista)->info, id, fifo);
		huboCambios += retorno;
		
		lista = &(*lista)->siguiente;
	}
	
	return huboCambios;
}

void ayuda(){
	printf("Ayuda\n");
}

int crearFifos(){

	if(mkfifo("../Fifos/fifo1", 0666) == -1 || mkfifo("../Fifos/fifo2", 0666) == -1)
		return -1;
	else 
		return 1;
}

void borrarFifos(){
	unlink("../Fifos/fifo1");
	unlink("../Fifos/fifo2");
}

void manejadorDemonio(int signal){
	finDemonio = true;
}
