using Test
using KernelDensityEstimate
using KernelDensityEstimatePlotting
using Colors

# check for errors on plotting code
p = kde!(rand(100));
q = kde!(rand(100).+1.0);

plotKDE([p],c=["red"]);
plot(p);

plot([p;q])
plot([p;q], c=["red";"green"])

p2 = kde!(rand(3,100));
q2 = kde!(rand(3,100).+1.0);

plot(p2);
plot([p2;q2]);
plot([p2;q2];c=["red";"green"],levels=3);
