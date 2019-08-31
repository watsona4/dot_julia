"Line Plot of  with UnicodePlots"
function plotscalar(; title = "", display_ = display, LTX::Type{TX} = Float64, LTY::Type{TY} = Float64) where {TX, TY}
  xs = TX[]
  ys = TY[]
  maxseen = typemin(TY)
  minseen = typemax(TY)

  function innerplotscalar((x, y))
    push!(xs, x)
    push!(ys, y)
    if !isempty(xs)
      display_(UnicodePlots.lineplot(xs, ys, title = title))
    end
    if y > maxseen
      maxseen = y
      printstyled("\nNew max at $x: $y\n"; color = :light_blue)
    end
    if y < minseen
      minseen = y
      printstyled("\nNew min at $x: $y\n"; color = :light_blue)
    end
  end
end