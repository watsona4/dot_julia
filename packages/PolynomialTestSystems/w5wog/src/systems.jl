export chandra, cyclic, katsura, fourbar, rps10, ipp, ipp2, boon, heart,
    d1, bacillus_subtilis, griewank_osborne, tritangents, cyclooctane

"""
    chandra(n)

The Chandrasekhar H-Equation for `n`.

## References

Laureano Gonzalez-Vega: "Some examples on problem solving by using the
  symbolic viewpoint when dealing with polynomial systems of equations".
  in: "Computer Algebra in Science and Engineering", Editors: J. Fleischer,
  J. Grabmeier, F.W. Hehl and W. Kuechlin.  Pages 102-116
  World Scientific Publishing, 1995.

S. Chandrasekhar: "Radiative Transfer", Dover, NY, 1960.

C.T. Kelley: "Solution of the Chandrasekhar H-equation by Newton's method".
  J. Math. Phys., 21 (1980), pp. 1625-1628.

Jorge J. More': "A collection of nonlinear model problems"
  in: "Computational Solution of Nonlinear Systems of Equations",
  Editors: Eugene L. Allgower and Kurt Georg.  Pages 723-762.
  Lectures in Applied Mathematics, Volume 26, AMS, 1990.

NOTE : the parameter c equals 0.51234.
  In general c can be any number in the interval (0,1]
"""
function chandra(n)
    @polyvar H[1:n]

    return TestSystem([(2n*H[i] - 0.51234H[i]*(1+ sum(i / (j+i) * H[j] for j=1:(n-1))) - 2n) for i=1:n],
        multi_bezout_number=(2^(n-1), [H[1:n-1], [H[n]]]),
        mixed_volume=2^(n-1))
end

"""
    cyclic(n)

The cyclic n-roots problems.

## References

Göran Björck and Ralf Fröberg:
`A faster way to count the solutions of inhomogeneous systems
 of algebraic equations, with applications to cyclic n-roots',
in J. Symbolic Computation (1991) 12, pp 329--336.
"""
function cyclic(n)
    @polyvar z[1:n]

    mv = nothing
    if n == 5
        mv = 70
    elseif n == 6
        mv = 156
    elseif n == 7
        mv = 924
    elseif n == 8
        mv = 2560
    elseif n == 9
        mv = 11016
    elseif n == 10
        mv = 35940
    elseif n == 11
        mv = 184_756
    end

    TestSystem([(sum(prod(z[(k-1) % n + 1] for k in j:j+m) for j in 1:n) for m=0:(n-2))...,prod(z)-1],
        mixed_volume = mv)
end

"""
    katsura(n)

A problem of magnetism in physics.

## References

From the PoSSo test suite.

Shigetoshi Katsura: "Users posing problems to PoSSO",
in the PoSSo Newsletter, no. 2, July 1994,
edited by L. Gonzalez-Vega and T. Recio.
Available at http://janet.dm.unipi.it/

S. Katsura, W. Fukuda, S. Inawashiro, N.M. Fujiki and R. Gebauer,
Cell Biophysics, Vol 11, pages 309--319, 1987.

W. Boege, R. Gebauer, and H. Kredel:
"Some examples for solving systems of algebraic equations by
 calculating Groebner bases", J. Symbolic Computation, 2:83-98, 1986.

Shigetoshi Katsura:
 "Spin Glass Problem by the Method of Integral Equation
  of the Effective Field".  In "New Trends in Magnetism",
edited by Mauricio D. Coutinho-Filho and Sergio M. Resende,
pages 110-121, World Scientific, 1990.
"""
function katsura(n)
  @polyvar x[0:n] # This creates variables x0, x1, ...

  return TestSystem([
    (sum(x[abs(l)+1]*x[abs(m-l)+1] for l=-n:n if abs(m-l)<=n) -
    x[m+1] for m=0:n-1)...,
    x[1] + 2sum(x[i+1] for i=1:n) - 1
  ], mixed_volume=2^n)
