
#
# Compile and run MOSEK examples
#
CSC=mcs
TrafficNetworkModel.exe: TrafficNetworkModel.cs
	$(CSC) -debug -out:TrafficNetworkModel.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe TrafficNetworkModel.cs

alan.exe: alan.cs
	$(CSC) -debug -out:alan.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe alan.cs

baker.exe: baker.cs
	$(CSC) -debug -out:baker.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe baker.cs

breaksolver.exe: breaksolver.cs
	$(CSC) -debug -out:breaksolver.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe breaksolver.cs

callback.exe: callback.cs
	$(CSC) -debug -out:callback.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe callback.cs

cqo1.exe: cqo1.cs
	$(CSC) -debug -out:cqo1.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe cqo1.cs

diet.exe: diet.cs
	$(CSC) -debug -out:diet.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe diet.cs

duality.exe: duality.cs
	$(CSC) -debug -out:duality.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe duality.cs

facility_location.exe: facility_location.cs
	$(CSC) -debug -out:facility_location.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe facility_location.cs

lo1.exe: lo1.cs
	$(CSC) -debug -out:lo1.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe lo1.cs

lownerjohn_ellipsoid.exe: lownerjohn_ellipsoid.cs
	$(CSC) -debug -out:lownerjohn_ellipsoid.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe lownerjohn_ellipsoid.cs

lpt.exe: lpt.cs
	$(CSC) -debug -out:lpt.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe lpt.cs

milo1.exe: milo1.cs
	$(CSC) -debug -out:milo1.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe milo1.cs

mioinitsol.exe: mioinitsol.cs
	$(CSC) -debug -out:mioinitsol.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe mioinitsol.cs

nearestcorr.exe: nearestcorr.cs
	$(CSC) -debug -out:nearestcorr.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe nearestcorr.cs

parameters.exe: parameters.cs
	$(CSC) -debug -out:parameters.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe parameters.cs

portfolio.exe: portfolio.cs
	$(CSC) -debug -out:portfolio.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe portfolio.cs

primal_svm.exe: primal_svm.cs
	$(CSC) -debug -out:primal_svm.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe primal_svm.cs

production.exe: production.cs
	$(CSC) -debug -out:production.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe production.cs

qcqp_sdo_relaxation.exe: qcqp_sdo_relaxation.cs
	$(CSC) -debug -out:qcqp_sdo_relaxation.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe qcqp_sdo_relaxation.cs

sdo1.exe: sdo1.cs
	$(CSC) -debug -out:sdo1.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe sdo1.cs

sospoly.exe: sospoly.cs
	$(CSC) -debug -out:sospoly.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe sospoly.cs

sudoku.exe: sudoku.cs
	$(CSC) -debug -out:sudoku.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe sudoku.cs

total_variation.exe: total_variation.cs
	$(CSC) -debug -out:total_variation.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe total_variation.cs

tsp.exe: tsp.cs
	$(CSC) -debug -out:tsp.exe -r:../../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe tsp.cs

all: TrafficNetworkModel.exe alan.exe baker.exe breaksolver.exe callback.exe cqo1.exe diet.exe duality.exe facility_location.exe lo1.exe lownerjohn_ellipsoid.exe lpt.exe milo1.exe mioinitsol.exe nearestcorr.exe parameters.exe portfolio.exe primal_svm.exe production.exe qcqp_sdo_relaxation.exe sdo1.exe sospoly.exe sudoku.exe total_variation.exe tsp.exe

clean:
	rm -f TrafficNetworkModel.exe alan.exe baker.exe breaksolver.exe callback.exe cqo1.exe diet.exe duality.exe facility_location.exe lo1.exe lownerjohn_ellipsoid.exe lpt.exe milo1.exe mioinitsol.exe nearestcorr.exe parameters.exe portfolio.exe primal_svm.exe production.exe qcqp_sdo_relaxation.exe sdo1.exe sospoly.exe sudoku.exe total_variation.exe tsp.exe

test: TrafficNetworkModel.exe alan.exe baker.exe breaksolver.exe callback.exe cqo1.exe diet.exe duality.exe facility_location.exe lo1.exe lownerjohn_ellipsoid.exe lpt.exe milo1.exe mioinitsol.exe nearestcorr.exe parameters.exe portfolio.exe primal_svm.exe production.exe qcqp_sdo_relaxation.exe sdo1.exe sospoly.exe sudoku.exe total_variation.exe tsp.exe
	cp ../../../platform/linux64x86/bin/mosekdotnet8_1.dll .
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono TrafficNetworkModel.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono alan.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono baker.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono breaksolver.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono callback.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono cqo1.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono diet.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono duality.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono facility_location.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono lo1.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono lownerjohn_ellipsoid.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono lpt.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono milo1.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono mioinitsol.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono nearestcorr.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono parameters.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono portfolio.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono primal_svm.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono production.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono qcqp_sdo_relaxation.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono sdo1.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono sospoly.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono sudoku.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono total_variation.exe
	LD_LIBRARY_PATH=../../../platform/linux64x86/bin mono tsp.exe
