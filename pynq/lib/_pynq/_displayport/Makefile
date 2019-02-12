CC ?= gcc
CXX ?= g++

OBJSC = displayport.o 
INC = -I${PYNQ_BUILD_ROOT}/usr/include/libdrm

all:	
	$(CXX) -fPIC $(INC) -c -g -std=c++11 displayport.cpp $(CFLAGS)
	$(CXX) -shared -fPIC -rdynamic $(OBJSC) -ldrm -o libdisplayport.so $(CFLAGS) $(LDFLAGS)
	rm *.o
