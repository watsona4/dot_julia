function [res] = mskenopt(d,c,a,blc,buc,param,cmd)
%
% Syntax : [res] = mskenopt(d,c,a,blc,buc,param,cmd)
%
%
% Purpose: Solves the entropy optimization problem
%
%          minimize           d'*(x.*ln(x))+c'*x
%          subject to  blc <=         a*x        <= buc
%                      0   <=           x 
%
%          It is required that d>=0.0.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

if nargin<6 
  param = [];
end

if nargin<7 
  cmd = 'minimize';
end

prob     = [];

[m,n]    = size(a);

nl.m     = m;
nl.n     = n;
nl.nzgo  = 0;
nl.nzgc  = 0;
nl.nzh   = 0;
nl.d     = d; 
gosub    = zeros(1,n);

t        = 1;
if ( min(d(:))<-16*eps )
  error('Invalid d');
end

gosub             = find(d(:)>=16*eps);
nl.nzgo           = length(gosub);

nl.nzh            = nl.nzgc;   
nl.grdobjsub      = gosub(:);

prob.nlfun.handle = nl;
prob.nlfun.getsp  = 'mskenspa';
prob.nlfun.getva  = 'mskenval'; 
prob.nlfun.grdobj = sparse(nl.grdobjsub,ones(nl.nzgo,1),ones(nl.nzgo,1),n,1);
prob.nlfun.conval = zeros(m,1);
prob.nlfun.grdcon = sparse(n,m);
prob.c            = c;
if issparse(a)
  prob.a          = a;
else
  prob.a          = sparse(a);
end
if nargin>3
  prob.blc        = blc;
end
if nargin>4 
  prob.buc        = buc;
end
prob.blx          = sparse(n,1);
prob.bux          = [];

[rcode,res]       = mosekopt(cmd,prob,param);
res.rcode         = rcode;

