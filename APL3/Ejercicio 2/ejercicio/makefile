.PHONY: clean

comp=g++

monitoreo: monitoreo.o
	$(comp) -o monitoreo monitoreo.o -w -std=c++17 -lrt -pthread

monitoreo.o: monitoreo.cpp
	$(comp) -c monitoreo.cpp

clean:
	rm *.o
