/*
-------------------------- ENCABEZADO --------------------------

Nombre del programa: ejercicio1.c
Número de APL: 3
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
*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>	// Biblioteca para utilizar pid_t
#include <unistd.h>		// Biblioteca para utilizar fork
#include <sys/wait.h>	// Biblioteca para utilizar wait
#include <signal.h>		// Biblioteca para utilizar signal

void mostrarAyuda();
void mostrarInformacion(pid_t pid, unsigned int numGen, pid_t pidPadre, const char* parentescoTipo);
void mensajeError(const char* proceso);

bool finDemonio = false;
void manejadorDemonio(int signal);

bool finEspera = false;
void manejadorEspera(int signal);

int main(int argc, char* argv[])
{
	if(argc > 1)
	{
		if( strcmp("-h", argv[1]) == 0 || strcmp("--help", argv[1]) == 0 )
		{
			mostrarAyuda();
			return 0;
		}
		else
		{
			puts("La opción ingresada no es válida. Por favor intente de nuevo.");
			return 1;
		}
	}

	mostrarInformacion(getpid(), 1, getppid(), "Padre");

	// Asociación de la señal SIGUSR2 con el manejador propio de los procesos (para poder esperar a que se ingrese una tecla), se "hereda" con el fork
	signal( SIGUSR2, manejadorEspera );

	/* -------------- Creación del Hijo 1 -------------- */

	pid_t pidHijo1 = fork();

	if( pidHijo1 == -1 )
	{
		mensajeError("Hijo 1");
		return 1;
	}

	if( pidHijo1 == 0 )
	{
		mostrarInformacion(getpid(), 2, getppid(), "Hijo");

		/* -------------- Creación del Nieto 1 -------------- */

		pid_t pidNieto1 = fork();

		if( pidNieto1 == -1 )
		{
			mensajeError("Nieto 1");
			return 1;
		}

		if( pidNieto1 == 0 )
		{
			mostrarInformacion(getpid(), 3, getppid(), "Nieto");

			/* -------------- Creación del Bisnieto 1 -------------- */

			pid_t pidBisnieto1 = fork();

			if( pidBisnieto1 == -1 )
			{
				mensajeError("Bisnieto 1");
				return 1;
			}

			if( pidBisnieto1 == 0 )
			{
				mostrarInformacion(getpid(), 4, getppid(), "Bisnieto");

				while( !finEspera )
					usleep(100000);

				return 0;
			}

			/* -------------- Creación del Bisnieto 2 -------------- */

			pid_t pidBisnieto2 = fork();

			if( pidBisnieto2 == -1 )
			{
				mensajeError("Bisnieto 2");
				return 1;
			}

			if( pidBisnieto2 == 0 )
			{
				mostrarInformacion(getpid(), 4, getppid(), "Bisnieto");

				while( !finEspera )
					usleep(100000);

				return 0;
			}

			while( !finEspera )
				usleep(100000);
	
			kill(pidBisnieto1, SIGUSR2);
			kill(pidBisnieto2, SIGUSR2);
	
			waitpid(pidBisnieto1, NULL, 0);
			waitpid(pidBisnieto2, NULL, 0);

			return 0;
		}

		/* -------------- Creación del Nieto 2 -------------- */

		pid_t pidNieto2 = fork();

		if( pidNieto2 == -1 )
		{
			mensajeError("Nieto 2");
			return 1;
		}

		if( pidNieto2 == 0 )
		{
			mostrarInformacion(getpid(), 3, getppid(), "Nieto");

			/* -------------- Creación del Bisnieto 3 -------------- */

			pid_t pidBisnieto3 = fork();

			if( pidBisnieto3 == -1 )
			{
				mensajeError("Bisnieto 3");
				return 1;
			}

			if( pidBisnieto3 == 0 )
			{
				mostrarInformacion(getpid(), 4, getppid(), "Bisnieto");

				/* -------------- Creación del Demonio -------------- */

				// Asociación de la señal SIGUSR1 con el manejador propio del demonio
				signal( SIGUSR1, manejadorDemonio );
	
				pid_t pidDemonio = fork();
	
				if( pidDemonio == -1 )
				{
					mensajeError("Demonio");
					return 1;
				}
	
				// Se muestra la información del demonio una vez creado
				if( pidDemonio == 0 )
				{
					mostrarInformacion(getpid(), 5, getppid(), "Demonio");

					puts("Los procesos se encuentran pausados para poder verificar con el comando \"ps -auxf\" toda la jerarquía de procesos generada. Presione enter para finalizar el programa.");
					puts("Nota: El demonio se continuará ejecutando en segundo plano luego de finalizar el programa. Para finalizarlo, ejecute el comando \"kill -SIGUSR1 <pid_demonio>\"");
				}
				// Finalización del proceso padre para dejar huérfano al hijo
				else
				{
					while( !finEspera )
						usleep(100000);

					return 0;
				}
	
				// En esta instancia solo se encuentra el demonio (huérfano)
	
				// Creamos una nueva sesión para el demonio, para que no tome la terminal hasta que se finalice
			 	pid_t sid = setsid();
	
			  	if (sid < 0)
				{
					printf("Error al ejecutar setsid\n");
			    		return 1;
			  	}
	
				// Espera activa hasta que se reciba la señal SIGUSR1
			  	while( !finDemonio )
					usleep(100000);
	
				return 0;
			}

			while( !finEspera )
				usleep(100000);
	
			kill(pidBisnieto3, SIGUSR2);
	
			waitpid(pidBisnieto3, NULL, 0);

			return 0;
		}

		while( !finEspera )
			usleep(100000);

		kill(pidNieto1, SIGUSR2);
		kill(pidNieto2, SIGUSR2);

		waitpid(pidNieto1, NULL, 0);
		waitpid(pidNieto2, NULL, 0);

		return 0;
	}

	/* -------------- Creación del Hijo 2 -------------- */

	pid_t pidHijo2 = fork();

	if( pidHijo2 == -1 )
	{
		mensajeError("Hijo 2");
		return 1;
	}

	if( pidHijo2 == 0 )
	{
		mostrarInformacion(getpid(), 2, getppid(), "Hijo");

		/* -------------- Creación del Nieto 3 -------------- */

		pid_t pidNieto3 = fork();

		if( pidNieto3 == -1 )
		{
			mensajeError("Nieto 3");
			return 1;
		}

		if( pidNieto3 == 0 )
		{
			mostrarInformacion(getpid(), 3, getppid(), "Nieto");

			/* -------------- Creación del Bisnieto 4 -------------- */

			pid_t pidBisnieto4 = fork();

			if( pidBisnieto4 == -1 )
			{
				mensajeError("Bisnieto 4");
				return 1;
			}

			if( pidBisnieto4 == 0 )
			{
				mostrarInformacion(getpid(), 4, getppid(), "Bisnieto");

				while( !finEspera )
					usleep(100000);

				return 0;
			}

			/* -------------- Creación del Bisnieto 5 -------------- */

			pid_t pidBisnieto5 = fork();

			if( pidBisnieto5 == -1 )
			{
				mensajeError("Bisnieto 5");
				return 1;
			}

			if( pidBisnieto5 == 0 )
			{
				mostrarInformacion(getpid(), 4, getppid(), "Bisnieto");

				pid_t pidZombie1 = fork();

				if( pidZombie1 == -1 )
				{
					mensajeError("Zombie 1");
					return 1;
				}

				if( pidZombie1 == 0 )
				{
					mostrarInformacion(getpid(), 5, getppid(), "Zombie");

					return 0;
				}

				pid_t pidZombie2 = fork();

				if( pidZombie2 == -1 )
				{
					mensajeError("Zombie 2");
					return 1;
				}

				if( pidZombie2 == 0 )
				{
					mostrarInformacion(getpid(), 5, getppid(), "Zombie");

					return 0;
				}

				while( !finEspera )
					usleep(100000);

				waitpid(pidZombie1, NULL, 0);
				waitpid(pidZombie2, NULL, 0);

				return 0;
			}

			while( !finEspera )
				usleep(100000);

			kill(pidBisnieto4, SIGUSR2);
			kill(pidBisnieto5, SIGUSR2);

			waitpid(pidBisnieto4, NULL, 0);
			waitpid(pidBisnieto5, NULL, 0);

			return 0;
		}

		while( !finEspera )
			usleep(100000);

		kill(pidNieto3, SIGUSR2);

		waitpid(pidNieto3, NULL, 0);

		return 0;
	}

	// Una vez que el proceso padre reciba la tecla ingresada, procede a enviar la señal SIGUSR2 a sus hijos, los cuales enviarán la señal a sus hijos y así sucesivamente,
	// de manera tal que los procesos queden en espera y así poder ver con el comando ps o pstree la jerarquía de procesos generada.
	// El uso de señales permite finalizar todos los procesos con un único getchar

	getchar();

	kill(pidHijo1, SIGUSR2);
	kill(pidHijo2, SIGUSR2);

	waitpid(pidHijo1, NULL, 0);
	waitpid(pidHijo2, NULL, 0);

	return 0;
}

