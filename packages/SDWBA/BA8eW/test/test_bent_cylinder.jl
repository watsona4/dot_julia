# using PyPlot

###############################################################################
# This code section is translated directly from Joe's matlab script. It uses
# the bent-cylinder equation from Stanton 1998 (II).
###############################################################################

freq = 10.0.^range(3., stop=6., length=1000);
# define contants
Theta = 0;
g = 1.0357; # rho2/rho1
rho1 = 1.025; # density of water
rho2 = g*rho1; # density of shrimp
h = 1.0279; # c2 / c1
c1 = 1500; # spped of sound in  seawater
c2 = h*c1; # speed of sound in shrimp



a = 1.9E-3; # in m
rho_c_div_L = 2.2;
L = 29E-3; #in m
Ldiva = 16;
a = L./Ldiva;

R_12 = ((rho2*c2)/(rho1*c1) - 1) ./ (rho2*c2/(rho2*c1) + 1);

k1 = 2*pi.* freq ./ c1;
k2 =  2*pi.* freq ./ c2;


T_12 = 2*(rho2*c2./(rho1*c1)) / (1 + (rho2*c2./(rho1*c1)));
T_21 = 2*(rho1*c1./(rho2*c2)) / (1 + (rho1*c1./(rho2*c2)));
rho_c = rho_c_div_L * L;

alpha_B = 0.8;
mu_term = -pi/2*k1*a ./ (k1*a .+ 0.4);

I_o = 1 .- T_12 * T_21 .* exp.(im*4*k2*a) .* exp.(im*mu_term);

f_shrimp = 1/2*sqrt(rho_c*a) * R_12 .* exp.(-im*2*k1*a) .* I_o .*
	exp.(-alpha_B*(2*Theta*rho_c / L)^2);


TS_s = 10*log10.(abs.(f_shrimp).^2);
TS_shrimp = TS_s;


# plot(freq,TS_s);
# axis([350E3 800E3 -100 -40]);

###############################################################################
# recreating above using DWBA
###############################################################################
n_segments = 20

phi = 1 / rho_c_div_L
curvature_angle = range(-phi / 2, stop=phi / 2, length=n_segments)
origin = (rho_c - a) * [sin(phi / 2), cos(phi / 2)]
x = (rho_c - a) .* sin.(curvature_angle) .- origin[1]
z = (rho_c - a) .* cos.(curvature_angle) .- origin[2]
# plot(x, z)


bent_cylinder = Scatterer(
	[x'; zeros(1, n_segments); z'],
	a * ones(n_segments),
	h * ones(n_segments),
	g * ones(n_segments),
)

dwba = freq_spectrum(bent_cylinder, freq[1], freq[end], c1, length(k1))
# plot(freq, TS_s)
# plot(dwba["freq"], dwba["TS"])


@test dwba["TS"][1:10] == [-146.4384727146246,-134.3981674296699,-127.35600801470818,
	-122.36054597020149,-118.48682943594616,-115.3228602668385,-112.64886618846771,
	-110.33366282447088,-108.29263365106235,-106.46800319058687]
