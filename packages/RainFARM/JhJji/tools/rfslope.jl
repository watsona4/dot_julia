#!/usr/bin/env julia
# Copyright (c) 2016, Jost von Hardenberg - ISAC-CNR, Italy

using RainFARM
using ArgParse
using Compat, Compat.Printf

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "infile"
            help = "The input file to downscale"
            arg_type = AbstractString
            required = true
        "--varname", "-v"
            help = "Input variable name"
            arg_type = AbstractString
            default = ""
        "--outfile", "-o", "--out"
            help = "Output filename for spectrum"
            arg_type = AbstractString
            default = ""
        "--kmin", "-k"
            help = "Minimum wavenumber"
            arg_type = Int
            default = 1
    end

    s.description="Estimation of spatial spectral slope for RainFARM downscaling"

    return parse_args(s)
end

args = parse_commandline()
filenc=args["infile"]
varnc=args["varname"]
outfile=args["outfile"]
kmin=args["kmin"]

#println("Estimating slope ",filenc)

(pr,lon_mat,lat_mat)=read_netcdf2d(filenc, varnc);
#println("Size var:", size(pr)," size lon: ",size(lon_mat)," size lat: ", size(lat_mat))
# Calcolo fft3d e slope
(fxp,ftp,fs)=fft3d(pr);
sx=fitslopex(fxp,kmin=kmin);
#println("Computed spatial spectral slope: ",sx)
println(sx)

if outfile!="" 
   nk=length(fxp[:])
   k=collect(1:nk)
   aa=zeros(nk,2)
   aa[:,1]=k
   aa[:,2]=fxp
   fname="$outfile.s.dat"
   writedlm(fname,aa)
   fname="$outfile.t.dat"
   nw=length(ftp[:])
   w=collect(1:nw)
   aa=zeros(nw,2)
   aa[:,1]=w
   aa[:,2]=ftp
   writedlm(fname,aa)
   fname="$outfile.2d.dat"
   writedlm(fname,fs)
end
