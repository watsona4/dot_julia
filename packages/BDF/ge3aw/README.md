[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/sam81/BDF.jl.svg?branch=master)](https://travis-ci.org/sam81/BDF.jl)
[![Coverage Status](https://coveralls.io/repos/github/sam81/BDF.jl/badge.svg?branch=master)](https://coveralls.io/github/sam81/BDF.jl?branch=master)

`BDF.jl` is a Julia module to read/write BIOSEMI 24-bit [BDF](http://www.biosemi.com/faq/file_format.htm) files (used for storing electroencephalographic recordings)

Usage:

    bdfHeader = readBDFHeader("res1.bdf") #read the bdf header
    sampRate = bdfHeader["sampRate"][1] #get the sampling rate
    #read the data, the event table, the trigger channel and the status channel
    dats, evtTab, trigs, statusChan = readBDF("res1.bdf")

Documentation is available here:

http://samcarcagno.altervista.org/BDF/index.html
