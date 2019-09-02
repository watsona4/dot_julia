all: 
	cd mrkd/expl; make;
	cd ..; julia --color=yes docs/make.jl
deploy:
	cp -r docs/build/* /Volumes/Bernard.mourrain/software/MultivariateSeries
