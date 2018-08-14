CC ?= gcc
CXX ?= g++

OBJSC = displayport.o 
INC = -I/usr/include/libdrm

all:	
	$(CXX) -fPIC $(INC) -c -g -std=c++11 displayport.cpp
	$(CXX) -shared -fPIC -rdynamic $(OBJSC) -ldrm -o libdisplayport.so
	rm *.o
