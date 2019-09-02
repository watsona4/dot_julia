export gadplot_axes

split_gadargs(args...) = (),args
split_gadargs(ax::AxisId,args...) = (ax,),args
split_gadargs(ax1::AxisId,ax2::AxisId,args...) = (ax1,ax2),args
split_gadargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,args...) = (ax1,ax2,ax3),args
split_gadargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,ax4::AxisId,args...) =
  (ax1,ax2,ax3,ax4),args
function split_gadargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,ax4::AxisId,
                      ax5::AxisId,args...)
  error("Plotting data using 5 or more axes is not supported by Gadfly backend.")
end

function gadplot_axes(data,args...;kwds...)
  ax, args = split_gadargs(args...)
  df, axes = asplotable(data,ax...;kwds...)
  if eltype(df.value) <: Complex
    df.value = abs.(df.value)
    @warn("Ignoring phase of complex value")
  end

  gadplot_axes_(df,axes,names(df)[2:end]...;args=args)
end

function gadplot_axes_(df,axes,x;args)
  plot(df,x=x,y=:value,Geom.line,args...)
end

function gadplot_axes_(df,axes,x,y;args)
  (xmin,xmax) = extrema(df[x])
  (ymin,ymax) = extrema(df[y])
  plot(df,x=x,y=y,color=:value,Geom.rectbin,
       Coord.cartesian(xmin=xmin,xmax=xmax),args...)
end

function gadplot_axes_(df,axes,x,y,z;args)
  xmin,xmax = extrema(df[x])
  ymin,ymax = extrema(df[y])
  plot(df,x=x,y=y,color=:value,xgroup=z,
       Geom.subplot_grid(Geom.rectbin,
                         Coord.cartesian(xmin=xmin,xmax=xmax,
                                         ymin=ymin,ymax=ymax)),args...)
end

function gadplot_axes_(df,axes,x,y,z,w;args)
  xmin,xmax = extrema(df[x])
  ymin,ymax = extrema(df[y])
  plot(df,x=x,y=y,color=:value,xgroup=z,ygroup=w,
       Geom.subplot_grid(Geom.rectbin,
                         Coord.cartesian(xmin=xmin,xmax=xmax,
                                         ymin=ymin,ymax=ymax)),args...)
end
function gadplot_axes_(df,axes,args...;kwds...)
  error("Plotting data with $(length(axes)) dims along
        $(length(args)) axes is not supported.")
end
