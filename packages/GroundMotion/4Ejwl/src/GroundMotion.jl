## LICENSE
##   Copyright (c) 2018 GEOPHYSTECH LLC
##
##   Licensed under the Apache License, Version 2.0 (the "License");
##   you may not use this file except in compliance with the License.
##   You may obtain a copy of the License at
##
##       http://www.apache.org/licenses/LICENSE-2.0
##
##   Unless required by applicable law or agreed to in writing, software
##   distributed under the License is distributed on an "AS IS" BASIS,
##   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##   See the License for the specific language governing permissions and
##   limitations under the License.
##
## initial release by Andrey Stepnov, email: a.stepnov@geophsytech.ru
module GroundMotion
  # This source contains a module settings. Please find types and functions in nested source files (see include).
  # The distance() function is used, see https://github.com/JuliaGeo/Geodesy.jl for further read
  using 
    DelimitedFiles,
    Geodesy

  export
    # types
    Point_vs30,
    Point_pga_out,
    Earthquake,
    Params_as2008,
    Params_simidorikawa1999,
    Params_mf2013,
    # functions
    read_vs30_file,
    convert_to_point_vs30,
    read_vs30_dl_file,
    convert_to_float_array,
    gmpe_as2008,
    gmpe_simidorikawa1999,
    gmpe_mf2013
  
  # Types
  include("types.jl")
  # AS2008 GMPE modeling
  include("as2008.jl")
  # Si-Midorikawa 1999 GMPE modeling
  include("simidorikawa1999.jl")
  # Morikawa-Fujiwara 2013 GMPE modeling
  include("morikawafujiwara2013.jl")
  # read/write functions
  include("auxiliary.jl")
end

