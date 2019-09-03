"""
    overwrite_netcdf2d(fname,var,varname) 

Overwrite variable `varname` with field `var` in netcdf file `fname` 
"""
function overwrite_netcdf2d(fname,var,varname) 
ncin= NetCDF.open(fname)
ncwrite(var,fname,varname)
ncclose(fname)
end


