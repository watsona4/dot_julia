function [ret] = mskgpval(nlh,what,whichi,x,yo,yc)
% Syntax :  Do not use this function.
%
% Purpose: Is used by mskgpopt to compute the value for
%          the nonlinear functions.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

m              = nlh.m;
n              = nlh.n;
t              = nlh.t; 

ret.rcode      = 0;

sumx           = (x'*nlh.hesout)';
tmp            = ones(m,1);
tmp(nlh.subi)  = 0.0;
temp           = sumx+tmp; 
logtemp        = log(temp);

%x(nlh.subt)    = max(x(nlh.subt),eps); 

%what 
%fprintf('x:');
%x'



if ~isempty(findstr(what,'objval'))
  %temp'
  %logtemp' 
  ret.objval = x(nlh.subt)'*log(x(nlh.subt)) - temp'*logtemp;
end

if ~isempty(findstr(what,'grdobj')) | ~isempty(findstr(what,'grdlag'))
  v                = nlh.hesout*sumx;
  v                = v(nlh.subc);
  tmp              = v./x(nlh.subc);
  grdobj           = zeros(size(x));
  grdobj(nlh.sub0) = 1.0+log(x(nlh.sub0)); 
  grdobj(nlh.subc) = -log(tmp); 
end


if ~isempty(findstr(what,'grdobj')) 
  %ret.grdobj           = -nlh.hesout*(1.0+logtemp);
  %ret.grdobj(nlh.subt) = ret.grdobj(nlh.subt)+1.0+log(x(nlh.subt));

  ret.grdobj            = grdobj;
  
  %fprintf('grdobj:\n');
  %ret.grdobj'
end

if ~isempty(findstr(what,'conval'))
  ret.conval = sparse(length(whichi),1);
end

if ~isempty(findstr(what,'grdcon'))
  ret.grdcon = sparse(n,length(whichi));
end

if ~isempty(findstr(what,'grdlag'))
   if yo==0.0
     ret.grdlag = sparse(t,1);
   else 
     %ret.grdlag           = -nlh.hesout*(1.0+logtemp);
     %ret.grdlag(nlh.subt) = yo*(ret.grdlag(nlh.subt)+1.0+log(x(nlh.subt)));

     ret.grdlag           = yo.*grdobj; 
   end
end
 
if ~isempty(findstr(what,'hes'))
  if yo==0.0
    ret.hes = sparse(t,t);
  else
    v        = nlh.hesout*sumx;   
    
    v        = v(nlh.subc); 
    diagi    = [nlh.sub0;nlh.subc];
    
    %yo./x(nlh.sub0)
    %(v-x(nlh.subc))
    %(v.*x(nlh.subc))
    diagv    = [yo./x(nlh.sub0);(yo*(v-x(nlh.subc)))./(v.*x(nlh.subc))];
    
    %min(diagv)
    ret.hes  = sparse(diagi,diagi,diagv,t,t)...
               -tril(nlh.hesout*(sparse(1:m,1:m,yo./temp)*nlh.hesout'),-1);
   
    %ret.hes = sparse(nlh.subt,nlh.subt,yo./x(nlh.subt),t,t)...
    %          - tril(nlh.hesout*(sparse(1:m,1:m,yo./temp)*nlh.hesout')); 
    
  end
end 

%ret
%fprintf('done\n');
%ret
%nnz(ret.hes)
