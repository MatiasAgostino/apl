.PHONY: clean

comp=g++

servidorComp: servidor.o
	$(comp) -o servidorComp servidor.o

servidor.o: servidor.c
	$(comp) -c servidor.c

	
clean:
	rm *.o
