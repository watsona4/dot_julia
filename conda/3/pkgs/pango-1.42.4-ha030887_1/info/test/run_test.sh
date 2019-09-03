

set -ex



pango-view --help
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
