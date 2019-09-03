#!/usr/bin/env julia
# Copyright (c) 2016, Jost von Hardenberg - ISAC-CNR, Italy
using RainFARM
using ArgParse
using Compat, Compat.Printf

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--radius", "-r"
            help = "Smoothing radius (in grid units)"
            arg_type = Float64
            default = 0.
        "--lapse", "-l"
            help = "Lapse rate [K/km]"
            arg_type =  Float64
            default = 6.5 
        "--varname", "-v"
            help = "Input variable name (in orofile)"
            arg_type = AbstractString 
            default = "" 
        "--coord", "--box", "-b"
            help = "Coordinates of box in which to downscale [lon1 lon2 lat1 lat2]"
 	    nargs = 4
            arg_type =  Float64
	    default =  [ 7, 7.65, 45.35, 45.75 ]
        "--orocoarse", "-o"
            help = "Coarse orography of original data"
            arg_type = AbstractString
            default = ""
        "orofile"
            help = "The input file to use for orography"
            arg_type = AbstractString
            required = true
        "infile"
            help = "The file to downscale"
            arg_type = AbstractString
            required = true
        "outfile"
            help = "The output file name"
            arg_type = AbstractString
            required = true
    end

    s.description="Downscale temperature with a given lapse rate"
    s.version="0.1"
    s.add_version=true

    return parse_args(s)
end

args = parse_commandline()
lapse=abs(args["lapse"])
radius=args["radius"]
filein=args["infile"]
fileout=args["outfile"]
fileoro=args["orofile"]
fileorocoarse=args["orocoarse"]
varname=args["varname"]
coord=args["coord"]

lon1=coord[1]
lon2=coord[2]
lat1=coord[3]
lat2=coord[4]

println("Downscaling in box: ",coord[1],"/",coord[2],"/",coord[3],"/",coord[4])

(tin0,lonl0,latl0)=read_netcdf2d(filein,varname);
if(length(size(lonl0))>1)
dxl=max(lonl0[2,1]-lonl0[1,1],lonl0[1,2]-lonl0[1,1]);
else
dxl=lonl0[2]-lonl0[1];
end

println("dx=",dxl)
if(radius==0)
    radius=dxl/2
end

#Add buffer
lonl1=lon1-radius
lonl2=lon2+radius
latl1=lat1-radius
latl2=lat2+radius
println("box + buffer=",lonl1,"/",lonl2,"/",latl1,"/",latl2)

rr=round.(Int32,rand()*1000000)

run(`cdo -s sellonlatbox,$lonl1,$lonl2,$latl1,$latl2 $fileoro orocut$rr.nc`)
(oro,lonl2,latl2,oroname)=read_netcdf2d("orocut$rr.nc","");
if(length(size(lonl2))>1)
dxf=max(lonl2[2,1]-lonl2[1,1],lonl2[1,2]-lonl2[1,1]);
else
dxf=lonl2[2]-lonl2[1];
end

println("Remapping input data ...")
run(`cdo -s -b F32 remapnn,orocut$rr.nc $filein input_nn$rr.nc`)
(tin,lonl,latl,varname)=read_netcdf2d("input_nn$rr.nc",varname);
oro=float(oro); # convert to float
(nx,ny,nt)=size(tin)

nf2=div(radius,abs(dxf))
println("Smoothing radius = ",radius," = ",nf2, " pixel")

println("Preparing correction ...")
if(fileorocoarse=="")
   oros=smooth(oro,nf2)
else
   run(`cdo -s -b F32 remapnn,orocut$rr.nc $fileorocoarse orocut_coarse$rr.nc`)
   (oroc,lonl,latl,orocname)=read_netcdf2d("orocut_coarse$rr.nc","");
   oros=smooth(oroc,nf2)
   run(`rm orocut_coarse$rr.nc`)
end
#println("oro=",mean(oro)," oros=",mean(oros))
oro=-(oro-oros)*lapse/1000.

write_netcdf2d("orocorr_temp$rr.nc",oro,lonl,latl,oroname,"orocut$rr.nc")
run(`cdo -s sellonlatbox,$lon1,$lon2,$lat1,$lat2 orocorr_temp$rr.nc orocorr$rr.nc `)

println("Downscaling ...")
for i=1:nt
    println("t=",i)
    tins=smooth(tin[:,:,i],nf2)
    tin[:,:,i]=tins+oro
#println("tin=",mean(tin[:,:,i])," tins=",mean(tins))
end

write_netcdf2d("out_temp$rr.nc",tin,lonl,latl,varname,"input_nn$rr.nc")
run(`cdo -s sellonlatbox,$lon1,$lon2,$lat1,$lat2 out_temp$rr.nc $fileout `)
run(`rm orocut$rr.nc input_nn$rr.nc out_temp$rr.nc orocorr_temp$rr.nc orocorr$rr.nc`)



