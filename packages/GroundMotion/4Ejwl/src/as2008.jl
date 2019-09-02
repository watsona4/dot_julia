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

## initial release by Andrey Stepnov a.stepnov@geophsytech.ru

"""
**ON GRID**

`gmpe_as2008(eq::Earthquake,config_as2008::Params_as2008,grid::Array{Point_vs30};min_val::Number)` 

where `min_val=0` by default
  
Output will be 1-d `Array{Point_pga_out}` with points based on input grid with `pga > min_val` (pga, is Acceleration of gravity in percent (%g) rounded to ggg.gg)

**without grid**
  
`gmpe_as2008(eq::Earthquake,config::Params_as2008,VS30::Number=350,distance::Int64=1000)` 

where `VS30=30` [m/s^2], `distance=1000` [km] by default.
  
Output will be 1-d `Array{Float64}` with `1:distance` values of `pga` (that is Acceleration of gravity in percent (%g) rounded to ggg.gg)

**EXAMPLES:**
```  
gmpe_as2008(eq,config_as2008,grid) # for PGA on GRID
gmpe_as2008(eq,config_as2008) # for without input grid
```

**Model parameters**

Please, see `examples/as-2008.conf`
"""
## AS2008 PGA modeling ON GRID
function gmpe_as2008(eq::Earthquake,config::Params_as2008,grid::Array{Point_vs30};min_val::Number=0)
  vs30_row_num = length(grid[:,1])
  eq.moment_mag == 0 ? magnitude = eq.local_mag : magnitude = eq.moment_mag
  epicenter = LatLon(eq.lat, eq.lon)
  # define t6
  if magnitude < 5.5
    t6 = 1
  elseif magnitude <= 6.5 && magnitude >= 5.5
    t6 = (0.5 * (6.5 - magnitude) + 0.5)
  else 
    t6 = 0.5
  end
  # modeling
  if config.ground_motion_type == "PGA"
    output_data = Array{Point_pga_out}(undef,0)
    out_type = Point_pga_out
  end
  for i=1:vs30_row_num
    # rrup
    current_point = LatLon(grid[i].lat,grid[i].lon)
    r_rup = sqrt((distance(current_point,epicenter)/1000)^2 + eq.depth^2)
    # F1
    if magnitude <= config.c1
      f1 = config.a1 + config.a4 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 + 
        (config.a2 + config.a3 * (magnitude - config.c1)) *
        log(sqrt(r_rup^2 + config.c4^2))
    else 
      f1 = config.a1 + config.a5 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 +
        (config.a2 + config.a3 * (magnitude - config.c1)) *
            log(sqrt(r_rup^2 + config.c4^2))
    end
    # F8
    if r_rup < 100 
      f8 = 0;
    else 
      f8 = config.a18 * (r_rup - 100) * t6
    end
    # PGA1100
    pga1100 = exp((f1 + (config.a10 + config.b * config.n) *
               log(config.vs30_1100 / config.vlin) + f8))
    # F5
    if grid[i].vs30 < config.vlin
      f5 =  config.a10 * log(grid[i].vs30 / config.vlin) -
        config.b * log(pga1100 + config.c) + config.b * 
        log(pga1100 + config.c * (grid[i].vs30 / config.vlin)^config.n)
    elseif (grid[i].vs30 > config.vlin) && (grid[i].vs30 < config.v1)
      f5 = (config.a10 + config.b * config.n) *
        log(grid[i].vs30 / config.vlin)
    else
      f5 = (config.a10 + config.b * config.n) * 
        log(config.v1 / config.vlin)
    end
    if config.ground_motion_type == "PGA"
      motion = round((exp(f1 + f5 + f8) * 100),digits=2)
    end
    if motion >= min_val
      output_data = push!(output_data, out_type(grid[i].lon,grid[i].lat,motion))
    end
  end
  return output_data
end
## AS2008 PGA modeling for PLOTTING
function gmpe_as2008(eq::Earthquake,config::Params_as2008;VS30::Number=350,distance::Number=1000)
  eq.moment_mag == 0 ? magnitude = eq.local_mag : magnitude = eq.moment_mag
  # define t6
  if magnitude < 5.5
    t6 = 1
  elseif magnitude <= 6.5 && magnitude >= 5.5
    t6 = (0.5 * (6.5 - magnitude) + 0.5)
  else 
    t6 = 0.5
  end
  output_data = Array{Float64}(undef,0)
  for i=1:distance
    # rrup
    r_rup = sqrt((i)^2 + eq.depth^2)
    # F1
    if magnitude <= config.c1
      f1 = config.a1 + config.a4 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 + 
        (config.a2 + config.a3 * (magnitude - config.c1)) *
        log(sqrt(r_rup^2 + config.c4^2))
    else 
      f1 = config.a1 + config.a5 * (magnitude - config.c1) +
        config.a8 * (8.5 - magnitude)^2 +
        (config.a2 + config.a3 * (magnitude - config.c1)) *
            log(sqrt(r_rup^2 + config.c4^2))
    end
    # F8
    if r_rup < 100 
      f8 = 0;
    else 
      f8 = config.a18 * (r_rup - 100) * t6
    end
    # PGA1100
    pga1100 = exp((f1 + (config.a10 + config.b * config.n) *
               log(config.vs30_1100 / config.vlin) + f8))
    # F5
    if VS30 < config.vlin
      f5 =  config.a10 * log(VS30 / config.vlin) -
        config.b * log(pga1100 + config.c) + config.b * 
        log(pga1100 + config.c * (VS30 / config.vlin)^config.n)
    elseif (VS30 > config.vlin) && (VS30 < config.v1)
      f5 = (config.a10 + config.b * config.n) *
        log(VS30 / config.vlin)
    else
      f5 = (config.a10 + config.b * config.n) * 
        log(config.v1 / config.vlin)
    end
    if config.ground_motion_type == "PGA"
      motion = round((exp(f1 + f5 + f8) * 100),digits=2)
    end
    output_data = push!(output_data, motion)
  end
  return output_data
end

