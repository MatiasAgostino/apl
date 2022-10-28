.PHONY: clean

comp=g++ # Especificamos el compilador

ejercicio1: ejercicio1.o
	$(comp) -o ejercicio1 ejercicio1.o

ejercicio1.o: ejercicio1.c
	$(comp) -c ejercicio1.c

clean:
	rm *.o