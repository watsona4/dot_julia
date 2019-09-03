#!/usr/bin/env julia

# Copyright (c) 2016, Jost von Hardenberg - ISAC-CNR, Italy

using RainFARM
using ArgParse
using Compat, Compat.Printf

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--nf", "-n"
            help = "Subdivisions for downscaling [default: 2]"
            arg_type = Int
            default = 2
        "--outfile", "-o", "--out"
            help = "Weights file"
            arg_type = AbstractString
            default = "grid.nc" 
        "infile"
            help = "The input file to downscale"
            arg_type = AbstractString
            required = true
        "varname"
            help = "Input variable name"
            arg_type = AbstractString
            required = true
    end
	s.description="Generates a sample file with a grid equal to the input file downscaled by a factor NF"
    return parse_args(s)
end

args = parse_commandline()
nf=args["nf"]
filenc=args["infile"]
outfile=args["outfile"]
varnc=args["varname"]

println("Reading file ",filenc)

(pr,lon_mat,lat_mat)=read_netcdf2d(filenc, varnc);

# Creo la griglia fine
nss=size(pr)
if (length(nss)>=3)
    pr=pr[:,:,1]
end
ns=nss[1];

(lon_f, lat_f)=lon_lat_fine(lon_mat, lat_mat,nf);

println("Output size: ",size(lon_f))

write_netcdf2d(outfile,reshape(pr,ns,ns,1),lon_f,lat_f,varnc,filenc)

