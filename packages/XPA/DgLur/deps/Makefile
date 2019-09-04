#
# Define the following environment variables if the default definitions is not
# suitable for your installation.
#
#     XPA_DEFS specifies the C-preprocessor flags for finding headers "xpa.h"
#              and "prsetup.h".  For instance: XPA_DEFS=-I/usr/local/include
#
#     XPA_LIBS specifies the linker flags for linking with the XPA dynamic
#              library. For instance: XPA_LIBS="-L/usr/local/lib -lxpa"
#
#     XPA_DLL  specifies the path to the XPA dynamic library.   This may be
#              defined to force using another dynamic library than the one
#              imposed by the system.  Note that, this variable has precedence
#              over XPA_LIBS.   For instance: XPA_DLL=/usr/local/libxpa.so.1
#

srcdir = .

all: deps.jl

clean:
	rm -f *~ core gencode

distclean: clean
	rm -f deps.jl

gencode: ${srcdir}/gencode.c Makefile
	if test "$(XPA_DLL)" != ""; then \
	    defs="-DXPA_DLL=\"\\\"$(XPA_DLL)\\\"\""; \
	    libs=""; \
	elif test "$(XPA_LIBS)" != ""; then \
	    defs="-UXPA_DLL"; \
	    libs="$(XPA_LIBS)"; \
	else \
	    defs="-UXPA_DLL"; \
	    libs="-lxpa"; \
	fi; \
	$(CC) $(CPPFLAGS) $(XPA_DEFS) $$defs $(CFLAGS) -o "$@" "$<" $$libs $(LDFLAGS)

deps.jl: gencode ${srcdir}/getdll.sh Makefile
	rm -f "$@"
	./gencode >"$@"
	if ! grep >/dev/null '^ *const libxpa *=' <"$@"; then \
	    ${srcdir}/getdll.sh xpa gencode | \
	        sed -e 's/\(.*\)/const libxpa = "\1"/' >>"$@"; \
	fi
	chmod 444 "$@"

.PHONY: all clean distclean