end

# Mechanisms

"""
    fourbar()
A four-bar design problem, so-called 5-point problem.

## References

See Morgan, A.P. and Wampler, C.W. :
 `Solving a planar four-bar design problem using continuation'
in Transaction of the ASME, J. of Mechanical Design, Vol. 112
pages 544-550, 1990.

For the coefficients, see Table 2, a = (1,0).
This is the start system, with five random precision points,
that has been used to solve twenty other test systems.
"""
function fourbar()
    @polyvar X1 X2 Y1 Y2

    return TestSystem([
        0.01692601*X1^2*Y1^2 - 0.888509280014*X1^2*Y2^2 + 0.0411717692438*X2^2*Y1^2 - 0.00437457395884*X2^2*Y2^2 + 0.331480641249*X1*X2*Y1^2 - 1.38036964668*X1*X2*Y2^2 - 0.270492270191*X1^2*Y1*Y2 + 1.44135801774*X2^2*Y1*Y2 + 0.859888946812*X1*X2*Y1*Y2 + 0.0791489659197*X1^2*Y1 - 0.00336032777032*X1^2*Y2 - 0.0620826738427*X1*Y1^2 + 0.501879647495*X1*Y2^2 + 0.647156236961*X2^2*Y1 + 0.0926311741907*X2^2*Y2 - 0.255000006226*X2*Y1^2 - 0.0896892386081*X2*Y2^2 - 0.568007271041*X1*X2*Y2 + 0.095991501961*X1*X2*Y1 + 0.165310767618*X1*Y1*Y2 - 0.563962321337*X2*Y1*Y2 - 0.0784871167595*X1*Y1 - 0.0784871167595*X2*Y2 + 0.011807283256*X1*Y2  - 0.011807283256*X2*Y1 + 0.0422876985355*X1^2 + 0.0422876985355*X2^2 + 0.0372427422943*Y1^2 + 0.0372427422943*Y2^2,
        0.518178672335*X1^2*Y1^2 - 0.0414464807343*X1^2*Y2^2 + 2.63600135179*X2^2*Y1^2 - 0.799490472298*X2^2*Y2^2 + 0.29442805494*X1^2*Y1*Y2 + 1.46551534655*X2^2*Y1*Y2 - 0.631878110759*X1*X2*Y1^2 - 1.80296540237*X1*X2*Y2^2 - 2.87586667102*X1*X2*Y1*Y2 - 0.987856648177*X1^2*Y1 - 0.530579106676*X1^2*Y2 - 0.0397576281649*X1*Y1^2 + 0.317719102869*X1*Y2^2 - 1.93710490787*X2^2*Y1  + 0.00127693327315*X2^2*Y2 - 0.581380074072*X2*Y1^2 - 0.0672137066743*X2*Y2^2 + 0.531856039949*X1*X2*Y1 + 0.949248259696*X1*X2*Y2 + 0.514166367398*X1*Y1*Y2 - 0.357476731033*X2*Y1*Y2 + 0.140965913657*X1*Y1  + 0.140965913657*X2*Y2 - 0.153347218606*X1*Y2 + 0.153347218606*X2*Y1 + 0.283274882058*X1^2  + 0.283274882058*X2^2 + 0.0382903330079*Y1^2 + 0.0382903330079*Y2^2,
        0.0233560008057*X1^2*Y1^2 - 0.00428427501149*X1^2*Y1*Y2 - 0.792756311827*X1^2*Y2^2 + 0.0492185850289*X2^2*Y2^2 + 0.0759264856293*X1*X2*Y1^2 + 1.14839711492*X1*X2*Y1*Y2 - 0.283066217262*X2^2*Y1^2 + 0.460041521291*X2^2*Y1*Y2 - 0.388399310674*X1*X2*Y2^2 - 0.0561169736293*X1*Y1^2 + 0.485064247792*X1*Y2^2 + 0.0689567235492*X1^2*Y1 - 0.115620658768*X1^2*Y2 - 0.13286905328*X2*Y1^2 - 0.084375901147*X2*Y2^2 + 0.639964831612*X2^2*Y1 + 0.101386684276*X2^2*Y2 + 0.217007343044*X1*X2*Y1 - 0.571008108063*X1*X2*Y2 + 0.0484931521334*X1*Y1*Y2 - 0.541181221422*X2*Y1*Y2 - 0.00363197918253*X1*Y2 + 0.00363197918253*X2*Y1 - 0.0781302968652*X1*Y1 - 0.0781302968652*X2*Y2 + 0.0471311092612*X1^2 + 0.0471311092612*X2^2 + 0.0324495575052*Y1^2 + 0.0324495575052*Y2^2,
        0.393707415641*X1^2*Y1^2 + 0.59841456862*X1^2*Y2^2 + 0.0735854940135*X2^2*Y1^2 + 0.0548997238169*X2^2*Y2^2 + 0.0116156836985*X1^2*Y1*Y2 + 0.0699694273575*X2^2*Y1*Y2 - 0.305757340849*X1*X2*Y1^2 - 0.364111084508*X1*X2*Y2^2 - 0.223392923175*X1*X2*Y1*Y2 + 0.0996725944534*X1^2*Y1 + 0.0113936468426*X1^2*Y2 - 0.381205205249*X1*Y1^2 - 0.473402150235*X1*Y2^2 - 0.0213613191759*X2^2*Y1 - 0.0372595571271*X2^2*Y2 + 0.148904552394*X2*Y1^2 + 0.142408744984*X2*Y2^2 - 0.0486532039697*X1*X2*Y1 + 0.121033913629*X1*X2*Y2 - 0.00649580741066*X1*Y1*Y2 + 0.092196944986*X2*Y1*Y2 - 0.0483106652705*X1*Y1  - 0.0483106652705*X2*Y2 - 0.00316794272326*X1*Y2 + 0.00316794272326*X2*Y1 + 0.00634952598374*X1^2 + 0.00634952598374*X2^2 + 0.0922886309144*Y1^2  + 0.0922886309144*Y2^2
    ], mixed_volume=80)
