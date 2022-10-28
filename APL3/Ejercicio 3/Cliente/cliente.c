#include <stdio.h>
#include <stdlib.h> 
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>

#define TAM_COMANDO 100  
#define SIN_STOCK 1
#define LIST 2
#define QUIT 3
#define STOCK 4
#define REPO 5
#define INVALIDO 77
#define TAM_DESC 50
 
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
 
void mostrarOpciones(); 
void resolver(pid_t *pid); 
void ayuda();
int validarComando(char *comando, t_comando *parteEntera);
void removerSaltoDeLinea(char *string);
int crearFifos();
void borrarFifos();
void listarProducto(void *dato);
void mostrarProducto(void *dato);

int main(int argc, char *argv[]) {  
	 
	pid_t pidServer;
	signal(SIGINT, SIG_IGN);
	//Se revisa si se recibió un parametro de ayuda     
	if(argc == 2){         
		if(strcmp(argv[1],"-help") == 0 || strcmp(argv[1],"-h") == 0){             			ayuda();             
		} else {
			printf("Este script NO recibe parametros.\n");
			ayuda();
		}
	} else if(argc >= 3){         
		printf("Este script NO recibe parametros.\n");         
		ayuda();     
	} else { 
		
		char archivoClientes[100] = "../Logs/cliente.txt";
		char archivoServidor[100] = "../Logs/servidor.txt";
		int seCrearonFifos;
		//SE CHEQUEA QUE EL ARCHIVO CLIENTE NO EXISTA,
		//SI EXISTE, QUIERE DECIR QUE YA HAY UN CLIENTE CONECTADO
		
		if(access(archivoClientes, F_OK) == 0) {
			printf("Solo se permite una instancia de cliente.\n\n");
			return 0;
		} 
		
		//SI NO HAY UN SERVIDOR, SE CREAN LAS FIFOS
		if((seCrearonFifos = access(archivoServidor, F_OK)) != 0){
			if(crearFifos() == -1){
				printf("ERROR AL CREAR LAS FIFOS\n\n");
				exit(1);
			}
		}
			
		FILE *pf = fopen(archivoClientes, "w");
		resolver(&pidServer);
		
		if(seCrearonFifos != 0)
			borrarFifos();
		fclose(pf);
		remove(archivoClientes);
	}   
	   
	kill(pidServer, SIGUSR2);
	return 0; 
}

void mostrarOpciones(){    
	printf("\n---------------LISTADO DE OPCIONES---------------\n\n");     
	printf("STOCK ID_Producto|Muestra descripcion y stock para el producto dado\n\n");         
	printf("SIN_STOCK|Muestra ID, descripcion y costo de los productos con STOCK cero\n\n");     
	printf("REPO Cantidad|Muestra el costo total de reponer una cantidad dada para cada producto sin stock\n\n");         
	printf("LIST|Muestra ID, descripcion y precio de todos los productos existentes\n\n");     
	printf("QUIT|Finaliza la ejecucion\n\n"); 
}   

void resolver(pid_t *pidServer){       
	char comando[TAM_COMANDO]; 
	char fin[TAM_COMANDO] = "QUIT";
	int tipoComando, parteEntera, cantAReponer;
	t_comando comandoEntero;
	int fifo1, fifo2;
	t_producto producto;
	
	fifo1 = open("../Fifos/fifo1", O_WRONLY);
	fifo2 = open("../Fifos/fifo2", O_RDONLY);
	
	if(fifo1 == -1 || fifo2 == -1) {
		printf("Error al abrir las fifos.\n");
		exit(1);
	}
	  
	do{         
		mostrarOpciones();         
		printf("Ingrese la acción que desea:");      
		fgets(comando, TAM_COMANDO, stdin);
		removerSaltoDeLinea(comando);
		tipoComando = validarComando(comando, &comandoEntero);  
		
		system("clear");
		
		
		if(tipoComando == INVALIDO){
			printf("-------------Comando invalido-------------\n\n");
		} else {
			//ENVIAR COMANDO
			
			//printf("%s\n", comandoEntero.comando);
			//printf("%d\n", comandoEntero.parteNumerica);
			
			write(fifo1, &comandoEntero, sizeof(t_comando));
			
			//RECIBIR RESPUESTA
			if(tipoComando == SIN_STOCK || tipoComando == LIST){
				//Defino como criterio ID finalizacion -1
				read(fifo2, &producto, sizeof(t_producto));
				
				//LEO EL PID DEL DEMONIO SERVIDOR PARA MATARLO
				if(!strcmp(comando, "QUIT")){
					FILE *pf = fopen("../Logs/servidor.txt", "rb");
					fread(pidServer, 1, sizeof(pid_t), pf);
				}
				
				if(producto.id == -1 && tipoComando == SIN_STOCK)
					printf("NO hay productos sin stock.\n\n");
				else if(producto.id == -1 && tipoComando == LIST)
					printf("NO hay productos.\n\n");
				
				while(producto.id != -1){
					listarProducto(&producto);
					read(fifo2, &producto, sizeof(t_producto));
				}
				
			} else if(tipoComando == STOCK) {
				read(fifo2, &producto, sizeof(t_producto));
				if(producto.id == -1){
					printf("NO hay productos con ese ID.\n\n");
				} else {
					mostrarProducto(&producto);
				}
				
			} else if(tipoComando == REPO) {
			
				read(fifo2, &cantAReponer, sizeof(int));
				printf("$%d",cantAReponer);
			} 
		}
		
	}while(strcmp(comando,"QUIT") != 0);    
	
	
	close(fifo1);
	close(fifo2); 
}   

void removerSaltoDeLinea(char *string){
	int largo = strlen(string);
	
	if(largo > 1 && string[largo-1] == '\n')
		string[largo-1] = '\0';
}

int validarComando(char *comando, t_comando *comandoEntero){
	
	char comandoString[TAM_COMANDO];
	int parteEntera;
	
	if(!strcmp(comando, "SIN_STOCK")){
		strcpy(comandoEntero->comando, comando);
		return SIN_STOCK;
	}
	else if(!strcmp(comando, "LIST")){
		strcpy(comandoEntero->comando, comando);
		return LIST;
	}
	else if(!strcmp(comando, "QUIT")){
		strcpy(comandoEntero->comando, comando);
		return QUIT;
	}
	else {
		sscanf(comando, "%s %d", comandoString, &parteEntera);
		
		//printf("%s   a\n", comandoString);
		if(!strcmp(comandoString, "STOCK")){
			strcpy(comandoEntero->comando, comandoString);
			comandoEntero->parteNumerica = parteEntera;
			return STOCK;
		} else if(!strcmp(comandoString, "REPO")){
			strcpy(comandoEntero->comando, comandoString);
			comandoEntero->parteNumerica = parteEntera;
			return REPO;
		} else 
			return INVALIDO;
	}	
} 

int crearFifos(){

	if(mkfifo("../Fifos/fifo1", 0666) == -1 || mkfifo("../Fifos/fifo2", 0666) == -1)
		return -1;
	else 
		return 1;
}

void listarProducto(void *dato){
	
	t_producto *prod = (t_producto*)dato;
	
	printf("%d %s $%d\n", prod->id, prod->descripcion, prod->precio);
}

void mostrarProducto(void *dato){
	
	t_producto *prod = (t_producto*)dato;
	
	printf("%s %du\n", prod->descripcion, prod->stock);
}

void borrarFifos(){
	unlink("../Fifos/fifo1");
	unlink("../Fifos/fifo2");
}

void ayuda(){     
	printf("ayuda\n"); 
} 
