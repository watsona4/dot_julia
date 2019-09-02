
#
# Compile and run MOSEK examples
#
CSC=mcs
blas_lapack.exe: blas_lapack.cs
	$(CSC) -debug -out:blas_lapack.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe blas_lapack.cs

callback.exe: callback.cs
	$(CSC) -debug -out:callback.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe callback.cs

case_portfolio_1.exe: case_portfolio_1.cs
	$(CSC) -debug -out:case_portfolio_1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe case_portfolio_1.cs

case_portfolio_2.exe: case_portfolio_2.cs
	$(CSC) -debug -out:case_portfolio_2.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe case_portfolio_2.cs

case_portfolio_3.exe: case_portfolio_3.cs
	$(CSC) -debug -out:case_portfolio_3.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe case_portfolio_3.cs

cqo1.exe: cqo1.cs
	$(CSC) -debug -out:cqo1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe cqo1.cs

feasrepairex1.exe: feasrepairex1.cs
	$(CSC) -debug -out:feasrepairex1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe feasrepairex1.cs

lo1.exe: lo1.cs
	$(CSC) -debug -out:lo1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe lo1.cs

lo2.exe: lo2.cs
	$(CSC) -debug -out:lo2.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe lo2.cs

milo1.exe: milo1.cs
	$(CSC) -debug -out:milo1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe milo1.cs

mioinitsol.exe: mioinitsol.cs
	$(CSC) -debug -out:mioinitsol.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe mioinitsol.cs

opt_server_async.exe: opt_server_async.cs
	$(CSC) -debug -out:opt_server_async.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe opt_server_async.cs

opt_server_sync.exe: opt_server_sync.cs
	$(CSC) -debug -out:opt_server_sync.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe opt_server_sync.cs

parameters.exe: parameters.cs
	$(CSC) -debug -out:parameters.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe parameters.cs

production.exe: production.cs
	$(CSC) -debug -out:production.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe production.cs

qcqo1.exe: qcqo1.cs
	$(CSC) -debug -out:qcqo1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe qcqo1.cs

qo1.exe: qo1.cs
	$(CSC) -debug -out:qo1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe qo1.cs

response.exe: response.cs
	$(CSC) -debug -out:response.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe response.cs

scopt1.exe: scopt1.cs
	$(CSC) -debug -out:scopt1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe scopt1.cs

sdo1.exe: sdo1.cs
	$(CSC) -debug -out:sdo1.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe sdo1.cs

sensitivity.exe: sensitivity.cs
	$(CSC) -debug -out:sensitivity.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe sensitivity.cs

simple.exe: simple.cs
	$(CSC) -debug -out:simple.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe simple.cs

solutionquality.exe: solutionquality.cs
	$(CSC) -debug -out:solutionquality.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe solutionquality.cs

solvebasis.exe: solvebasis.cs
	$(CSC) -debug -out:solvebasis.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe solvebasis.cs

solvelinear.exe: solvelinear.cs
	$(CSC) -debug -out:solvelinear.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe solvelinear.cs

sparsecholesky.exe: sparsecholesky.cs
	$(CSC) -debug -out:sparsecholesky.exe -r:../../platform/linux64x86/bin/mosekdotnet8_1.dll -target:exe sparsecholesky.cs

all: blas_lapack.exe callback.exe case_portfolio_1.exe case_portfolio_2.exe case_portfolio_3.exe cqo1.exe feasrepairex1.exe lo1.exe lo2.exe milo1.exe mioinitsol.exe opt_server_async.exe opt_server_sync.exe parameters.exe production.exe qcqo1.exe qo1.exe response.exe scopt1.exe sdo1.exe sensitivity.exe simple.exe solutionquality.exe solvebasis.exe solvelinear.exe sparsecholesky.exe

clean:
	rm -f blas_lapack.exe callback.exe case_portfolio_1.exe case_portfolio_2.exe case_portfolio_3.exe cqo1.exe feasrepairex1.exe lo1.exe lo2.exe milo1.exe mioinitsol.exe opt_server_async.exe opt_server_sync.exe parameters.exe production.exe qcqo1.exe qo1.exe response.exe scopt1.exe sdo1.exe sensitivity.exe simple.exe solutionquality.exe solvebasis.exe solvelinear.exe sparsecholesky.exe

test: blas_lapack.exe callback.exe case_portfolio_1.exe case_portfolio_2.exe case_portfolio_3.exe cqo1.exe feasrepairex1.exe lo1.exe lo2.exe milo1.exe mioinitsol.exe opt_server_async.exe opt_server_sync.exe parameters.exe production.exe qcqo1.exe qo1.exe response.exe scopt1.exe sdo1.exe sensitivity.exe simple.exe solutionquality.exe solvebasis.exe solvelinear.exe sparsecholesky.exe
	cp ../../platform/linux64x86/bin/mosekdotnet8_1.dll .
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono blas_lapack.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono callback.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono case_portfolio_1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono case_portfolio_2.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono case_portfolio_3.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono cqo1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono feasrepairex1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono lo1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono lo2.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono milo1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono mioinitsol.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono opt_server_async.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono opt_server_sync.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono parameters.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono production.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono qcqo1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono qo1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono response.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono scopt1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono sdo1.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono sensitivity.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono simple.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono solutionquality.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono solvebasis.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono solvelinear.exe
	LD_LIBRARY_PATH=../../platform/linux64x86/bin mono sparsecholesky.exe
