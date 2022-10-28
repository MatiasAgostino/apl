.PHONY: clean

comp=g++

clienteComp: cliente.o
	$(comp) -o clienteComp cliente.o

cliente.o: cliente.c
	$(comp) -c cliente.c
	
servidorComp: servidor.o
	$(comp) -o servidorComp servidor.o

servidor.o: servidor.c
	$(comp) -c servidor.c

	
clean:
	rm *.o
