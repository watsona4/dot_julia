export vlplot_axes

function asvlplot_scale(scale)
  if scale in [:linear,:log,:sqrt,:time,:utc,:sequential]
    string(scale)
  else
    error("Unsupported scale type $scale")
  end
end

function vlplot_axes(data,args...;colors="reds",width=300,height=300,kwds...)
  df, axes = asplotable(data,args...;kwds...)
  if any(x -> x isa QualitativePlotAxis,axes)
    error("VegaLite interface does not yet support qualitative axes.")
  end

  vlplot_axes_(df,axes,names(df)[2:end]...;colors=colors,
               width=width,height=height)
end

function vlplot_axes_(df,axes,x;colors,width,height)
  df |>
    @vlplot(:line, width=width, height=height,
            x={field=x,typ="quantitative", bin={step=axes[1].step},
               scale={typ=asvlplot_scale(axes[1].scale)}},
            y={field=:value,typ="quantitative"})
end

function vlplot_axes_(df,axes,x,y;colors,width,height)
  df |>
  @vlplot(:rect, width=width, height=height,
          x={field=x,typ="quantitative", bin={step=axes[1].step},
             scale={typ=asvlplot_scale(axes[1].scale)}},
          y={field=y,typ="quantitative", bin={step=axes[2].step},
             scale={typ=asvlplot_scale(axes[2].scale)}},
          color={field=:value, aggregate="mean", typ="quantitative"},
          config={view={stroke="transparent"},
                  scale={bandPaddingInner=0, bandPaddingOuter=0},
                  range={heatmap={scheme=colors}}})
end

function vlplot_axes_(df,axes,x,y,z;colors,width,height)
  df |>
    @vlplot(:rect, width=width, height=height,
            x={field=x,typ="quantitative", bin={step=axes[1].step},
               scale={typ=asvlplot_scale(axes[1].scale)}},
            y={field=y,typ="quantitative", bin={step=axes[2].step},
               scale={typ=asvlplot_scale(axes[2].scale)}},
            color={field=:value, aggregate="mean", typ="quantitative"},
            column={field=z},
            config={view={stroke="transparent"},
                    scale={bandPaddingInner=0, bandPaddingOuter=0},
                    range={heatmap={scheme=colors}}})
end

function vlplot_axes_(df,axes,x,y,z,w;colors,width,height)
  df |>
    @vlplot(:rect, width=width, height=height,
            x={field=x,typ="quantitative", bin={step=axes[1].step},
               scale={typ=asvlplot_scale(axes[1].scale)}},
            y={field=y,typ="quantitative", bin={step=axes[2].step},
               scale={typ=asvlplot_scale(axes[2].scale)}},
            color={field=:value, aggregate="mean", typ="quantitative"},
            column={field=z},row={field=w},
            config={view={stroke="transparent"},
                    scale={bandPaddingInner=0, bandPaddingOuter=0},
                    range={heatmap={scheme=colors}}})
end

function vlplot_axes_(df,axes,args...;kwds...)
  error("Plotting data with $(length(axes)) dims along
        $(length(args)) axes is not supported.")
end
