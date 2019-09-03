#!/bin/bash

cd nss

if [[ ${HOST} =~ .*darwin.* ]]; then
    USE_GCC=0
    MACOS_SDK_DIR="${CONDA_BUILD_SYSROOT}"
elif [[ ${HOST} =~ .*linux.* ]]; then
    USE_GCC=1
fi

make   -j1 BUILD_OPT=1 \
    NSPR_INCLUDE_DIR=$PREFIX/include/nspr \
    NSPR_LIB_DIR=$PREFIX/lib \
    PREFIX=$PREFIX \
    SQLITE_INCLUDE_DIR=$PREFIX/include \
    SQLITE_LIB_DIR=$PREFIX/lib \
    NSS_INCLUDE_DIR=$PREFIX/include \
    NSS_LIB_DIR=$PREFIX/lib \
    NS_INCLUDE_DIR=$PREFIX/include \
    NS_LIB_DIR=$PREFIX/lib \
    NSPR_PREFIX=$PREFIX \
    USE_SYSTEM_ZLIB=1 \
    ZLIB_LIBS=-lz \
    NSS_ENABLE_WERROR=0 \
    USE_64=1 \
    NSS_USE_SYSTEM_SQLITE=1 \
    NSDISTMODE=copy \
    NO_MDUPDATE=1 \
    NSS_DISABLE_GTESTS=1 \
    NSS_GYP_PREFIX=$PREFIX \
    NS_USE_GCC=$USE_GCC \
    MACOS_SDK_DIR=$MACOS_SDK_DIR \
    all latest

cd ../dist

FOLDER=$(<latest)
install -v -m755 ${FOLDER}/lib/*${SHLIB_EXT}  "${PREFIX}/lib"
install -v -m644 ${FOLDER}/lib/{*.chk,libcrmf.a} "${PREFIX}/lib"

install -v -m755 -d "${PREFIX}/include/nss"
cp -v -RL {public,private}/nss/* "${PREFIX}/include/nss"
chmod -v 644 ${PREFIX}/include/nss/*
install -v -m755 ${FOLDER}/bin/{certutil,nss-config,pk12util} "${PREFIX}/bin"

install -v -m644 ${FOLDER}/lib/pkgconfig/nss.pc  "${PREFIX}/lib/pkgconfig"

