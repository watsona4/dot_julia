default: test

.PHONY: test
test: test-julia-1.0 #test-julia-0.6 

.PHONY: test-julia-0.6
test-julia-0.6:
	julia-0.6 --color=yes -e 'Pkg.test("Granular")' \
		&& notify-send Granular.jl tests completed successfully on Julia 0.6 \
		|| notify-send Granular.jl failed on Julia 0.6

.PHONY: test-julia-0.7
test-julia-0.7:
	julia-0.7 --color=yes -e 'import Pkg; Pkg.test("Granular")' \
		&& notify-send Granular.jl tests completed successfully on Julia 0.7 \
		|| notify-send Granular.jl failed on Julia 0.7

.PHONY: test-julia-1.0
test-julia-1.0:
	julia-1.0 --color=yes -e 'import Pkg; Pkg.test("Granular")' \
		&& notify-send Granular.jl tests completed successfully on Julia 1.0 \
		|| notify-send Granular.jl failed on Julia 1.0

.PHONY: docs
docs:
	cd docs && julia --color=yes make.jl
	open docs/build/index.html

