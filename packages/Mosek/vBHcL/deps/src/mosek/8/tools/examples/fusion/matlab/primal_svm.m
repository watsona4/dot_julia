%
% Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
% File:      primal_svm.m
%
% Purpose: Implements a simple soft-margin SVM
%          using the Fusion API.
%
function primal_svm()
   
import mosek.fusion.*

nc = 10;
m  = 50;
n  = 3;

rng(0,'twister');

nump= randi(m) - 1 ;
numm= m - nump;

y = cat(1 , ones(nump,1) , -ones(numm,1));

mean = 1.;
var = 1.;

X = cat(1, var.*randn(nump,n) + mean, var.*randn(numm,n) - mean) ;

disp(['Number of data    : ', num2str(m)])
disp(['Number of features: ', num2str(n)])


M = Model('primal SVM');

w =  M.variable('w',   n, Domain.unbounded());
t =  M.variable('t',   1, Domain.unbounded());
b =  M.variable('b',   1, Domain.unbounded());
xi = M.variable('xi',  m, Domain.greaterThan(0.));

M.constraint( Expr.add(Expr.mulElm( y, Expr.sub( Expr.mul(X,w), ...
                                                 Var.repeat(b,m) ) ), xi) , Domain.greaterThan( 1. ) );

M.constraint( Expr.vstack(1., t, w) , Domain.inRotatedQCone() );

M.acceptedSolutionStatus(AccSolutionStatus.NearOptimal);

disp('   c   | b      | w');
for i = 1:nc 

    c = i*500.0;
    M.objective(ObjectiveSense.Minimize, Expr.add( t, Expr.mul(c, ...
                                                      Expr.sum(xi) ) ) );
    M.solve();

    disp( [ num2str(c),' | ', num2str(b.level()) , ' | ' , num2str( w.level()' ) ] );
             
end

end