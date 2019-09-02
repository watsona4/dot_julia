#!/bin/bash

mkdir -p ${PREFIX}/bin

if [ $(uname) == Linux ]; then
    mv bin/* ${PREFIX}/bin
fi


if [ $(uname) == Darwin ]; then
    pkgutil --expand pandoc.pkg pandoc
    cpio -i -I pandoc/pandoc.pkg/Payload
    cp usr/local/bin/* ${PREFIX}/bin/
fi
