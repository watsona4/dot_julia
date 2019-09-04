	#===========================MakeFile==============================
# To compile 
#================================================================

EXDIR = $(shell pwd)


# ---------------------------------------------------------------------
# Compiler selection 
# ---------------------------------------------------------------------

CCC = g++

# ---------------------------------------------------------------------
# Compiler options 
# ---------------------------------------------------------------------

CCOPT = -Ofast -Wall -Wextra -g -fPIC

#------------------------------------------------------------
#
# Build and Execute directory
#
#------------------------------------------------------------

LIB_PATH = $(EXDIR)/lib
SRC_PATH = $(EXDIR)/src
OBJ_PATH = ${EXDIR}/obj
RES_PATH = ${EXDIR}/res
PLO_PATH = ${EXDIR}/plot

#------------------------------------------------------------
#
# make all : to compile all.
# make clean : delete the results files
# make clear : delete obj files, results files, binary file
#
#------------------------------------------------------------


CPP_EX = libUMFLP.so

all: $(OBJ_PATH)/Box.o $(OBJ_PATH)/Data.o $(OBJ_PATH)/Dualoc.o $(OBJ_PATH)/Functions.o $(OBJ_PATH)/BiMiUFLP.o
	@ echo ">> Creating library"
	@ $(CCC) -shared -o ../$(CPP_EX) $(OBJ_PATH)/Box.o $(OBJ_PATH)/Data.o $(OBJ_PATH)/Dualoc.o $(OBJ_PATH)/Functions.o $(OBJ_PATH)/BiMiUFLP.o $(CCLNFLAGS)

$(OBJ_PATH)/Box.o : $(SRC_PATH)/Box.cpp
	@ $(CCC) -c $(CCOPT) $(SRC_PATH)/Box.cpp -o $(OBJ_PATH)/Box.o 
$(OBJ_PATH)/Data.o : $(SRC_PATH)/Data.cpp
	@ $(CCC) -c $(CCOPT) $(SRC_PATH)/Data.cpp -o $(OBJ_PATH)/Data.o
$(OBJ_PATH)/Dualoc.o : $(SRC_PATH)/Dualoc.cpp
	@ $(CCC) -c $(CCOPT) $(SRC_PATH)/Dualoc.cpp -o $(OBJ_PATH)/Dualoc.o
$(OBJ_PATH)/Functions.o : $(SRC_PATH)/Functions.cpp
	@ $(CCC) -c $(CCOPT) $(SRC_PATH)/Functions.cpp -o $(OBJ_PATH)/Functions.o
$(OBJ_PATH)/BiMiUFLP.o : $(SRC_PATH)/BiMiUFLP.cpp
	@ $(CCC) -c $(CCOPT) $(SRC_PATH)/BiMiUFLP.cpp -o $(OBJ_PATH)/BiMiUFLP.o


dir : ${RES_PATH} ${OBJ_PATH} ${BIN_PATH}

${RES_PATH}:
	@ mkdir -p $@

${OBJ_PATH}:
	@ mkdir -p $@

${BIN_PATH}:
	@ mkdir -p $@

clear :
	@ echo ">> Clear results files"
	@ rm -f ${RES_PATH}/*.out 

clean : clear
	@ echo ">> Clean files and folders"
	@ /bin/rm -f ${PLO_PATH}/*.eps
	@ /bin/rm -rf *.o *~ $(OBJ_PATH)/*.o
	@ /bin/rm -rf ${SRC_PATH}/*~
	@ /bin/rm -rf $(BIN_PATH)/$(CPP_EX)

#======================== END OF MakeFile =========================
