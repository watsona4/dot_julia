

set -ex



xmllint test.xml
conda inspect linkages -p $PREFIX libxml2
exit 0