end

"""
    ipp()

The six-revolute-joint problem of mechanics.

## References

A. Morgan and A. Sommese
`Computing all solutions to polynomial systems
 using homotopy continuation',
 Appl. Math. Comput., Vol. 24, pp 115-138, 1987.
"""
function ipp()
    @polyvar x1 x2 x3 x4 x5 x6 x7 x8
    TestSystem([x1^2+x2^2-1,
        x3^2+x4^2-1,
        x5^2+x6^2-1,
        x7^2+x8^2-1,
        (-2.4915068E-01*x1*x3+ 1.6091354E+00*x1*x4+ 2.7942343E-01 *x2*x3+ 1.4348016E+00*x2*x4) + (4.0026384E-01*x5*x8-8.0052768E-01*x6*x7+ 7.4052388E-02*x1-8.3050031E-02*x2) - (3.8615961E-01*x3-7.5526603E-01*x4+ 5.0420168E-01*x5 -1.0916287E+00*x6+ 4.0026384E-01*x8) + 4.920729E-02,
        (1.2501635E-01*x1*x3-6.8660736E-01*x1*x4-1.1922812E-01* x2*x3-7.1994047E-01*x2*x4) - (4.3241927E-01*x5*x7-8.6483855E-01*x6*x8-3.715727E-02*x1+ 3.5436896E-02*x2)+ 8.5383482E-02*x3-3.9251967E-02*x5-4.3241927E-01*x7+ 1.387301E-02,
        (-6.3555007E-01*x1*x3-1.1571992E-01*x1*x4-6.6640448E-01 *x2*x3) + (1.1036211E-01*x2*x4+ 2.9070203E-01*x5*x7+ 1.2587767E+00*x5*x8)- (6.2938836E-01*x6*x7+ 5.8140406E-01*x6*x8+ 1.9594662E-01*x1)- (1.2280342E+00*x2-7.9034221E-02*x4+ 2.6387877E-02*x5)- 5.713143E-02*x6-1.1628081E+00*x7+1.2587767E+00*x8+ 2.162575E+00,
        (1.4894773E+00*x1*x3+ 2.3062341E-01*x1*x4+ 1.3281073E+00*x2*x3)-(2.5864503E-01*x2*x4+ 1.165172E+00*x5*x7-2.6908494E-01*x5*x8)+ (5.3816987E-01*x6*x7+ 5.8258598E-01*x6*x8-2.0816985E-01*x1)+(2.686832E+00*x2-6.9910317E-01*x3+ 3.5744413E-01*x4)+ 1.2499117E+00*x5+ 1.467736E+00*x6+ 1.165172E+00*x7+ 1.10763397E+00*x8-6.9686809E-01
        ], mixed_volume=64, nreal_solutions=10, nsolutions=32)
