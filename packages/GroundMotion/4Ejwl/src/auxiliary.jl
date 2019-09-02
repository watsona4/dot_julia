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

## initial release by Andrey Stepnov, email: a.stepnov@geophsytech.ru

## read VS30 file
function read_vs30_file(filename::String)
  A = readdlm(filename)
  vs30_row_num = length(A[:,1])
  B = Array{Point_vs30}(undef,0)
  for i=1:vs30_row_num
    B = push!(B,Point_vs30(A[i,1],A[i,2],A[i,3]))
  end
  return B
end
## convert Array{Float64,2} array to Array{GroundMotion.Point_vs30,1}
function convert_to_point_vs30(A::Array{Float64,2})
  vs30_row_num = length(A[:,1])
  B = Array{Point_vs30}(undef,0)
  for i=1:vs30_row_num
    B = push!(B,Point_vs30(A[i,1],A[i,2],A[i,3]))
  end
  return B
end
## read VS30 file with Dl column
function read_vs30_dl_file(filename::String)
  A = readdlm(filename)
  vs30_row_num = length(A[:,1])
  B = Array{Point_vs30_dl}(undef,0)
  for i=1:vs30_row_num
    B = push!(B,Point_vs30_dl(A[i,1],A[i,2],A[i,3],A[i,4]))
  end
  return B
end
## convert Array{Point_pga_out}(N,1) array to Array{Float64}(N,4)
"""
convert_to_float_array(B::Array{T,N})
  where T is Point_{pga,pgv,pgd}_out, Point_vs30

  Convert 1-d array of custom type to Array{Float64}(N,X)
"""
function convert_to_float_array(B::Array{Point_pga_out})
  A = Array{Float64}(undef,length(B),3)
  for i=1:length(B)
   A[i,1] = B[i].lon
   A[i,2] = B[i].lat
   A[i,3] = B[i].pga
  end
  return A
end
function convert_to_float_array(B::Array{Point_vs30})
  A = Array{Float64}(undef,length(B),3)
  for i=1:length(B)
   A[i,1] = B[i].lon
   A[i,2] = B[i].lat
   A[i,3] = B[i].vs30
  end
return A
end
function convert_to_float_array(B::Array{Point_vs30_dl})
  A = Array{Float64}(undef,length(B),4)
  for i=1:length(B)
   A[i,1] = B[i].lon
   A[i,2] = B[i].lat
   A[i,3] = B[i].vs30
   A[i,4] = B[i].dl
  end
return A
end

