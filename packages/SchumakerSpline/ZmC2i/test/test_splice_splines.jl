using SchumakerSpline
from = 0.5
to = 10
x1 = collect(range(from, stop=to, length=40))
y1 = (x1).^2
x2 = [0.5,0.75,0.8,0.93,0.9755,1.0,1.1,1.4,2.0]
y2 = sqrt.(x2)
left_spline = Schumaker(x1,y1)
right_spline = Schumaker(x2,y2)

crossover_point = get_intersection_points(left_spline,right_spline)

splice_point = crossover_point[1]
spliced = splice_splines(left_spline, right_spline, splice_point)
# Testing at splice point
abs(evaluate(spliced, splice_point) - evaluate(right_spline, splice_point))          < 100*eps()
# As this was a continuous split
abs(evaluate(spliced, splice_point- 100*eps()) - evaluate(spliced, splice_point + 100*eps()))          < 10000*eps()
# Testing in left spline territory.
abs(evaluate(spliced, splice_point-0.5) - evaluate(left_spline, splice_point-0.5))   < 100*eps()
abs(evaluate(spliced, splice_point-0.5) - evaluate(right_spline, splice_point-0.5))  > 0.1
# Testing solidly into right spline territory.
abs(evaluate(spliced, splice_point+0.5) - evaluate(left_spline, splice_point+0.5))   > 100*eps()
abs(evaluate(spliced, splice_point+0.5) - evaluate(right_spline, splice_point+0.5))  < 0.1

splice_point = 1.7
spliced = splice_splines(left_spline, right_spline, splice_point)
# Testing at splice point
abs(evaluate(spliced, splice_point) - evaluate(right_spline, splice_point))          < 100*eps()
# As this was NOT a continuous split
abs(evaluate(spliced, splice_point- 100*eps()) - evaluate(spliced, splice_point + 100*eps()))  > 0.1
# Testing in left spline territory.
abs(evaluate(spliced, splice_point-0.5) - evaluate(left_spline, splice_point-0.5))   < 100*eps()
abs(evaluate(spliced, splice_point-0.5) - evaluate(right_spline, splice_point-0.5))  > 0.1
# Testing solidly into right spline territory.
abs(evaluate(spliced, splice_point+0.5) - evaluate(left_spline, splice_point+0.5))   > 100*eps()
abs(evaluate(spliced, splice_point+0.5) - evaluate(right_spline, splice_point+0.5))  < 0.1
