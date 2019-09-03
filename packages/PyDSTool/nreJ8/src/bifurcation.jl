mutable struct BifurcationCurve{DType,SPType}
  points::DType
  stab::Vector{String}
  special_points::SPType
  changes::Vector{Int}
end

@recipe function f(bif::BifurcationCurve,coords)
  x = bif.points[coords[1]]
  y = bif.points[coords[2]]
  g = bif.stab
  style_order = unique(bif.stab)

  linestyle --> reshape([style == "S" ? :solid : :dash for style in style_order],1,length(style_order))
  color --> reshape([style == "S" ? :blue : :red for style in style_order],1,length(style_order))
  legend --> false
  xlabel --> coords[1]
  ylabel --> coords[2]

  for k in keys(bif.special_points)
    @series begin
      seriestype --> :scatter
      markersize --> 5
      color := :red
      [bif.special_points[k][coords[1]]],[bif.special_points[k][coords[2]]]
    end
  end
  CompositeLine((x, y, g))
end

mutable struct CompositeLine
  args
end

@recipe function f(h::CompositeLine)
    x, y, linegroups = h.args

    seriesx = Dict{eltype(linegroups), Vector{Float64}}()
    seriesy = Dict{eltype(linegroups), Vector{Float64}}()

    for i in 1:length(linegroups)
        if ! haskey(seriesx, linegroups[i])
            seriesx[linegroups[i]] = Float64[]
            seriesy[linegroups[i]] = Float64[]
        end

        push!(seriesx[linegroups[i]], x[i])
        push!(seriesy[linegroups[i]], y[i])

        if i > 1 && linegroups[i] != linegroups[i-1]
            # End the previous series with the same point to avoid gaps
            push!(seriesx[linegroups[i-1]], x[i])
            push!(seriesy[linegroups[i-1]], y[i])

            # Add an NaN to stop the group
            push!(seriesx[linegroups[i-1]], NaN)
            push!(seriesy[linegroups[i-1]], NaN)

        end
    end

    seriestype := :path

    for key in keys(seriesx)
        @series begin
            seriesx[key], seriesy[key]
        end
    end

end

function bifurcation_curve(PC,bif_type,freepars;max_num_points=450,
                          max_stepsize=2,min_stepsize=1e-5,
                          stepsize=2e-2,loc_bif_points="all",
                          save_eigen=true,name="DefaultName",
                          print_info=true,calc_stab=true,
                          var_tol = 1e-6, func_tol = 1e-6,
                          test_tol = 1e-4,
                          initpoint=nothing,solver_sequence=[:forward])

  curve_point_type = bif_type[1:end-2]

  if !(typeof(freepars)<:AbstractArray)
    freepars = [freepars]
  end

  # Setup Parameters
  PCargs = ds[:args](name=name)
  PCargs[:type]         = bif_type
  PCargs[:freepars]     = freepars
  PCargs[:MaxNumPoints] = max_num_points
  PCargs[:MaxStepSize]  = max_stepsize
  PCargs[:MinStepSize]  = min_stepsize
  PCargs[:StepSize]     = stepsize
  PCargs[:LocBifPoints] = loc_bif_points
  PCargs[:SaveEigen]    = save_eigen
  PCargs[:VarTol]       = var_tol
  PCargs[:FuncTol]      = func_tol
  PCargs[:TestTol]      = test_tol
  if initpoint != nothing
    PCargs[:initpoint] = initpoint
  end

  # Run Solver
  PC[:newCurve](PCargs)
  for step in solver_sequence
    PC[:curves][name][step]()
  end

  # Print Info
  if print_info
    PC[:curves][name][:info]()
  end


  # Get the curve
  pts = PyDict(PC[:curves][name][:_curveToPointset]())
  points = OrderedDict{Symbol,Vector{Float64}}()
  for k in keys(pts)
    points[Symbol(k)] = pts[k]
  end
  len = length(points[first(keys(points))])

  # Get the stability
  # S => Stable
  # U => Unstable
  # N => Neutral

  # Get this from the information at:
  # https://github.com/robclewley/pydstool/blob/master/PyDSTool/PyCont/ContClass.py#L218
  curve = PC[:curves][name]
  if calc_stab
    stab = [curve[:CurveInfo][i][curve_point_type]["stab"] for i in 1:len]
  else
    stab = []
  end

  # Get information for special points, ex limit points
  special_points = Dict{String,Any}()
  for k in keys(curve[:BifPoints])
    for i in 1:length(curve[:BifPoints][k][:found])
      tmp_dict = PyDict(curve[:BifPoints][k][:found][i]["X"])
      dd = Dict{Symbol,Float64}()
      for k2 in keys(tmp_dict)
        dd[Symbol(k2)]=tmp_dict[k2]
      end
      special_points[k*string(i)] = dd
    end
  end
  #=
  # Start and endpoints
  for i in 1:len
    if "P" in keys(curve[i])
      tmp_dict = PyDict(curve[i]["P"]["data"]["V"])
      dd = Dict{Symbol,Float64}()
      for k in keys(tmp_dict)
        dd[Symbol(k)]=tmp_dict[k]
      end
      special_points[curve[i]["P"]["name"]] = dd
    end
  end
  =#

  changes = find_changes(stab)

  BifurcationCurve(points,stab,special_points,changes)
end

function find_changes(stab)
  changes = Int[]
  for i in 2:length(stab)
    if stab[i]!= stab[i-1]
      push!(changes,i)
    end
  end
  changes
end
