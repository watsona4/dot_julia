
#
# Compile and run MOSEK examples
#
examples.jar: TrafficNetworkModel.java alan.java baker.java breaksolver.java callback.java cqo1.java diet.java duality.java facility_location.java lo1.java lownerjohn_ellipsoid.java lpt.java milo1.java mioinitsol.java nearestcorr.java parameters.java portfolio.java primal_svm.java production.java qcqp_sdo_relaxation.java sdo1.java sospoly.java sudoku.java total_variation.java tsp.java
	javac -d . -classpath ../../../platform/linux64x86/bin/mosek.jar TrafficNetworkModel.java alan.java baker.java breaksolver.java callback.java cqo1.java diet.java duality.java facility_location.java lo1.java lownerjohn_ellipsoid.java lpt.java milo1.java mioinitsol.java nearestcorr.java parameters.java portfolio.java primal_svm.java production.java qcqp_sdo_relaxation.java sdo1.java sospoly.java sudoku.java total_variation.java tsp.java
	jar cf examples.jar com

clean:
	rm -rf com/

test: examples.jar
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.TrafficNetworkModel
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.alan
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.baker
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.breaksolver
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.callback
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.cqo1
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.diet
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.duality
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.facility_location
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.lo1
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.lownerjohn_ellipsoid
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.lpt
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.milo1
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.mioinitsol
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.nearestcorr
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.parameters
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.portfolio
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.primal_svm
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.production
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.qcqp_sdo_relaxation
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.sdo1
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.sospoly
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.sudoku
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.total_variation
	java -cp examples.jar:../../../platform/linux64x86/bin/mosek.jar com.mosek.fusion.examples.tsp
