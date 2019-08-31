SHELL = /bin/bash
CC = g++
CFLAGS = -c -fPIC -Wall -O2 -I $(LIB_PATH) -I $(DATA_PATH) -I $(STAT_PATH)
LDFLAGS = -Wall -O2 -I $(LIB_PATH) -I $(DATA_PATH) -I $(STAT_PATH) $(LIB_OBJ) $(DATA_OBJ) $(STAT_OBJ)


# library

LIB_PATH = lib
LIB = 	$(LIB_PATH)/math_misc.cpp \
	$(LIB_PATH)/point3D.cpp \
	$(LIB_PATH)/transit.cpp \
	$(LIB_PATH)/occultations.cpp \
	$(LIB_PATH)/c_interface.cpp 
LIB_OBJ = $(LIB:.cpp=.o)
LIB_NAME = libcorbits.so

# base

BASE_PATH = base
BASE_SRC = $(BASE_PATH)/corbits.cpp
BASE_OBJ = $(BASE_SRC:.cpp=.o)

# data

DATA_PATH = data
DATA_SRC = $(DATA_PATH)/koi_input.cpp
DATA_OBJ = $(DATA_SRC:.cpp=.o)

# stat

STAT_PATH = stat
STAT_SRC = $(STAT_PATH)/stat_dist.cpp
STAT_OBJ = $(STAT_SRC:.cpp=.o)

# examples

EXAMPLES = kepler-11 period-dist mhs-dist solar-system case-trans koi-table

KEP11_PATH = examples/kepler-11
KEP11_SRC = $(KEP11_PATH)/Kepler-11.cpp
KEP11_OBJ = $(KEP11_SRC:.cpp=.o)

KEP90_PATH = examples/kepler-90
KEP90_SRC = $(KEP90_PATH)/Kepler-90.cpp
KEP90_OBJ = $(KEP90_SRC:.cpp=.o)

PER_PATH = examples/period-dist
PER_SRC = $(PER_PATH)/period_dist.cpp
PER_OBJ = $(PER_SRC:.cpp=.o)

MHS_PATH = examples/mhs-dist
MHS_SRC = $(MHS_PATH)/mhs_dist.cpp
MHS_OBJ = $(MHS_SRC:.cpp=.o)

SOLSYS_PATH = examples/solar-system
SOLSYS_SRC = $(SOLSYS_PATH)/solsys.cpp
SOLSYS_OBJ = $(SOLSYS_SRC:.cpp=.o)

CASE_PATH = examples/case-trans
CASE_SRC = $(CASE_PATH)/case_trans.cpp
CASE_OBJ = $(CASE_SRC:.cpp=.o)

KOI_TABLE_PATH = examples/koi-table
KOI_TABLE_SRC = $(KOI_TABLE_PATH)/koi_table.cpp
KOI_TABLE_OBJ = $(KOI_TABLE_SRC:.cpp=.o)

# targets

all: lib base examples data

lib: $(LIB_OBJ) $(DATA_OBJ) $(STAT_OBJ)
	$(CC) -shared -o$(LIB_NAME) $(LIB_OBJ) $(DATA_OBJ) $(STAT_OBJ)

corbits: base

data: $(DATA_PATH)/koi-data-edit.txt

base: lib $(BASE_OBJ)
	$(CC) $(LDFLAGS) $(BASE_OBJ) -o $(BASE_PATH)/corbits

examples: $(EXAMPLES)

# Kepler-11

kepler-11: lib $(KEP11_OBJ)
	$(CC) $(LDFLAGS) $(KEP11_OBJ) -o $(KEP11_PATH)/$@

run-kepler-11: kepler-11
	cd $(KEP11_PATH) && ./kepler-11

# Kepler-90

kepler-90: lib $(KEP90_OBJ)
	$(CC) $(LDFLAGS) $(KEP90_OBJ) -o $(KEP90_PATH)/$@

run-kepler-90: kepler-90
	cd $(KEP90_PATH) && ./kepler-90

# Period ratio distribution

period-dist: lib $(DATA_OBJ) $(PER_OBJ)
	$(CC) $(LDFLAGS) $(PER_OBJ) -o $(PER_PATH)/$@

run-period-dist: period-dist $(DATA_PATH)/koi-data-edit.txt
	cd $(PER_PATH) && ./period-dist

period-hist: $(DATA_PATH)/per_adj_hist_py.txt \
	$(DATA_PATH)/per_all_hist_py.txt \
	$(DATA_PATH)/per_snr_hist_py.txt \
	$(DATA_PATH)/per_adj_stat.txt \
	$(DATA_PATH)/per_all_stat.txt \
	$(DATA_PATH)/per_snr_stat.txt
	cd $(PER_PATH) && python make_per_hist.py #2> /dev/null

