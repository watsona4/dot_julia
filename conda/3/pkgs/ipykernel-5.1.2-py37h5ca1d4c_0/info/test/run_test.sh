

set -ex



jupyter kernelspec list
pytest --pyargs ipykernel
exit 0
