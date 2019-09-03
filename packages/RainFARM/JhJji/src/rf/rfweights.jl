"""
    ww = rfweights(orofile, reffile, nf; weightsfn="", varname="", fsmooth=false)

Compute orographic weights from a fine-scale precipitation climatology file.

#Arguments
* `orofile`  : filename of input climatology
* `reffile`  : filename of reference file (for metadata, e.g. the file to downscale)
* `nf`       : refinement factor for spatial downscaling
* `weightsfn`: write weights to file weightsfn
* `varname`  : variable name in climatology
* `fsmooth`  : use smoothing instead of gp conservation

#Returns
* `ww`       : a weight matrix also saved to weightsfn

#Depends

This function uses external system calls using the "cdo" command (https://code.mpimet.mpg.de/projects/cdo/wiki/Cdo) which needs to be available on your system.
"""
function rfweights(orofile, reffile, nf; weightsfn="", varname="", fsmooth=false)

  # Create a reference gridrf.nc file (same grid as rainfarm output files)
  (pr,lon_mat,lat_mat)=read_netcdf2d(reffile, varname);
  # Create fine scale grid
  nss=size(pr)
  if (length(nss)>=3)
    pr=pr[:,:,1]
  end
  println(nss)
  ns=nss[1];
  (lon_f, lat_f)=lon_lat_fine(lon_mat, lat_mat,nf);

  rr=round.(Int,rand(1)*100000)[1]

  println("Output size: ",size(lon_f))
  if(varname=="")
    varname="pr"
    run(`cdo -s  setname,pr $reffile reffile_rr.nc`)
    reffile="reffile_rr.nc"
  end
  if(weightsfn=="")
    weightsfn="weights$rr.nc"
    fsavew=false
  else
    fsavew=true
  end

  # The rest is done in CDO
  println("Computing weights")
  write_netcdf2d("gridrf.nc",reshape(pr,ns,ns,1),lon_f,lat_f,varname,reffile)
  run(`cdo -s -b F32 timmean $orofile pr_orofile_$rr.nc`)
  run(`cdo -s -f nc copy gridrf.nc gridrf_2_$rr.nc`)
  run(`cdo -s -f nc remapbil,gridrf_2_$rr.nc pr_orofile_$rr.nc pr_remap_rr.nc`)
  if(fsmooth)
    (prr,lon,lat)=read_netcdf2d("pr_remap_rr.nc","")
    ww=prr./smoothconv(prr,ns);
    write_netcdf2d(weightsfn,ww,lon_f,lat_f,varname,reffile)
    run(`rm -f pr_remap_rr.nc pr_orofile_$rr.nc gridrf.nc gridrf_2_$rr.nc reffile_rr.nc`)
  else
    run(`cdo -s gridboxmean,$nf,$nf pr_remap_rr.nc pr_remap_gbm_$rr.nc`)
    run(`cdo -s remapnn,pr_remap_rr.nc pr_remap_gbm_$rr.nc pr_remap_nn_$rr.nc`)
    run(`cdo -s div pr_remap_rr.nc pr_remap_nn_$rr.nc $weightsfn`)
    run(`rm -f pr_remap_rr.nc pr_remap_gbm_$rr.nc pr_remap_nn_$rr.nc pr_orofile_$rr.nc gridrf.nc gridrf_2_$rr.nc reffile_rr.nc`)
  end
  (ww,lon_f,lat_f)=read_netcdf2d(weightsfn, "");
  if(!fsavew) 
     run(`rm -f $weightsfn`)
  end
  return ww
end