period-kde: $(DATA_PATH)/per_adj_hist_py.txt \
	$(DATA_PATH)/per_all_hist_py.txt \
	$(DATA_PATH)/per_snr_hist_py.txt \
	$(DATA_PATH)/per_adj_stat.txt \
	$(DATA_PATH)/per_all_stat.txt \
	$(DATA_PATH)/per_snr_stat.txt
	cd $(PER_PATH) && python make_per_kde.py #2> /dev/null

# MHS distribution

mhs-dist: lib $(DATA_OBJ) $(MHS_OBJ)
	$(CC) $(LDFLAGS) $(MHS_OBJ) -o $(MHS_PATH)/$@

run-mhs-dist: mhs-dist $(DATA_PATH)/koi-data-edit.txt
	cd $(MHS_PATH) && ./mhs-dist

mhs-hist: $(DATA_PATH)/mhs_adj_hist_py.txt \
	$(DATA_PATH)/mhs_all_hist_py.txt \
	$(DATA_PATH)/mhs_snr_hist_py.txt \
	$(DATA_PATH)/mhs_all_stat.txt \
	$(DATA_PATH)/mhs_adj_stat.txt \
	$(DATA_PATH)/mhs_snr_stat.txt
	cd $(MHS_PATH) && python make_mhs_hist.py #2> /dev/null

mhs-kde: $(DATA_PATH)/mhs_adj_hist_py.txt \
	$(DATA_PATH)/mhs_all_hist_py.txt \
	$(DATA_PATH)/mhs_snr_hist_py.txt \
	$(DATA_PATH)/mhs_all_stat.txt \
	$(DATA_PATH)/mhs_adj_stat.txt \
	$(DATA_PATH)/mhs_snr_stat.txt
	cd $(MHS_PATH) && python make_mhs_kde.py #2> /dev/null

# Solar System

solar-system: lib $(SOLSYS_OBJ)
	$(CC) $(LDFLAGS) $(SOLSYS_OBJ) -o $(SOLSYS_PATH)/$@

run-solar-system: solar-system
	cd $(SOLSYS_PATH) && ./solar-system 2> /dev/null

# Transit-region case transition

case-trans: lib $(CASE_OBJ)
	$(CC) $(LDFLAGS) $(CASE_OBJ) -o $(CASE_PATH)/$@

run-case-trans: case-trans
	cd $(CASE_PATH) && ./case-trans

# Table of KOI probabilities

koi-table: lib $(KOI_TABLE_OBJ)
	$(CC) $(LDFLAGS) $(KOI_TABLE_OBJ) -o $(KOI_TABLE_PATH)/$@

run-koi-table: koi-table
	cd $(KOI_TABLE_PATH) && ./koi-table


# ref: http://mrbook.org/tutorials/make
.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

# remove object files and executables
clean:
	rm -f $(LIB_PATH)/*.o \
	$(BASE_PATH)/*.o \
	$(BASE_PATH)/corbits \
	$(DATA_PATH)/*.o \
	$(KEP11_PATH)/*.o \
	$(KEP11_PATH)/kepler-11 \
	$(PER_PATH)/*.o \
	$(PER_PATH)/period-dist \
	$(MHS_PATH)/*.o \
	$(MHS_PATH)/mhs-dist \
	$(SOLSYS_PATH)/*.o \
	$(SOLSYS_PATH)/solar-system \
	$(STAT_PATH)/*.o \
	$(TEST_PATH)/*.o \
	$(TEST_PATH)/unit-test

# remove all output files
clean-all: clean
	rm -f $(DATA_PATH)/*.txt \
	$(DATA_PATH)/*.pdf

# files

$(DATA_PATH)/koi-data-edit.txt:
	$(DATA_PATH)/grab.sh

$(DATA_PATH)/per_adj_hist_py.txt: run-period-dist

$(DATA_PATH)/per_all_hist_py.txt: run-period-dist

$(DATA_PATH)/per_snr_hist_py.txt: run-period-dist

$(DATA_PATH)/per_adj_stat%txt $(DATA_PATH)/per_all_stat%txt $(DATA_PATH)/per_snr_stat%txt:
	cd $(PER_PATH) && Rscript per-fit.R

$(DATA_PATH)/mhs_adj_hist_py.txt: run-mhs-dist

$(DATA_PATH)/mhs_all_hist_py.txt: run-mhs-dist

$(DATA_PATH)/mhs_snr_hist_py.txt: run-mhs-dist

$(DATA_PATH)/mhs_adj_stat%txt $(DATA_PATH)/mhs_all_stat%txt $(DATA_PATH)/mhs_snr_stat%txt:
	cd $(MHS_PATH) && Rscript mhs-fit.R