end

"""
    ipp2()

The 6R inverse position problem.

# References

This system occurs as Example 3.3 in a paper by Charles Wampler:
`Bezout Number Calculations for Multi-Homogeneous Polynomial Systems',
Appl. Math. Comput. vol. 51 No. 2--3, pp. 143--157.

For the original formulation of the problem, see
 Charles Wampler and Alexander Morgan:
 `Solving the 6R inverse position problem using a generic-case solution
  methodology', Mech. Mach. Theory, Vol. 26, No. 1, pp. 91-106, 1991.
"""
function ipp2()
    @polyvar z21 z22 z31 z32 z33 z41 z42 z43 z51 z52 z53
    TestSystem([ z21^2 + z22^2 - 1.25830472585 + 1.05384271933im,
        z31^2 + z32^2 + z33^2 - 1,
        z41^2 + z42^2 + z43^2 - 1,
        z51^2 + z52^2 + z53^2 - 1,
        z21*z31 + z22*z32 + (0.642935654806 + 0.819555356316im)*z33- 0.266880023988 - 0.452565255666im,
        z31*z41 + z32*z42 + z33*z43 - 0.26425551745 - 0.342483846503im,
        z41*z51 + z42*z52 + z43*z53 - 0.126010863922 - 0.864590917688im,
        (0.352598136811 + 0.116888144319im)*z51 + (0.539042485525 + 0.687058436892im)*z52 + (0.391154215376 + 0.128900893182im)*z53 - 0.179560356712 - 0.8709166566im,
        (0.984138451804 + 0.414967172346im)*z21 + (0.958341609741 + 0.847442419999im)*z22*z33 + (-0.496254299764 - 0.546020011741im)*z22 + (0.353268870498 + 0.389909226888im)*z31 + (0.964759562277 + 0.71397074519im)*z32*z43 + (0.0783739840935 - 1.33026494666im)*z32 + (-0.964759562277 - 0.71397074519im)*z33*z42 + (0.204379350351 + 0.00374294529684im)*z41 + (0.706319991205 + 0.120097702053im)*z42*z53 + (-0.706319991205 - 0.120097702053im)*z43*z52 + (0.907681632783 + 0.405209293447im)*z51 + (0.148939301127 + 0.182393186752im)*z52 + (-0.0486385369088 - 0.496934768083im)*z53 - 0.437312713588 - 0.914780691357im,
        (-0.958341609741 - 0.847442419999im)*z21*z33 + (0.496254299764 + 0.546020011741im)*z21 + (0.984138451804 + 0.414967172346im)*z22 + (-0.964759562277 - 0.71397074519im)*z31*z43 + (-0.0783739840935 + 1.33026494666im)*z31 + (0.353268870498 + 0.389909226888im)*z32 + ( 0.964759562277 + 0.71397074519im)*z33*z41 + (-0.706319991205 - 0.120097702053im)*z41*z53 + (0.204379350351 + 0.00374294529684im)*z42 + (0.706319991205 + 0.120097702053im)*z43*z51 + (-0.148939301127 - 0.182393186752im)*z51 + (0.907681632783 + 0.405209293447im)*z52 + (0.134045297503 + 0.164748774862im)*z53 - 0.719086796333 - 0.691791591267im,
        (0.958341609741 + 0.847442419999im)*z21*z32 + (-0.958341609741 - 0.847442419999im)*z22*z31 + (0.964759562277 + 0.71397074519im)*z31*z42 + (-0.964759562277 - 0.71397074519im)*z32*z41 + (0.353268870498 + 0.389909226888im)*z33 + (0.706319991205 + 0.120097702053im)*z41*z52 + (-0.706319991205 - 0.120097702053im)*z42*z51 + (0.204379350351 + 0.00374294529684im)*z43 + (0.0486385369088 + 0.496934768083im)*z51  + (-0.134045297503 - 0.164748774862im)*z52 + (0.907681632783 + 0.405209293447im)*z53 - 0.64863071126 + 0.983034576618im
    ],
    multi_bezout_number=(320, [[z21, z22, z41, z42, z43], [z31, z32, z33, z51, z52, z53]]),
    mixed_volume=288)
