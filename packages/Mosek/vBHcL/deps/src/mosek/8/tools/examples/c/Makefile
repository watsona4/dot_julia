#
# Compile and run MOSEK examples
#

CC=gcc
IPATHS=-I../../platform/linux64x86/h
LPATH=-L../../platform/linux64x86/bin -Wl,-rpath-link,../../platform/linux64x86/bin '-Wl,-rpath=$$ORIGIN/../../platform/linux64x86/bin'
LIBS=-lmosek64


%.o: %.c
	$(CC) -c -g $(IPATHS) -o $@ $<

blas_lapack: blas_lapack.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
callback: callback.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
case_portfolio_1: case_portfolio_1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
case_portfolio_2: case_portfolio_2.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
case_portfolio_3: case_portfolio_3.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
cqo1: cqo1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
errorreporting: errorreporting.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
feasrepairex1: feasrepairex1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
lo1: lo1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
lo2: lo2.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
milo1: milo1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
mioinitsol: mioinitsol.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
opt_server_async: opt_server_async.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
opt_server_sync: opt_server_sync.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
parameters: parameters.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
production: production.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
qcqo1: qcqo1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
qo1: qo1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
response: response.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
sdo1: sdo1.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
sensitivity: sensitivity.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
simple: simple.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
solutionquality: solutionquality.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
solvebasis: solvebasis.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
solvelinear: solvelinear.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
sparsecholesky: sparsecholesky.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
unicode: unicode.o
	$(CC) -g $(LPATH) -o $@ $< $(LIBS)
tstscopt: tstscopt.o scopt-ext.o
	$(CC) -g $(LPATH) -o $@ $^ $(LIBS) -lm
tstexpopt: tstexpopt.o scopt-ext.o expopt.o dgopt.o
	$(CC) -g $(LPATH) -o $@ $^ $(LIBS) -lm

.PHONY: clean test all

all: blas_lapack callback case_portfolio_1 case_portfolio_2 case_portfolio_3 cqo1 errorreporting feasrepairex1 lo1 lo2 milo1 mioinitsol opt_server_async opt_server_sync parameters production qcqo1 qo1 response sdo1 sensitivity simple solutionquality solvebasis solvelinear sparsecholesky unicode tstscopt tstexpopt

.DEFAULT: all

clean:
	rm -f blas_lapack callback case_portfolio_1 case_portfolio_2 case_portfolio_3 cqo1 errorreporting feasrepairex1 lo1 lo2 milo1 mioinitsol opt_server_async opt_server_sync parameters production qcqo1 qo1 response sdo1 sensitivity simple solutionquality solvebasis solvelinear sparsecholesky unicode tstexpopt tstscopt
	rm -f blas_lapack.o callback.o case_portfolio_1.o case_portfolio_2.o case_portfolio_3.o cqo1.o errorreporting.o feasrepairex1.o lo1.o lo2.o milo1.o mioinitsol.o opt_server_async.o opt_server_sync.o parameters.o production.o qcqo1.o qo1.o response.o sdo1.o sensitivity.o simple.o solutionquality.o solvebasis.o solvelinear.o sparsecholesky.o unicode.o tstscopt.o tstexpopt.o scopt-ext.o dgopt.o expopt.o

test: blas_lapack callback case_portfolio_1 case_portfolio_2 case_portfolio_3 cqo1 errorreporting feasrepairex1 lo1 lo2 milo1 mioinitsol opt_server_async opt_server_sync parameters production qcqo1 qo1 response sdo1 sensitivity simple solutionquality solvebasis solvelinear sparsecholesky unicode tstscopt tstexpopt
	./blas_lapack
	./callback
	./case_portfolio_1
	./case_portfolio_2
	./case_portfolio_3
	./cqo1
	./errorreporting
	./feasrepairex1
	./lo1
	./lo2
	./milo1
	./mioinitsol
	./opt_server_async
	./opt_server_sync
	./parameters
	./production
	./qcqo1
	./qo1
	./response
	./sdo1
	./sensitivity
	./simple
	./solutionquality
	./solvebasis
	./solvelinear
	./sparsecholesky
	./unicode
	./tstexpopt
	./tstscopt
