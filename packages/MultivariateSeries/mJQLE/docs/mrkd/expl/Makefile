.SUFFIXES: .ipynb .md

MD := $(patsubst %.ipynb,%.md,$(wildcard *.ipynb))

.ipynb.md:
	jupiter nbconvert --to markdown $*.ipynb

all: $(MD)