end

include("rps10.jl")



# Mixed



"""
    boon()

Neurofysiology, posted by Sjirk Boon. Note that the system


## References

The system has been posted to the newsgroup
sci.math.num-analysis by Sjirk Boon.

P. Van Hentenryck, D. McAllester and D. Kapur:
`Solving Polynomial Systems Using a Branch and Prune Approach'
SIAM J. Numerical Analysis, Vol. 34, No. 2, pp 797-827, 1997.

"""
function boon()
    @polyvar s1 g1 s2 g2 C1 C2
    TestSystem([s1^2+g1^2 - 1,
     s2^2+g2^2 - 1,
     C1*g1^3+C2*g2^3 - 1.2,
     C1*s1^3+C2*s2^3 - 1.2,
     C1*g1^2*s1+C2*g2^2*s2 - 0.7,
     C1*g1*s1^2+C2*g2*s2^2 - 0.7], mixed_volume=20, nsolutions=8, nreal_solutions=8)
end

"""
    heart()

The heart-dipole problem.

## References

Nelsen, C.V. and Hodgkin, B.C.:
`Determination of magnitudes, directions, and locations of two independent
dipoles in a circular conducting region from boundary potential measurements'
IEEE Trans. Biomed. Engrg. Vol. BME-28, No. 12, pages 817-823, 1981.

Morgan, A.P. and Sommese, A.J.:
`Coefficient-Parameter Polynomial Continuation'
Appl. Math. Comput. Vol. 29, No. 2, pages 123-160, 1989.
Errata: Appl. Math. Comput. 51:207 (1992)

Morgan, A.P. and Sommese, A. and Watson, L.T.:
`Mathematical reduction of a heart dipole model'
J. Comput. Appl. Math. Vol. 27, pages 407-410, 1989.
"""
function heart()
    @polyvar a b c d t u v w
    TestSystem([a + b - 0.63254;
        c + d + 1.34534;
        t*a + u*b - v*c - w*d + 0.8365348;
        v*a + w*b + t*c + u*d - 1.7345334;
        a*t^2 - a*v^2 - 2*c*t*v + b*u^2 - b*w^2 - 2*d*u*w - 1.352352;
        c*t^2 - c*v^2 + 2*a*t*v + d*u^2 - d*w^2 + 2*b*u*w + 0.843453;
        a*t^3 - 3*a*t*v^2 + c*v^3 - 3*c*v*t^2 + b*u^3 - 3*b*u*w^2 + d*w^3 - 3*d*w*u^2 + 0.9563453;
        c*t^3 - 3*c*t*v^2 - a*v^3 + 3*a*v*t^2 + d*u^3 - 3*d*u*w^2 - b*w^3 + 3*b*w*u^2 - 1.2342523
        ], mixed_volume=121, nsolutions=4, nreal_solutions=2)