void mostrarAyuda()
{
	puts("-------------- AYUDA --------------");
	puts("\nEste programa genera, mediante el uso del syscall fork, el siguiente escenario:");
	puts("- 2 procesos hijos");
	puts("- 3 procesos nietos");
	puts("- 5 procesos bisnietos");
	puts("- 2 procesos zombies, en cualquier nivel");
	puts("- 1 proceso demonio, que debe quedar activo");
	puts("\nCada proceso no podrá tener más de 2 hijos y deberá mostrar por pantalla la siguiente información:");
	puts("Soy el proceso con PID ...... y pertenezco a la generación Nº ....... Pid: ......... Pid padre: ..... Parentesco/Tipo: [nieto, hijo, zombie]");
	puts("\nLuego, se espera hasta que se presione una tecla antes de finalizar, para poder verificar con el comando ps o pstree toda la jerarquía de procesos generada.");

	puts("\nPara mostrar la ayuda, ejecute:");
	puts("- ./ejercicio1 -h");
	puts("- ./ejercicio1 --help");
}

void mostrarInformacion(pid_t pid, unsigned int numGen, pid_t pidPadre, const char* parentescoTipo)
{
	printf("-------------- INFORMACIÓN SOBRE PROCESO CREADO --------------\nSoy el proceso con PID %d y pertenezco a la generación Nº %u Pid: %d Pid padre: %d Parentesco/Tipo: %s\n\n", pid, numGen, pid, pidPadre, parentescoTipo);
}

void mensajeError(const char* proceso)
{
	printf("Ha sucedido un error al crear el nuevo proceso: %s\n", proceso);
}

void manejadorDemonio(int signal)
{
	finDemonio = true;
}

void manejadorEspera(int signal)
{
	finEspera = true;
}

// -------------------- FIN DE ARCHIVO --------------------
