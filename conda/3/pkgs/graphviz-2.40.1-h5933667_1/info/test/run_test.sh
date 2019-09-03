#!/bin/bash

dot -Tpng -o sample.png sample.dot
dot -Tpdf -o sample.pdf sample.dot
dot -Tsvg -o sample.svg sample.dot


set -ex



dot -V
neato -?
conda inspect linkages $PKG_NAME
exit 0
