
#
# Compile and run MOSEK examples
#

CC=g++
IPATHS=-I../../../platform/linux64x86/h -I../../../platform/linux64x86/include
LPATHS=-L../../../platform/linux64x86/bin -Wl,-rpath-link,../../../platform/linux64x86/bin '-Wl,-rpath=$$ORIGIN/../../../platform/linux64x86/bin'

fusion: 
	make install -C ../../../platform/linux64x86/src/fusion_cxx

TrafficNetworkModel: fusion TrafficNetworkModel.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o TrafficNetworkModel TrafficNetworkModel.cc -lfusion64 -lmosek64

alan: fusion alan.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o alan alan.cc -lfusion64 -lmosek64

baker: fusion baker.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o baker baker.cc -lfusion64 -lmosek64

breaksolver: fusion breaksolver.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o breaksolver breaksolver.cc -lfusion64 -lmosek64

callback: fusion callback.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o callback callback.cc -lfusion64 -lmosek64

cqo1: fusion cqo1.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o cqo1 cqo1.cc -lfusion64 -lmosek64

diet: fusion diet.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o diet diet.cc -lfusion64 -lmosek64

duality: fusion duality.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o duality duality.cc -lfusion64 -lmosek64

facility_location: fusion facility_location.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o facility_location facility_location.cc -lfusion64 -lmosek64

lo1: fusion lo1.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o lo1 lo1.cc -lfusion64 -lmosek64

lownerjohn_ellipsoid: fusion lownerjohn_ellipsoid.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o lownerjohn_ellipsoid lownerjohn_ellipsoid.cc -lfusion64 -lmosek64

lpt: fusion lpt.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o lpt lpt.cc -lfusion64 -lmosek64

milo1: fusion milo1.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o milo1 milo1.cc -lfusion64 -lmosek64

mioinitsol: fusion mioinitsol.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o mioinitsol mioinitsol.cc -lfusion64 -lmosek64

nearestcorr: fusion nearestcorr.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o nearestcorr nearestcorr.cc -lfusion64 -lmosek64

parameters: fusion parameters.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o parameters parameters.cc -lfusion64 -lmosek64

portfolio: fusion portfolio.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o portfolio portfolio.cc -lfusion64 -lmosek64

primal_svm: fusion primal_svm.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o primal_svm primal_svm.cc -lfusion64 -lmosek64

production: fusion production.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o production production.cc -lfusion64 -lmosek64

qcqp_sdo_relaxation: fusion qcqp_sdo_relaxation.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o qcqp_sdo_relaxation qcqp_sdo_relaxation.cc -lfusion64 -lmosek64

sdo1: fusion sdo1.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o sdo1 sdo1.cc -lfusion64 -lmosek64

sospoly: fusion sospoly.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o sospoly sospoly.cc -lfusion64 -lmosek64

sudoku: fusion sudoku.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o sudoku sudoku.cc -lfusion64 -lmosek64

total_variation: fusion total_variation.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o total_variation total_variation.cc -lfusion64 -lmosek64

tsp: fusion tsp.cc
	$(CC) -pthread -std=c++11 -g $(IPATHS) $(LPATHS) -o tsp tsp.cc -lfusion64 -lmosek64

all: fusion TrafficNetworkModel alan baker breaksolver callback cqo1 diet duality facility_location lo1 lownerjohn_ellipsoid lpt milo1 mioinitsol nearestcorr parameters portfolio primal_svm production qcqp_sdo_relaxation sdo1 sospoly sudoku total_variation tsp

clean:
	rm -f TrafficNetworkModel alan baker breaksolver callback cqo1 diet duality facility_location lo1 lownerjohn_ellipsoid lpt milo1 mioinitsol nearestcorr parameters portfolio primal_svm production qcqp_sdo_relaxation sdo1 sospoly sudoku total_variation tsp

	make clean -C ../../../platform/linux64x86/src/fusion_cxx

test: TrafficNetworkModel alan baker breaksolver callback cqo1 diet duality facility_location lo1 lownerjohn_ellipsoid lpt milo1 mioinitsol nearestcorr parameters portfolio primal_svm production qcqp_sdo_relaxation sdo1 sospoly sudoku total_variation tsp
	./TrafficNetworkModel
	./alan
	./baker
	./breaksolver
	./callback
	./cqo1
	./diet
	./duality
	./facility_location
	./lo1
	./lownerjohn_ellipsoid
	./lpt
	./milo1
	./mioinitsol
	./nearestcorr
	./parameters
	./portfolio
	./primal_svm
	./production
	./qcqp_sdo_relaxation
	./sdo1
	./sospoly
	./sudoku
	./total_variation
	./tsp
