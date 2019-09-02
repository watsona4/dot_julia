CC = gcc # C compiler
CFLAGS = -fPIC -O2# C flags
RM = rm -f  # rm command

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
	LDFLAGS = -shared# linking flags
	TARGET_LIB = libhilbert.so
endif
ifeq ($(UNAME),Darwin)
	LDFLAGS = -dynamiclib# linking flags
	TARGET_LIB = libhilbert.dylib
endif

SRCS = hilbert.c

hilbert:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGET_LIB) $(SRCS)
