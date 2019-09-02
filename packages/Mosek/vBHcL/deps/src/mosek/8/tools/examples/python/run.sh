#!/bin/bash

#
# Run MOSEK examples
#

export PYTHONPATH=../../platform/linux64x86/python/2/

export LD_LIBRARY_PATH=$LIBRARY_PATH:../../platform/linux64x86/bin/

python blas_lapack.py && \
python callback.py && \
python case_portfolio_1.py && \
python case_portfolio_2.py && \
python case_portfolio_3.py && \
python cqo1.py && \
python feasrepairex1.py && \
python lo1.py && \
python lo2.py && \
python milo1.py && \
python mioinitsol.py && \
python opt_server_async.py && \
python opt_server_sync.py && \
python parameters.py && \
python production.py && \
python qcqo1.py && \
python qo1.py && \
python response.py && \
python scopt1.py && \
python sdo1.py && \
python sensitivity.py && \
python simple.py && \
python solutionquality.py && \
python solvebasis.py && \
python solvelinear.py && \

echo OK
