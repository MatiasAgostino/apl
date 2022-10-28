/**
-------------------------- ENCABEZADO --------------------------

Nombre del programa: monitoreo.cpp
Número de APL: 3
Número de ejercicio: 2
Número de entrega: Entrega

---------------- INTEGRANTES DEL GRUPO ----------------

        Apellido, Nombre       	        | DNI
        Agostino, Matías                | 43861796
 	    Colantonio, Bruno Ignacio       | 43863195
    	Fernández, Rocío Belén          | 43875244
    	Galo, Santiago Ezequiel         | 43473506
  	    Panigazzi, Agustín Fabián       | 43744593

 -------------------- FIN DE ENCABEZADO --------------------
**/

#include <bits/stdc++.h>
#include <thread>
#include <mutex>
#include <sys/inotify.h>
#include <dirent.h>                 /// Para leer sobre directorios.
#include <sys/stat.h>               /// Para chequear si un evento referencia a la creacion de un directorio.
#include <sys/types.h>              /// Para chequear si un evento referencia a la creacion de un directorio.
#include <unistd.h>                 /// Para chequear si un evento referencia a la creacion de un directorio.
#include <fcntl.h>                  /// Para establecer inotify de manera no bloqueante.
#include <errno.h>                  /// Para utilizar inotify por medio de i/o signals.

using namespace std;

/// Varibles globales.
const string logs = "./logs.txt";
mutex mtx;

void monitoreo(string directorio) {
    int fd = inotify_init(),
        wd;

    if (fd < 0) {
        cerr << "Error al comenzar el monitoreo en el subdirectorio: " << directorio;

        return;
    }

    wd = inotify_add_watch(fd, directorio.c_str(), IN_DELETE | IN_DELETE_SELF | IN_MOVE | IN_MOVE_SELF | IN_CREATE | IN_MODIFY);

    if (wd < 0) {
        cerr << "Error al crear el watcher en el subdirectorio" << directorio;

        close(fd);

        return;
    }

    FILE* pf;
    struct stat path;
    char buffer[4096];
    int flags = fcntl(fd, F_GETFL, 0),
        tamEvento;

    /// Estableciendo el file descriptor del directorio, abierto por inotify, de manera no bloqueante.
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);

    /// Si no hay evento, read no bloquea al thread. errno posee la
    /// signal acorde a la situacion. EAGAIN nos indica que no hay eventos
    /// para escuchar en un momento particular, nos interesa ese caso.
    while ((tamEvento = read(fd, buffer, 1024)) > 0 || errno == EAGAIN) {
        inotify_event* event = ((inotify_event*)buffer);
        string archivoEvento = directorio;

        archivoEvento += "/";
        archivoEvento += event->name;

        /// Diferentes acciones segun el evento.
        if (tamEvento > 0) {
            if (event->mask & IN_CREATE) {
                if (stat(archivoEvento.c_str(), &path) == 0) {
                    if (path.st_mode & S_IFDIR) {
                        mtx.lock();
                        pf = fopen(logs.c_str(), "a+");

                        if (!pf) {
                            cerr << "Error al abrir el archivo de logs." << '\n';

                            return;
                        }

                        fprintf(pf, "En %s: se creo el directorio %s\n", directorio.c_str(), archivoEvento.c_str());
                        fclose(pf);
                        mtx.unlock();
                    } else if (path.st_mode & S_IFREG) {
                        mtx.lock();
                        pf = fopen(logs.c_str(), "a+");

                        if (!pf) {
                            cerr << "Error al abrir el archivo de logs." << '\n';

                            return;
                        }

                        fprintf(pf, "En %s: se creo el archivo %s\n", directorio.c_str(), archivoEvento.c_str());
                        fclose(pf);
                        mtx.unlock();
                    }
                } else {
                    cerr << "Error al crear " << archivoEvento << '\n';
                }
            } else if (event->mask & IN_MODIFY) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return;
                }

                fprintf(pf, "En %s: se modifico el archivo %s\n", directorio.c_str(), archivoEvento.c_str());
                fclose(pf);
                mtx.unlock();

            /// En linux, eliminar un arhivo o directorio mediante la GUI significa moverlo a papelera. Debemos
            /// atender ese caso.
            } else if (event->mask & IN_MOVE) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return;
                }

                fprintf(pf, "En %s: se movio a papelera %s\n", directorio.c_str(), archivoEvento.c_str());
                fclose(pf);
                mtx.unlock();

            /// Por tanto, cuando se detecta que el directorio monitoreado fue movido, se asume una eliminacion.
            }  else if (event->mask & IN_DELETE || event->mask & IN_DELETE_SELF || event->mask & IN_MOVE_SELF) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return;
                }

                fprintf(pf, "Se elimino el subdirectorio %s - Fin del thread\n", directorio.c_str());
                fclose(pf);
                mtx.unlock();

                inotify_rm_watch(fd, wd);
                close(fd);

                return;
            }
        }
    }
}

