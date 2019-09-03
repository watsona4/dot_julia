# Makefile originally lifted from Clang.jl
# Copyright (c) 2012-: Isaiah Norton and [contributors](https://github.com/ihnorton/Clang.jl/graphs/contributors)

ifeq (exists, $(shell [ -e Make.user ] && echo exists ))
include Make.user
endif

TARGETDIR=../usr/lib
TARGETBASENAME=pa_ringbuffer
OBJS = pa_ringbuffer.o

# check to see if the user passed in a HOST variable for cross-compiling
ifeq ($(HOST),)
	# Figure out OS and architecture
	OS=$(shell uname)
	ifneq ($(findstring MINGW,$(OS)),)
		OS=WINNT
	endif
else
	HOSTSUFFIX=_$(HOST)
	ifneq ($(findstring linux,$(HOST)),)
		OS=Linux
	else ifneq ($(findstring darwin,$(HOST)),)
		OS=Darwin
	else ifneq ($(findstring mingw,$(HOST)),)
		OS=WINNT
	endif
endif

CFLAGS =-Wall -Wno-strict-aliasing -fno-omit-frame-pointer
LDFLAGS =

# file extensions and platform-specific libs
ifeq ($(OS), WINNT)
	LIBS +=
	LDFLAGS += -shared
	INC +=
	SHACMD = sha256sum
	SHLIB_EXT = dll
else ifeq ($(OS), Darwin)
	LIBS +=
	INC +=
	LDFLAGS += -dynamiclib
	SHLIB_EXT = dylib
	SHACMD = shasum -a256
else
	CFLAGS += -fPIC
	LIBS +=
	INC +=
	LDFLAGS += -shared
	SHLIB_EXT = so
	SHACMD = sha256sum
endif

# LINUX_LIBS =-lrt
# LINUX_LDFLAGS =-rdynamic
# add the Homebrew.jl tree to the include dirs in case we used it for
# portaudio and libsndfile
# DARWIN_LDFLAGS =-L../../../Homebrew/deps/usr/lib
# DARWIN_INC =-I../../../Homebrew/deps/usr/include

TARGET=$(TARGETDIR)/$(TARGETBASENAME)$(HOSTSUFFIX).$(SHLIB_EXT)

.PHONY: clean cleantemp default

default: $(TARGET)

%.o: %.c Makefile
	$(CC) $< -c -o $@ $(INC) $(CFLAGS)

$(TARGETDIR):
	mkdir -p $@

$(TARGET): $(OBJS) $(TARGETDIR) Makefile
	$(CC) $(OBJS) $(LDFLAGS) -o $@ $(LIBS)

cleantemp:
	rm -f $(OBJS)

clean: cleantemp
	rm -f $(TARGETDIR)/$(TARGETBASENAME)*.so
	rm -f $(TARGETDIR)/$(TARGETBASENAME)*.dylib
	rm -f $(TARGETDIR)/$(TARGETBASENAME)*.dll
