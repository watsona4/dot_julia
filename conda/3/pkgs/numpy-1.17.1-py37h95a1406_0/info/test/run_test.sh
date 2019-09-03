

set -ex



f2py -h
pytest --timeout=300 -v --pyargs numpy
exit 0
