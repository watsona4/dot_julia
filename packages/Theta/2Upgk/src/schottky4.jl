"""
    schottky_genus_4(τ)

Compute the value of the genus 4 Schottky-Igusa polynomial, given as input a 4x4 matrix in the Siegel upper half space.
"""
function schottky_genus_4(τ::Array{<:Number})
    R = RiemannMatrix(τ, siegel=false, ϵ=1.0e-10, nderivs=0);
    m1 = [[1,0,1,0], [1,0,1,0]];
    m2 = [[0,0,0,1], [1,0,0,0]];
    m3 = [[0,0,1,1], [1,0,1,1]];
    n1 = [[0,0,0,1], [1,1,1,0]];
    n2 = [[0,0,1,1], [0,0,0,1]];
    n3 = [[0,0,1,0], [1,0,1,1]];
    p1 = 1;
    p2 = 1;
    p3 = 1;
    z = [0; 0; 0; 0];
    for i1=0:1, i2=0:1, i3=0:1
        n = i1*n1 + i2*n2 + i3*n3;
        c1 = theta(z, R, char=remainder_char(m1+n));
        c2 = theta(z, R, char=remainder_char(m2+n));
        c3 = theta(z, R, char=remainder_char(m3+n));
        p1 *= c1;
        p2 *= c2;
        p3 *= c3;
    end
    schottky_poly = p1^2 + p2^2 + p3^2 - 2*p1*p2 - 2*p1*p3 - 2*p2*p3;
    return schottky_poly
end

"""
    random_nonschottky_genus_4(tol=0.1, trials=100)

Find a random 4x4 matrix in the Siegel upper half space which is not in the Schottky locus, up to the input tolerance and number of trials.
"""
function random_nonschottky_genus_4(tol::Real=0.1, trials::Integer=100)
    t = 0; # largest value of schottky polynomial
    i = 0; # counter for number of trials
    max_matrix = rand(4,4); # stores best non-schottky candidate
    while t < tol && i < trials
        τ = random_siegel(4);
        s = schottky_genus_4(τ);
        if abs(s) > t
            t = abs(s)
            max_matrix = τ;
        end
        i += 1;
    end
    return [max_matrix, t];
end

