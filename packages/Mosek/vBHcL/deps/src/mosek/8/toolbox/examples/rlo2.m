%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      rlo2.m
%
%  Purpose :   Solves the problem:
%
%              Maximize t 
%              subject to
%                        t <= sum(delta(j)*x(j)) -Omega*z,
%                        y(j) = sigma(j)*x(j), j=1,...,n,
%                        sum(x(j)) = 1,
%                        || y || <= z,
%

function rlo2(n, Omega, draw)

n = str2num(n)
Omega = str2num(Omega)
draw

% Set nominal returns and volatilities
delta = (0.96/(n-1))*[0:1:n-1]+1.04;
sigma = (1.152/(n-1))*[0:1:n-1];

% Set mosekopt description of the problem
prob.c = -[1;zeros(2*n+1,1)];
A      = [-1,ones(1,n)+delta,-Omega,zeros(1,n);zeros(n+1,2*n+2)];
for j=1:n,
    % Body of the constraint y(j) - sigma(j)*x(j) = 0:
    A(j+1,j+1)   = -sigma(j);
    A(j+1,2+n+j) = 1;
end;
A(n+2,2:n+1)        = ones(1,n);
prob.a             = sparse(A);
prob.blc           = [zeros(n+1,1);1];
prob.buc           = [inf;zeros(n,1);1];
prob.blx           = [-inf;zeros(n,1);0;zeros(n,1)];
prob.bux           = inf*ones(2*n+2,1);
prob.cones         = cell(1,1);
prob.cones{1}.type = 'MSK_CT_QUAD';
prob.cones{1}.sub  = [n+2;[n+3:1:2*n+2]'];

% Run mosekopt
[r,res]=mosekopt('minimize echo(1)',prob);

if draw == true 
    % Display the solution
    xx = res.sol.itr.xx;
    t  = xx(1);

    disp(sprintf('Robust optimal value: %5.4f',t));
    x = max(xx(2:1+n),zeros(n,1));
    plot([1:1:n],x,'-m');
    grid on;
    
    disp('Press <Enter> to run simulations');
    pause
    
    % Run simulations
    
    Nsim = 10000;
    out  = zeros(Nsim,1);
    for i=1:Nsim,
        returns  = delta+(2*rand(1,n)-1).*sigma;
        out(i)   = returns*x;
    end;
    disp(sprintf('Actual returns over %d simulations:',Nsim));
    disp(sprintf('Min=%5.4f Mean=%5.4f Max=%5.4f StD=%5.2f',...
                 min(out),mean(out),max(out),std(out)));
    hist(out);
end