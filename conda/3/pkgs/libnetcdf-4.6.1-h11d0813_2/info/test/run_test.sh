nc-config --has-dap      | grep -q yes
nc-config --has-dap2     | grep -q yes
nc-config --has-dap4     | grep -q yes
nc-config --has-nc2      | grep -q yes
nc-config --has-nc4      | grep -q yes
nc-config --has-hdf5     | grep -q yes
nc-config --has-hdf4     | grep -q yes
nc-config --has-logging  | grep -q yes
nc-config --has-cdf5     | grep -q yes

# C++ and Fortran are now separate packages (netcdf-cxx4 and netcdf-fortran)
# nc-config --has-c++      | grep -q no
# nc-config --has-c++4     | grep -q no
# nc-config --has-fortran  | grep -q no

# Parallel is the one we would like to have.
# nc-config --has-parallel | grep -q no

# Not sure if people still uses pnetcdf.
# nc-config --has-pnetcdf  | grep -q no

# We cannot package szip due to its license
# nc-config --has-szlib    | grep -q no

set -ex



test -f ${PREFIX}/lib/libnetcdf.a
test -f ${PREFIX}/lib/libnetcdf${SHLIB_EXT}
nc-config --all
ncdump -h "http://geoport-dev.whoi.edu/thredds/dodsC/estofs/atlantic"
ncdump -h "https://data.nodc.noaa.gov/thredds/dodsC/ioos/sccoos/scripps_pier/scripps_pier-2016.nc"
ncdump -h "http://oos.soest.hawaii.edu/thredds/dodsC/hioos/model/atm/ncep_pac/NCEP_Pacific_Atmospheric_Model_best.ncd"
ncdump -h "http://oos.soest.hawaii.edu/thredds/dodsC/usgs_dem_10m_tinian"
ncdump -h "https://www.ncei.noaa.gov/thredds/dodsC/namanl/201609/20160929/namanl_218_20160929_1800_006.grb"
exit 0
