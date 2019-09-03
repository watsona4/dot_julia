

set -ex



iconv --help
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
