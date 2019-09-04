all: libLAP.so

2phrpasf2.o: 2phrpasf2.c 2phrpasf2.h
	gcc -O3 -c -fpic 2phrpasf2.c -o 2phrpasf2.o

libLAP.so: 2phrpasf2.o
	gcc -O3 -shared -o ../libLAP.so 2phrpasf2.o