# EchogramColorSchemes

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->

[![Build Status](https://travis-ci.org/EchoJulia/EchogramColorSchemes.jl.svg?branch=master)](https://travis-ci.org/EchoJulia/EchogramColorSchemes.jl)

[![Coverage Status](https://coveralls.io/repos/EchoJulia/EchogramColorSchemes.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/EchoJulia/EchogramColorSchemes.jl?branch=master)

[![codecov.io](http://codecov.io/github/EchoJulia/EchogramColorSchemes.jl/coverage.svg?branch=master)](http://codecov.io/github/EchoJulia/EchogramColorSchemes.jl?branch=master)

This trivial package contains colour schemes that are widely used in
fisheries acoustics.


	using EchogramColorSchemes
	
	EK80.colors
	EK500.colors
	

When using any colour scheme with an Echogram, it is usually desirable
to add a black or white default / background.

	c = addblack(EK80)
	
This works with other colour schemes too:

	using ColorSchemes
	c = addwhite(ColorSchemes.viridis)
