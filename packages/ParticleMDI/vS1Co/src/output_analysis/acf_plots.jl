# using Plots
#
# function nchanges(c1, c2)
#   out = Int64(0)
#   n = length(c1)
#   for i in 1:(n - 1)
#     j = i + 1
#     while j <= n
#       if (c1[i] == c1[j]) != (c2[i] == c2[j])
#         out += Int64(1)
#         j = n + 1
#       else
#         j += 1
#       end
#     end
#   end
#   return out
# end
#
# function clustacf(output::Array, maxlag = 20)
#   n = size(output, 2)
#   acfpoints = Vector{Float64}(maxlag + 1)
#   acfpoints[1] = Float64(1)
#   for lag in 1:maxlag
#     tmp = Float64(1)
#     for i in (lag + 1):size(output, 1)
#       tmp -= nchanges(output[i, :], output[i - lag, :]) / ((n - 1) * (size(output, 1) - lag))
#     end
#     acfpoints[lag + 1] = tmp
#   end
#   plot(x=0:maxlag, y = acfpoints, yend = acfpoints * 0, xend = 0:maxlag,
#         Geom.segment,
#         Geom.point,
#         Guide.xticks(ticks = collect(0:maxlag)),
#         Guide.xlabel("Lag"),
#         Guide.ylabel("ACF"),
#         Coord.cartesian(ymin = 0, ymax = 1))
# end
#
#
# function clustrand(output::Array, maxlag = 20)
#   n = size(output, 2)
#   acfpoints = Vector{Float64}(maxlag + 1)
#   acfpoints[1] = Float64(1)
#   for lag in 1:maxlag
#     tmp = Float64(0)
#     for i in (lag + 1):size(output, 1)
#       tmp += randindex(output[i, :], output[i - lag, :])[1] / (size(output, 1) - lag)
#     end
#     acfpoints[lag + 1] = tmp
#   end
#   plot(x=0:maxlag, y = acfpoints, yend = acfpoints * 0, xend = 0:maxlag,
#         Geom.segment,
#         Geom.point,
#         Guide.xticks(ticks = collect(0:maxlag)),
#         Guide.xlabel("Lag"),
#         Guide.ylabel("ACF"),
#         Coord.cartesian(ymin = 0, ymax = 1))
# end
