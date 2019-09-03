#!/usr/bin/env julia

# RainFARM 
# Stochastic downscaling following 
# D'Onofrio et al. 2014, J of Hydrometeorology 15 , 830-843 and
# Rebora et. al 2006, JHM 7, 724 
# Includes orographic corrections

# Implementation in Julia language

# Copyright (c) 2016, Jost von Hardenberg - ISAC-CNR, Italy

using RainFARM
using ArgParse
using Compat, Compat.Printf

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--slope", "-s"
            help = "spatial spectral slope"
            arg_type = Float64
            default = 0.0
        "--nens", "-e"
            help = "number of ensemble members"
            arg_type = Int
            default = 1
        "--nf", "-n"
            help = "Subdivisions for downscaling"
            arg_type = Int
            default = 2
        "--region", "-r", "-R"
            help = "Indices for region to cutout imin/imax/jmin/jmax"
            arg_type = AbstractString
            default = "0/0/0/0"
        "--weights", "-w", "--weight"
            help = "Weights file"
            arg_type = AbstractString
            default = "" 
        "--outfile", "-o", "--out"
            help = "Output filename radix"
            arg_type = AbstractString
            default = "rainfarm" 
        "infile"
            help = "The input file to downscale"
            arg_type = AbstractString
            required = true
        "--varname", "-v"
            help = "Input variable name"
            arg_type = AbstractString
            default = ""
        "--global", "-g"              
            action = :store_true
            help = "conserve precipitation over full domain"
        "--conv", "-c"              
            action = :store_true
            help = "conserve precipitation using convolution"
        "--kmin", "-k"
            help = "Minimum wavenumber"
            arg_type = Int
            default = 1
    end

    s.description="RainFARM downscaling: creates NENS realizations, downscaling INFILE, increasing spatial resolution by a factor NF. The slope is computed automatically unless specified. \ua0 Weights can be created with rfweights.jl"

    return parse_args(s)
end

args = parse_commandline()
nf=args["nf"]
filenc=args["infile"]
weightsnc=args["weights"]
nens=args["nens"]
varname=args["varname"]
fnbase=args["outfile"]
sx=args["slope"]
fglob=args["global"]
fsmooth=args["conv"]
region=args["region"]
kmin=args["kmin"]

imin=parse(Int,split(region,"/")[1])
imax=parse(Int,split(region,"/")[2])
jmin=parse(Int,split(region,"/")[3])
jmax=parse(Int,split(region,"/")[4])

println("Downscaling ",filenc)

(pr,lon_mat,lat_mat,varname)=read_netcdf2d(filenc, varname);

# Creo la griglia fine
(lon_f, lat_f)=lon_lat_fine(lon_mat, lat_mat,nf);

ns=size(lon_f)
println("Output size: ",ns)

if(imin==0)
   imin=1
   jmin=1
   if(length(ns)==2)
     imax=ns[1]; jmax=ns[2];
   else
     imax=ns[1]; (jmax,)=size(lat_f);
   end
else
   println("Cutout region: ",imin,"/",imax,"/",jmin,"/",jmax)
end

if(length(ns)==2)
  lon_fr=lon_f[imin:imax,jmin:jmax]
  lat_fr=lat_f[imin:imax,jmin:jmax]
else
  lon_fr=lon_f[imin:imax]
  lat_fr=lat_f[jmin:jmax]
end

if(sx==0.) 
# Calcolo fft3d e slope
(fxp,ftp)=fft3d(pr);
sx=fitslopex(fxp,kmin=kmin);
println("Computed spatial spectral slope: ",sx)
else
println("Fixed spatial spectral slope: ",sx)
end

#if(varnc=="")
#   varnc="pr"
#end

if(fglob) 
  println("Conserving only global precipitation")
end

if(weightsnc!="")
    println("Using weights file ",weightsnc)
    (ww,lon_mat2,lat_mat2)=read_netcdf2d(weightsnc, "");
else
    ww=1.
end
# Downscaling
for iens=1:nens
@compat  @printf("Realization %d\n",iens)
  @time rd=rainfarm(pr, sx, nf, ww,fglob=fglob,fsmooth=fsmooth,verbose=true);
@compat  fname=@sprintf("%s_%04d.nc",fnbase,iens);
  write_netcdf2d(fname,rd[imin:imax,jmin:jmax,:],lon_fr,lat_fr,varname,filenc)
end
