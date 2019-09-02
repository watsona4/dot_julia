
#
# Compile and run MOSEK examples
#
examples.jar: blas_lapack.java callback.java case_portfolio_1.java case_portfolio_2.java case_portfolio_3.java cqo1.java feasrepairex1.java lo1.java lo2.java milo1.java mioinitsol.java opt_server_async.java opt_server_sync.java parameters.java production.java qcqo1.java qo1.java response.java scopt1.java sdo1.java sensitivity.java simple.java solutionquality.java solvebasis.java solvelinear.java
	javac -d . -classpath ../../platform/linux64x86/bin/mosek.jar blas_lapack.java callback.java case_portfolio_1.java case_portfolio_2.java case_portfolio_3.java cqo1.java feasrepairex1.java lo1.java lo2.java milo1.java mioinitsol.java opt_server_async.java opt_server_sync.java parameters.java production.java qcqo1.java qo1.java response.java scopt1.java sdo1.java sensitivity.java simple.java solutionquality.java solvebasis.java solvelinear.java
	jar cf examples.jar com

clean:
	rm -rf com/

test: examples.jar
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.blas_lapack
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.callback
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.case_portfolio_1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.case_portfolio_2
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.case_portfolio_3
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.cqo1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.feasrepairex1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.lo1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.lo2
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.milo1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.mioinitsol
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.opt_server_async
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.opt_server_sync
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.parameters
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.production
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.qcqo1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.qo1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.response
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.scopt1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.sdo1
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.sensitivity
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.simple
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.solutionquality
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.solvebasis
	java -cp examples.jar:../../platform/linux64x86/bin/mosek.jar com.mosek.example.solvelinear

