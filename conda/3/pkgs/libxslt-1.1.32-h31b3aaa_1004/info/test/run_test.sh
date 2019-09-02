

set -ex



xsltproc --version
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