int main(int argc, char** argv)
{
    ios_base::sync_with_stdio(false);
    cin.tie(0);

    if (argc > 2) {
        cout << "El programa no acepta mas de un parametro. Ingrese '-h' o '--help' para obtener informacion sobre el mismo.\n";

        return 0;
    }

    if (argc <= 2 && (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help"))) {
        cout << "El programa monitorea el directorio que le es pasado por parametro.\n";
        cout << "Se monitorean cambios en archivos y en subdirectorios de profundidad nivel 1.\n";
        cout << "Ejemplo de uso: ./monitoreo /paht\n";
        cout << "Para compilarlo escriba el siguiente comando: make\n";

        return 0;
    }

    DIR* dp = nullptr;
    struct dirent* dir = nullptr;

    dp = opendir(argc == 2 ? argv[1] : ".");

    if (!dp) {
        cout << "No se encontro el directorio " << argv[1] << '\n';

        closedir(dp);

        return 0;
    }

    vector<string> dirs;

    /// Para saber la cantidad de subdirectorios que el directorio padre tiene
    /// inicialmente.
    while ( (dir = readdir(dp)) )
        if (dir->d_type == DT_DIR && strcmp(dir->d_name, ".") && strcmp(dir->d_name, "..")) {
            string directorio(argv[1]);

            directorio += "/";
            directorio += dir->d_name;
            dirs.push_back(directorio);
        }

    closedir(dp);

    int fd = inotify_init(),
        wd;

    if (fd < 0) {
        cout << "Error al comenzar el monitoreo.\n";

        return 0;
    }

    /// Creando el watcher general.
    wd = inotify_add_watch(fd, argv[1], IN_DELETE | IN_DELETE_SELF | IN_MOVE | IN_MOVE_SELF |IN_CREATE | IN_MODIFY);

    if (wd < 0) {
        cout << "Error al crear el watcher.\n";

        close(fd);

        return 0;
    }

    FILE* pf;
    struct stat path;
    char buffer[4096];
    int flags = fcntl(fd, F_GETFL, 0),
        tamEvento;

    /// Para establecer, tambien, inotify no bloqueante.
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    pf = fopen(logs.c_str(), "w+");

    if (!pf) {
        cerr << "Error al crear el archivo de logs." << '\n';

        return -1;
    }

    fprintf(pf, "ARCHIVO DE LOGS\n");
    fclose(pf);

    /// Polling
    while ((tamEvento = read(fd, buffer, 1024)) > 0 || errno == EAGAIN) {
        inotify_event* event = ((inotify_event*)buffer);
        string archivoEvento = argv[1];

        archivoEvento += "/";
        archivoEvento += event->name;

        if (dirs.size() > 0) {
            int ds = dirs.size() - 1;
            /// Crear un hilo por cada subdirectorio dentro del directorio padre.
            for (int i = ds; i >= 0; i--) {
                thread t(monitoreo, dirs[i]);

                t.detach();
            }

            dirs.clear();
        }

        if (tamEvento > 0) {
            if (event->mask & IN_CREATE) {
                if (stat(archivoEvento.c_str(), &path) == 0) {
                    if (path.st_mode & S_IFDIR) {
                        mtx.lock();
                        pf = fopen(logs.c_str(), "a+");

                        if (!pf) {
                            cerr << "Error al abrir el archivo de logs." << '\n';

                            return -1;
                        }

                        fprintf(pf, "En %s: se creo el directorio: %s\n", argv[1], archivoEvento.c_str());
                        fclose(pf);
                        dirs.push_back(archivoEvento);
                        mtx.unlock();
                    } else if (path.st_mode & S_IFREG) {
                        mtx.lock();
                        pf = fopen(logs.c_str(), "a+");

                        if (!pf) {
                            cerr << "Error al abrir el archivo de logs." << '\n';

                            return -1;
                        }

                        fprintf(pf, "En %s: se creo el archivo: %s\n", argv[1], archivoEvento.c_str());
                        fclose(pf);
                        mtx.unlock();
                    }
                } else {
                    cerr << "Error al crear " << archivoEvento << '\n';
                }
            } else if (event->mask & IN_MODIFY) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return -1;
                }

                fprintf(pf, "En %s: se modifico el archivo: %s\n", argv[1], archivoEvento.c_str());
                fclose(pf);
                mtx.unlock();
            } else if (event->mask & IN_MOVE) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return -1;
                }

                fprintf(pf, "En %s: se movio a papelera: %s\n", argv[1], archivoEvento.c_str());
                fclose(pf);
                mtx.unlock();
            } else if(event->mask & IN_DELETE) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return -1;
                }

                fprintf(pf, "En %s: se elimino: %s\n", argv[1], archivoEvento.c_str());
                fclose(pf);
                mtx.unlock();
            /// Detecciones de movimiento en el directorio, se asume una elminacion.
            } else if (event->mask & IN_DELETE_SELF || event->mask & IN_MOVE_SELF) {
                mtx.lock();
                pf = fopen(logs.c_str(), "a+");

                if (!pf) {
                    cerr << "Error al abrir el archivo de logs." << '\n';

                    return -1;
                }

                fprintf(pf, "Se elimino el directorio principal\nFin del monitoreo");
                fclose(pf);
                mtx.unlock();

                inotify_rm_watch(fd, wd);
                close(fd);

                return 0;
            }
        }
    }

    inotify_rm_watch(fd, wd);
    close(fd);

    return 0;
}

/** -------------------- FIN DE ARCHIVO -------------------- **/
