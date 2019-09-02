export ggplot_axes

split_ggargs(args...) = (),args
split_ggargs(ax::AxisId,args...) = (ax,),args
split_ggargs(ax1::AxisId,ax2::AxisId,args...) = (ax1,ax2),args
split_ggargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,args...) = (ax1,ax2,ax3),args
split_ggargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,ax4::AxisId,args...) =
  (ax1,ax2,ax3,ax4),args
split_ggargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,ax4::AxisId,ax5::AxisId,args...) =
  (ax1,ax2,ax3,ax4,ax5),args
split_ggargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,ax4::AxisId,ax5::AxisId,
  ax6::AxisId,args...) = (ax1,ax2,ax3,ax4,ax5,ax6),args
function split_ggargs(ax1::AxisId,ax2::AxisId,ax3::AxisId,ax4::AxisId,
                      ax5::AxisId,ax6::AxisId,ax7::AxisId,args...)
  error("Plotting data using 7 or more axes is not supported by ggplot backend.")
end

function ggplot_axes(data,args...;kwds...)
  ax, args = split_ggargs(args...)
  df, axes = asplotable(data,ax...;kwds...)
  if eltype(df.value) <: Complex
    df.value = abs.(df.value)
    @warn("Ignoring phase of complex value")
  end

  ggplot_axes_(df,axes,names(df)[2:end]...;args=args)
end

function ggplot_axes_(df,axes,x;args)
  R"""
  library(ggplot2)
  ggplot($df,aes_string(x=$(string(x)),y="value")) + geom_line()
  """
end

function ggplot_axes_(df,axes,x,y;args)
  R"""
  library(ggplot2)
  ggplot($df,aes_string(x=$(string(x)),y=$(string(y)))) +
      geom_raster(aes(fill=value))
  """
end

function ggplot_axes_(df,axes,x,y,z;args)
  R"""
  library(ggplot2)
  ggplot($df,aes_string(x=$(string(x)),y=$(string(y)))) +
      geom_raster(aes(fill=value)) +
      facet_wrap(as.formula(paste("~", $(string(z)))),
        labeller="label_both")
  """
end

function ggplot_axes_(df,axes,x,y,z,w;args)
  R"""
  library(ggplot2)
  ggplot($df,aes_string(x=$(string(x)),y=$(string(y)))) +
      geom_raster(aes(fill=value)) +
      facet_grid(as.formula(paste($(string(w)), "~",
        $(string(z)))),labeller="label_both")
  """
end

function ggplot_axes_(df,axes,x,y,z,w,v;args)
  R"""
  library(ggplot2)
  ggplot($df,aes_string(x=$(string(x)),y=$(string(y)))) +
      geom_raster(aes(fill=value)) +
      facet_grid(as.formula(paste($(string(w)), "~",
        $(string(z)), "+", $(string(v)))),labeller="label_both")
  """
end

function ggplot_axes_(df,axes,x,y,z,w,v,u;args)
  R"""
  library(ggplot2)
  ggplot($df,aes_string(x=$(string(x)),y=$(string(y)))) +
      geom_raster(aes(fill=value)) +
      facet_grid(as.formula(paste($(string(w)), "+", $(string(u)), "~",
        $(string(z)), "+", $(string(v)))),labeller="label_both")
  """
end

function ggplot_axes_(df,axes,args...;kwds...)
  error("Plotting data with $(length(axes)) dims along
        $(length(args)) axes is not supported.")
end
