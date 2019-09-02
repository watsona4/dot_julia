using Test
using HyperbolicPlane

p = HPoint(0)
q = HPoint(.2)
r = HPoint(0-0.2im)
@test dist(p,q) == dist(r)

p[:color] = "red"
@test p[:color] == "red"

P = RandomHPoint()
Q = RandomHPoint()
S = P+Q
L = HLine(P,Q)
@test issubset(S,L)
M = midpoint(S)
@test in(P,L)
@test in(P,S)
@test issubset(P+M,S)

@test length(S) == dist(P,Q)

x1 = length(S)
x2 = length(P+M) + length(M+Q)
@test abs(x1-x2) < 100*eps(1.)

T = P+Q+M
@test area(T) < 100*eps(1.0)


L = HLine(1,3)
LL = HLine(2,pi)
P = meet(L,LL)
@test in(P,L)
@test in(P,LL)

TT = reflect_across(T,L)
TT = reflect_across(TT,L)
@test T == TT


S = RandomHSegment()
L = HLine(S)
SS = S'
LL = HLine(SS)
@test L == LL'

SS = -S
LL = HLine(SS)
@test L == -LL

a,b,c,d = [RandomHPoint() for t=1:4]
X = HPolygon(a,b,c,d,HPoint(im*eps(1.0)))
Y = HPolygon(d,c,b,a,HPoint(0))
@test X==Y

C = HContainer()
P = RandomHPolygon(5)
for k=1:10
    add_object!(C,P)
end

T = RandomHTriangle()
add_object!(C,T)
TT = T'
add_object!(C,TT')
@test length(C) == 2


a,b,c = endpoints(T)
@test a+c+b == T

P = RandomHPolygon(3)
T = HTriangle(P)
aP = sort(angles(P))
aT = angles(T)
@test sum(abs.(aP-aT)) < 100*eps(1.0)

T = HPoint(1.0,2.0) + HPoint(3.0,-1) + HPoint(2,0)
P = HPolygon(T)
@test perimeter(T) == perimeter(P)

# point on line stuff
L = RandomHLine()
P = point_on_line(L)
@test in(P,L)

PP = points_on_line(L,2)
P,Q = PP
@test in(P,L) && in(Q,L)

R = RandomHRay()
V = get_vertex(R)
P = point_on_ray(R)
@test in(P,R)
A = midpoint(V,P)
@test in(A,R)



# Polygon area
X = equilateral(6,1)
T = X.plist[1] + X.plist[2] + HPoint()
AX = area(X)
AT = area(T)
@test abs(AX-6AT) <= equality_threshold() * eps(1.0)
