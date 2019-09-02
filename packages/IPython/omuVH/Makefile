precompile: tmp/precompile

tmp/precompile: tmp/compiles.csv
	rm -rf $@
	scripts/dump_precompile.jl $< $@

tmp/compiles.csv:
	rm -f $@
	scripts/snoop_repl.jl $@