end

"""
    d1()

A a sparse system, known as benchmark D1.

## References

H. Hong and V. Stahl:
`Safe Starting Regions by Fixed Points and Tightening',
Computing 53(3-4): 322-335, 1995.
"""
function d1()
    @polyvar x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12
    TestSystem([x1^2  + x2^2 - 1;
         x3^2  + x4^2 - 1;
         x5^2  + x6^2 - 1;
         x7^2  + x8^2 - 1;
         x9^2  + x10^2 - 1;
         x11^2 + x12^2 - 1;
         3*x3 + 2*x5 + x7 - 3.9701;
         3*x1*x4 + 2*x1*x6 + x1*x8 - 1.7172;
         3*x2*x4 + 2*x2*x6 + x2*x8 - 4.0616;
         x3*x9 + x5*x9 + x7*x9 - 1.9791;
         x2*x4*x9 + x2*x6*x9 + x2*x8*x9 + x1*x10 - 1.9115;
         - x3*x10*x11 - x5*x10*x11 - x7*x10*x11 + x4*x12 + x6*x12 + x8*x12 - 0.4077],
         mixed_volume=192,
         nreal_solutions=16,
         nsolutions=48)
end


"""

    bacillus_subtilis()

The system comes from biochemical reactions (Published here https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1005267).
Basically it models how the bacteris B. subtilis produces a stress response protein, sigmaB, in response to some stress input. This input to the system is the concentration of a phosphatase (a kind of protein). In this system I call that variable phos
"""
function bacillus_subtilis()
    @polyvar w w2 w2v v w2v2 vP sigmaB w2sigmaB vPp phos
    poly = [(-1 * 0.7 * w + -2 * 3600.0 * (w ^ 2 / 2) + 2 * 18.0 * w2)*(0.2 + sigmaB) + 4.0 * 0.4 * (1 + 30.0sigmaB),
     -1 * 0.7 * w2 + 3600.0 * (w ^ 2 / 2) + -1 * 18.0 * w2 + -1 * 3600.0 * w2 * v + 18.0w2v + 36.0w2v + -1 * 3600.0 * w2 * sigmaB + 18.0w2sigmaB,
     -1 * 0.7 * w2v + 3600.0 * w2 * v + -1 * 18.0 * w2v + -1 * 3600.0 * w2v * v + 18.0w2v2 + -1 * 36.0 * w2v + 36.0w2v2 + 1800.0 * w2sigmaB * v + -1 * 1800.0 * w2v * sigmaB,
     (-1 * 0.7 * v + -1 * 3600.0 * w2 * v + 18.0w2v + -1 * 3600.0 * w2v * v + 18.0w2v2 + -1 * 1800.0 * w2sigmaB * v + 1800.0 * w2v * sigmaB + 180.0vPp)*(0.2 + sigmaB) + 4.5 * 0.4 * (1 + 30.0sigmaB),
     -1 * 0.7 * w2v2 + 3600.0 * w2v * v + -1 * 18.0 * w2v2 + -1 * 36.0 * w2v2,
     -1 * 0.7 * vP + 36.0w2v + 36.0w2v2 + -1 * 3600.0 * vP * phos + 18.0vPp,
     (-1 * 0.7 * sigmaB + -1 * 3600.0 * w2 * sigmaB + 18.0w2sigmaB + 1800.0 * w2sigmaB * v + -1 * 1800.0 * w2v * sigmaB)*(0.2 + sigmaB) + 0.4 * (1 + 30.0sigmaB),
     -1 * 0.7 * w2sigmaB + 3600.0 * w2 * sigmaB + -1 * 18.0 * w2sigmaB + -1 * 1800.0 * w2sigmaB * v + 1800.0 * w2v * sigmaB,
     -1 * 0.7 * vPp + 3600.0 * vP * phos + -1 * 18.0 * vPp + -1 * 180.0 * vPp,
     (phos + vPp) - 2.0]
    TestSystem(poly; nsolutions=44)
