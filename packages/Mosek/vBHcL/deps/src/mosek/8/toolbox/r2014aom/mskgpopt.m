function [res] = mskgpopt(c,a,map,param,cmd)
% Syntax : [res] = mskgpopt(c,a,map,param,cmd)
%
% Purpose: Solves the posynomial version of the geometric optimization problem
%          in exponential form:
%
%          min  log(sum(k \in find(map==0),c(k)*exp(a(k,:)*x))
%          st. log(sum(k \in find(map==i),c(k)*exp(a(k,:)*x)) <= 0, for k=1,...,max(map)              
%
%          It is required that c>0.0.
%
% See also: mskgpwri, mskgpread
%

%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.


%[map,full(a)]
%c
%pause

prob = [];

if nargin<4
  param = [];
end

if nargin<5
  cmd = 'minimize';
end

m     = max(map);
[t,n] = size(a);

if length(c)~=t 
  error('c is of incorrect length.');
end

if min(c)<=0.0
  error('c should be positive.');
end

if max(c) == Inf
  error('An element of c is infinite.');
end
  
if length(map)~=t
  error('map is of incorrect length.');
end  

map = map(:);
if min(map)<0
  error('map must not contain negative values.');
end

if ~issparse(a)
   a = sparse(a);
end   


if isempty(findstr(cmd,'echo(0)'))
    mina    = min(a);
    varzero = find(mina>=0.0);
    varzero = varzero(:);

    if length(varzero)>=1 
        % fprintf('Has zero variables\n');   
        % pause;
        fprintf('\nWarning(mskgpopt): The problem is badly formulated due to:\n');
   
        for p=1:length(varzero)
            fprintf('Warning(mskgpopt): Variable %d can be fixed to zero because A(:,%d)>=0.\n',varzero(p),varzero(p));
        end    
    end      

    maxa   = max(a);
    varinf = find(maxa<=0.0);
    varinf = varinf(:);

    if length(varinf)>=1 
        % fprintf('Has zero variables\n');   
        % pause;
        fprintf('\nWarning(mskgpopt): The problem is badly formulated due to:\n');
   
        for p=1:length(varinf)
            fprintf('Warning(mskgpopt): Variable %d can be fixed to infinity because A(:,%d)<=0.\n',varinf(p),varinf(p));
        end    
    end      
end 

corig           = c;  
aorig           = a;
maporig         = map;

nl.m                 = m;
nl.n                 = n;
nl.t                 = t; 

sub0                 = find(map==0); 
sub                  = find(map>0);

% Find constraints having only 1 term.
nter                 = zeros(m,1);
for i=1:t
  if map(i)~=0
    nter(map(i)) = nter(map(i)) + 1; 
  end
end

mapi                 = (nter>=2);
nl.subi              = find(mapi); 
nl.subt              = sub(mapi(map(sub))); 
nl.hesout            = sparse(nl.subt,map(nl.subt),ones(size(nl.subt)),t,m);
nl.sub0              = sub0; 
nl.subc              = nl.subt; 
nl.subt              = union(nl.subt,sub0);

%nl.subi'
%nl.subt'
%nl.hesout

prob.c               = -log(c);
prob.a               = [sparse(a');sparse(ones(size(sub0)),sub0,ones(size(sub0)),1,t)];
prob.blc             = sparse(n+1,1,1);
prob.buc             = prob.blc;
prob.blx             = sparse(t,1);
prob.bux             = []; 
prob.nlfun.handle    = nl;
prob.nlfun.getsp     = 'mskgpspa';
prob.nlfun.getva     = 'mskgpval'; 
prob.nlfun.grdobj    = sparse(nl.subt,ones(size(nl.subt)),ones(size(nl.subt)),t,1);
prob.nlfun.conval    = zeros(n+1,1);
prob.nlfun.grdcon    = sparse(t,n+1);

%full(prob.a)
%prob.blc
%prob.buc

%fprintf('calling mosekopt');
%pause

[rcode,mres]         = mosekopt(cmd,prob,param);

%full(prob.a)
%prob.blc'
%prob.buc'
%prob.blx'
%prob.bux'

%mres.sol.itr.xx'

%mres.sol.itr

res                  = mres;
res.rcode            = rcode;
res.sol              = [];
res.sol.itr.prosta   = mres.sol.itr.prosta;
res.sol.itr.solsta   = mres.sol.itr.solsta;

%
% Hacks for infeasible cases.
%

if strcmp(res.sol.itr.prosta,'DUAL_INFEASIBLE')
    res.sol.itr.prosta = 'PRIMAL_INFEASIBLE';
elseif strcmp(res.sol.itr.prosta,'PRIMAL_INFEASIBLE')
    res.sol.itr.prosta = 'DUAL_INFEASIBLE';
end

if strcmp(res.sol.itr.solsta,'OPTIMAL')
   % Do nothing 
else
    res.sol.itr.solsta = 'UNKNOWN';
end

if 0 
   %varzero'
   [nrow,ncol]             = size(aorig);

   sub                     = setdiff([1:ncol],varzero);
   sub                     = sub(:);    
   
   x                       = zeros(nrow,1);
   p                       = setdiff([1:nrow],terzero);
   x(p)                    = mres.sol.itr.xx; 
       
   %x'
  
   res.sol.itr.xx          = zeros(ncol,1);   
   res.sol.itr.xx(varzero) = -inf;
   res.sol.itr.xx(sub)     = mres.sol.itr.y(1:n);
   
   %size(corig)
   %size(aorig)
   
   v                       = corig.*exp(aorig*res.sol.itr.xx);
   group                   = sparse(1:length(maporig),maporig+1,ones(size(maporig)));
   f                       = (v'*group)';
   
   %size(group)
   %size(res.sol.itrxx)
   f'
   
   objval                  = f(1);
   
   f                       = f(2:end);   
   sub                     = find(f>0.0);
   res.sol.itr.xc          = -inf *ones(max(maporig),1);
   res.sol.itr.xc(sub)     = log(f(sub));
   res.sol.itr.y           = -x'*group;
   res.sol.itr.slc         = zeros(m,1);
   res.sol.itr.suc         = res.sol.itr.y;
   res.sol.itr.sux         = sparse(n,1);
   
   objval
   
   mul                     = zeros(size(maporig));
   for j=1:nrow
      if maporig(j)==0 
         mul(j) = v(j)/objval;
      elseif f(maporig(j))>0.0
         mul(j) = -res.sol.itr.y(maporig(j))*v(j)/log(f(maporig(j)));
      end
   end  
   res.sol.itrslx = (mul'*aorig)';
   
else
   
   v                    = c.*exp(a*mres.sol.itr.y(1:n));
   group                = sparse(1:length(map),map+1,ones(size(map)));
   f                    = (v'*group)';                   

   res.sol.itr.xx       = mres.sol.itr.y(1:n);
   res.sol.itr.xc       = log(f(2:end));
   res.sol.itr.y        = -(mres.sol.itr.xx')*group;
   res.sol.itr.y        = res.sol.itr.y(2:end); 
   res.sol.itr.slc      = zeros(m,1);
   res.sol.itr.suc      = res.sol.itr.y;
   res.sol.itr.slx      = sparse(n,1);
   res.sol.itr.sux      = sparse(n,1);

   
     
end   
               

