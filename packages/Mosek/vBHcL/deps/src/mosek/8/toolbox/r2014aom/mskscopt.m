function [res] = mskscopt(opr,opri,oprj,oprf,oprg,c,a,blc,buc,blx,bux,param,cmd)
%
% Syntax : [res] = mskscopt(opr,opri,oprj,oprf,oprg,c,a,blc,buc,blx,bux,param,cmd)
%
% Purpose: Solves separable convex optimization problems on the form
%
%          minimize               c'*x + sum_j f_j(x_j)
%          subject to  blc(k) <=  a(k,:)*x + sum_j g_{kj}(x_j)  <= buc(k), k=1,...,size(a)
%                      blx    <=           x                    <= bux
%
% The nonlinear functions f_j and g_{kj} are specified using opr, opri, oprj
% oprf, oprg as follows. For all k between 1 and length(opri) then following
% nonlinear expression
%
% if opr(k,:)=='ent' 
%   oprf(k) * x(oprj(k)) * log(x(oprj(k)))
% elseif if opr(k,:)=='exp' 
%   oprf(k) * exp(oprg(k)*x(oprj(k)))
% elseif if opr(k,:)=='log' 
%   oprf(k) * log(x(oprj(k)))
% elseif if opr(k,:)=='pow' 
%   oprf(k) * x(oprj(k))^oprg(k)
% else
%   An invalid operator has been specified. 
%
% is added to the objective if opri(k)=0. Otherwise it is added to constraint
% opri(k).
%
%   
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

prob   = [];  
prob.c = c;
if issparse(a)
   prob.a = a;
else
   prob.a = sparse(a);
end

if nargin>7
   prob.blc = blc;
end

if nargin>8
   prob.buc = buc;
end

if nargin>9
   prob.blx = blx;
end   

if nargin>10
   prob.bux = bux;
end   

if nargin<12
   param = [];
end

if nargin<13
   cmd = 'minimize';
end   

opri            = opri(:);
oprj            = oprj(:);
oprf            = oprf(:);
oprg            = oprg(:);

[numcon,numvar] = size(a);

operators       = ['ent';...       % f*x*log(x)
                   'exp';...       % f*exp(g*x) 
                   'log';...       % f*log(x)  
                   'pow'];         % f*x^g   
       
numopr          = size(opr,1);
             
if length(opri)~=numopr             
   error('opri is of incorrect length');
end   

if length(oprj)~=numopr             
   error('oprj is of incorrect length');
end   

if length(oprf)~=numopr             
   error('oprf is of incorrect length');
end   

if length(oprg)~=numopr             
   error('opri is of incorrect length');
end   

oprtype   = zeros(numopr,1);

for j=1:numopr
   i = strmatch(lower(opr(j,:)),operators);
   if isempty(i)
      error(sprintf('Unknown operator %s type encountered at opr(%f).',opr(j),j));
   else   
      oprtype(j) = i;
   end
   
   if opri(j)<0 | opri(j)>numcon 
      error(sprintf('opri(%d) has the invalid value %d.',j,opri(j)));
   end   
   
   if oprj(j)<1 | oprj(j)>numvar 
      error(sprintf('oprj(%d) has the invalid value of %d',j,oprj(j)));
   end   
end   

nl.numcon         = numcon;
nl.numvar         = numvar;
nl.oprtype        = oprtype;
nl.opri           = opri;
nl.oprj           = oprj;
nl.oprf           = oprf;
nl.oprg           = oprg;

%oprtype

nl.subent         = find(oprtype==1);
nl.subexp         = find(oprtype==2);
nl.sublog         = find(oprtype==3);
nl.subpow         = find(oprtype==4);   

%nl.subent
%nl.subexp
%nl.sublog
%nl.subpow

p                 = find(opri>0);

gosub             = unique(oprj(find(opri==0)));
gcsub             = unique(opri(p));

%gcsub'

gosub             = gosub(:);
gcsub             = gcsub(:);  

prob.nlfun.handle = nl;
prob.nlfun.getsp  = 'mskscspa';
prob.nlfun.getva  = 'mskscval'; 
prob.nlfun.grdobj = sparse(gosub,ones(size(gosub)),ones(size(gosub)),numvar,1);
prob.nlfun.conval = sparse(gcsub,ones(size(gcsub)),ones(size(gcsub)),numcon,1);
prob.nlfun.grdcon = sparse(oprj(p),opri(p),ones(size(p)),numvar,numcon);

%prob.nlfun

[rcode,res]       = mosekopt(cmd,prob,param);
res.rcode         = rcode;

% end
