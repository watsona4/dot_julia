GENCCODE_ASSEMBLY_TYPE=-a gcc
SO=so
SOBJ=so
A=a
LIBPREFIX=lib
LIB_EXT_ORDER=.64.2
COMPILE=/home/conda/feedstock_root/build_artifacts/icu_1566795101908/_build_env/bin/x86_64-conda_cos6-linux-gnu-cc -DNDEBUG -D_FORTIFY_SOURCE=2 -O2 -I/opt/anaconda1anaconda2anaconda3/include -D_REENTRANT  -DU_HAVE_ELF_H=1 -DU_HAVE_STRTOD_L=1 -DU_HAVE_XLOCALE_H=1  -DU_ATTRIBUTE_DEPRECATED= -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -I/opt/anaconda1anaconda2anaconda3/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/icu_1566795101908/work=/usr/local/src/conda/icu-64.2 -fdebug-prefix-map=/opt/anaconda1anaconda2anaconda3=/usr/local/src/conda-prefix -std=c11 -Wall -pedantic -Wshadow -Wpointer-arith -Wmissing-prototypes -Wwrite-strings   -c
LIBFLAGS=-I/opt/anaconda1anaconda2anaconda3/include -DPIC -fPIC
GENLIB=/home/conda/feedstock_root/build_artifacts/icu_1566795101908/_build_env/bin/x86_64-conda_cos6-linux-gnu-cc -march=nocona -mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -I/opt/anaconda1anaconda2anaconda3/include -fdebug-prefix-map=/home/conda/feedstock_root/build_artifacts/icu_1566795101908/work=/usr/local/src/conda/icu-64.2 -fdebug-prefix-map=/opt/anaconda1anaconda2anaconda3=/usr/local/src/conda-prefix -std=c11 -Wall -pedantic -Wshadow -Wpointer-arith -Wmissing-prototypes -Wwrite-strings   -Wl,-O2 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,--disable-new-dtags -Wl,--gc-sections -Wl,-rpath,/opt/anaconda1anaconda2anaconda3/lib -Wl,-rpath-link,/opt/anaconda1anaconda2anaconda3/lib -L/opt/anaconda1anaconda2anaconda3/lib  -shared -Wl,-Bsymbolic
LDICUDTFLAGS=-nodefaultlibs -nostdlib
LD_SONAME=-Wl,-soname -Wl,
RPATH_FLAGS=
BIR_LDFLAGS=-Wl,-Bsymbolic
AR=/home/conda/feedstock_root/build_artifacts/icu_1566795101908/_build_env/bin/x86_64-conda_cos6-linux-gnu-ar
ARFLAGS=r
RANLIB=/home/conda/feedstock_root/build_artifacts/icu_1566795101908/_build_env/bin/x86_64-conda_cos6-linux-gnu-ranlib
INSTALL_CMD=/usr/bin/install -c
