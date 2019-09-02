using SchumakerSpline
from = 0.0
to = 10
x1 = collect(range(from, stop=to, length=40))
y1 = (x1).^2
s1 = Schumaker(x1,y1; extrapolation = (Constant, Curve))
#plot(s1)
abs(s1(x1[1]) - s1(x1[1]-0.5)) < eps()
abs(s1(x1[40]) - s1(x1[40]+0.5)) > 0.01

s2 = Schumaker(x1,y1; extrapolation = (Constant, Constant))
abs(s2(x1[40]) - s2(x1[40]+0.5)) < eps()
plot(s2)

s3 = Schumaker(x1,y1; extrapolation = (Constant, Linear))
abs((s3(x1[40]+0.5) - s3(x1[40])) - (s3(x1[40]+1.5) - s3(x1[40]+1.0))) < 2e-14
TopX = x1[40]
abs(s3(TopX - 10*eps()) + s3(TopX - 10*eps(),1)*0.5 - s3(TopX +0.5) ) < 1000*eps()
