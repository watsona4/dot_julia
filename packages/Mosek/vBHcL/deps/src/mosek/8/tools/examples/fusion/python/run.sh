#!/bin/bash

#
# Run MOSEK Fusion examples
#

export PYTHONPATH=../../../platform/linux64x86/python/2

export LD_LIBRARY_PATH=$LIBRARY_PATH:../../../platform/linux64x86/bin/

python TrafficNetworkModel.py && \
python alan.py && \
python baker.py && \
python breaksolver.py && \
python callback.py && \
python cqo1.py && \
python diet.py && \
python duality.py && \
python facility_location.py && \
python lo1.py && \
python lownerjohn_ellipsoid.py && \
python lpt.py && \
python milo1.py && \
python mioinitsol.py && \
python nearestcorr.py && \
python parameters.py && \
python portfolio.py && \
python primal_svm.py && \
python production.py && \
python qcqp_sdo_relaxation.py && \
python sdo1.py && \
python sospoly.py && \
python sudoku.py && \
python total_variation.py && \
python tsp.py && \
echo OK
