# SimradEK60TestData

[![Build Status](https://travis-ci.org/EchoJulia/SimradEK60TestData.jl.svg?branch=master)](https://travis-ci.org/EchoJulia/SimradEK60TestData.jl)

Sample Simrad EK60 scientific echosounder data for testing and
demonstration purposes.

Get the name of a RAW file like this:

	using SimradEK60TestData
	filename = EK60_SAMPLE
	
A corresponding calibration file is also available

	cal = ECS_SAMPLE
	
The data directory also includes corresponding CSV data exported from
EchoView to allow comparison and testing.

## Acknowledgements
Our thanks to the officers, crew, and scientists onboard the RRS James
Clark Ross for their assistance in collecting the data.