end


"""

    tritangents()

See https://www.juliahomotopycontinuation.org/examples/tritangents/.
"""
function tritangents()
    @polyvar h[1:3] # variables for the plane
    @polyvar x[1:3] y[1:3] z[1:3] #variables for the contact points
    @polyvar c[1:20] #variables for the cubic

    #the quadric
    Q = x[3] - x[1] * x[2]
    #the cubic
    C = c ⋅ unique(kron([x;1], [x;1], [x;1]))

    #generate the system P for the contact point x
    P_x = [
      h ⋅ x - 1;
      Q;
      C;
      det([h differentiate(Q, x) differentiate(C, x)])
    ]

    #generate a copy of P for the other contact points y,z
    P_y = [p([h; x; c] => [h; y; c]) for p in P_x]
    P_z = [p([h; x; c] => [h; z; c]) for p in P_x]

    #define F
    F = [P_x; P_y; P_z]

    #create random complex coefficients for C
    # c₁ is result of randn(ComplexF64, 20)
    c₁ = Complex{Float64}[-0.524114+0.798188im, 0.23203+0.203011im, 0.24588+0.265859im, -0.0293688-0.0838781im, 1.29037+1.19918im, 0.225558+0.113139im, 0.757771+0.327947im, 0.716762-1.14998im, -0.721386+0.253249im, 0.22066+0.286244im, 1.06596-1.24645im, -0.287841-0.15352im, 0.980128+0.798647im, -0.918701-1.5926im, -0.325193-0.163909im, 0.0885901-0.437345im, 0.195358-1.07946im, 0.451222-0.677876im, -0.498035+0.368011im, -1.34059+1.35779im]
    #plug in c₁ for c
    poly = [f([h; x; y; z; c] => [h; x; y; z; c₁]) for f in F]
    TestSystem(poly; nsolutions=720)
end


"""

    griewank_osborne()

This is an illustration of a system for which Newton's method fails near an isolated root.
No matter how close one starts to the multiplicity-three isolated root at the origin, (x,y) = (0,0), Newton's method diverges.

Reference: Griewank & Osborne, 1983
"""
function griewank_osborne()
    @polyvar x y
    TestSystem([(29/16)*x^3 - 2*x*y, x^2 - y])
end


"""

    cyclooctane(c::Float64=2.0)

This is a system that describes the confirmation space of cyclooctane, where the squared distance between neighboring carbon atoms is `c`.  See

    juliahomotopycontinuation.org/examples/cyclooctane/

for a detailed description.
"""
function cyclooctane(c::Float64=2.0)
    @polyvar z[1:3, 1:6]
    z_vec = vec(z)[1:17]
    Z = [zeros(3) z[:,1:5] [z[1,6]; z[2,6]; 0] [√c; 0; 0]]


    F1 = [(Z[:, i] - Z[:, i+1]) ⋅ (Z[:, i] - Z[:, i+1]) - c for i in 1:7]
    F2 = [(Z[:, i] - Z[:, i+2]) ⋅ (Z[:, i] - Z[:, i+2]) - 8c/3 for i in 1:6]
    F3 = (Z[:, 7] - Z[:, 1]) ⋅ (Z[:, 7] - Z[:, 1]) - 8c/3
    F4 = (Z[:, 8] - Z[:, 2]) ⋅ (Z[:, 8] - Z[:, 2]) - 8c/3
    f = [F1; F2; F3; F4]
    TestSystem(f)
end
