function [ret] = mskenval(nlh,what,whichi,x,yo,yc)
% Purpose: Is used by entopt to compute the value for
%          the nonlinear functions.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

m         = nlh.m;
n         = nlh.n;

ret.rcode = 0;

if ( ~isempty(findstr(what,'objval')) | ...
     ~isempty(findstr(what,'grdobj')) | ...
     ~isempty(findstr(what,'grdlag')) | ...
     ~isempty(findstr(what,'hes')) )
  sz    = find(x==0.0);
  x(sz) = 1.0e-16;
end 

if ~isempty(findstr(what,'objval'))
  ret.objval = full(nlh.d(nlh.grdobjsub)'*(x(nlh.grdobjsub).*log(x(nlh.grdobjsub))));
end

if ~isempty(findstr(what,'grdobj')) 
  ret.grdobj = sparse(nlh.grdobjsub,...
                      ones(length(nlh.grdobjsub),1),...
                      nlh.d(nlh.grdobjsub).*(1+log(x(nlh.grdobjsub))),...
                      n,1);
end

if ~isempty(findstr(what,'conval'))
  ret.conval = sparse(length(whichi),1);
end

if ~isempty(findstr(what,'grdcon'))
  ret.grdcon = sparse(n,length(whichi));
end

if ~isempty(findstr(what,'grdlag'))
   if yo==0.0
     ret.grdlag = sparse(n,1);
   else 
     ret.grdlag = sparse(nlh.grdobjsub,...
                         ones(length(nlh.grdobjsub),1),...
                         nlh.d(nlh.grdobjsub).*(1+log(x(nlh.grdobjsub))),...
                         n,1);
   end
end
 
if ~isempty(findstr(what,'hes'))
  if yo==0.0
    ret.hes = sparse(n,n);
  else
    ret.hes = sparse(nlh.grdobjsub,...
                     nlh.grdobjsub,... 
                     nlh.d(nlh.grdobjsub)./x(nlh.grdobjsub),...
                     n,n); 
  end
end 
