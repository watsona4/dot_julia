#!/bin/bash

# Deactivate external conda.
source deactivate

# Add and configure special conda directories and files.
export CONDARC="$PREFIX/.condarc"
export CONDA_ENVS_DIRS="$PREFIX/envs"
export CONDA_PKGS_DIRS="$PREFIX/pkgs"
touch "$CONDARC"
mkdir "$CONDA_ENVS_DIRS"
mkdir "$CONDA_PKGS_DIRS"

# Activate the built conda.
source $PREFIX/bin/activate $PREFIX

# Run conda tests.
source ./test_conda.sh

# Deactivate the built conda when done.
# Not necessary, but a good test.
source deactivate


set -ex



unset CONDA_SHLVL
eval "$(python -m conda shell.bash hook)"
conda activate base
export PYTHON_MAJOR_VERSION=$(python -c "import sys; print(sys.version_info[0])")
export TEST_PLATFORM=$(python -c "import sys; print('win' if sys.platform.startswith('win') else 'unix')")
export PYTHONHASHSEED=$(python -c "import random as r; print(r.randint(0,4294967296))") && echo "PYTHONHASHSEED=$PYTHONHASHSEED"
env | sort
conda info
conda create -y -p ./built-conda-test-env
conda activate ./built-conda-test-env
echo $CONDA_PREFIX
[ "$CONDA_PREFIX" = "$PWD/built-conda-test-env" ] || exit 1
conda deactivate
exit 0
