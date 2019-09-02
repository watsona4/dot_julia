function [ret] = mskscval(nlh,what,whichi,x,yo,yc)
% Purpose: Is used by mskscopt to compute the value for
%          the nonlinear functions.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

ret.rcode = 0;

numcon    = nlh.numcon;
numvar    = nlh.numvar;

evali = whichi;
if ~isempty(findstr(what,'objval')) | ( ~isempty(findstr(what,'grdlag')) & yo~=0.0 )
  evali = [evali;0];
end

mapi          = zeros(numcon+1,1);
mapi(evali+1) = 1;
mapt          = mapi(1+nlh.opri);

if ~isempty(findstr(what,'objval')) | ~isempty(findstr(what,'conval'))
   fval = zeros(size(nlh.opri));
else
   fval = [];
end

if ~isempty(findstr(what,'grdobj')) | ~isempty(findstr(what,'grdcon')) | ~isempty(findstr(what,'grdlag'))    
   gval = zeros(size(nlh.opri));
else
   gval = [];
end

if ~isempty(findstr(what,'hes'))     
   hval = zeros(size(nlh.opri));
else
   hval = [];
end

% Entropy

sub = nlh.subent(find(mapt(nlh.subent)));
if ~isempty(sub)
  xsub = x(nlh.oprj(sub)); 

  if ~isempty(fval)
     fval(sub) = fval(sub) + nlh.oprf(sub).*log(xsub).*xsub;
  end   
  
  if ~isempty(gval)
     gval(sub) = gval(sub) + nlh.oprf(sub).*(log(xsub)+ones(size(xsub)));
  end
  
  if ~isempty(hval)
     hval(sub) = hval(sub) + nlh.oprf(sub)./xsub;
  end 
end  

% Exponential

sub = nlh.subexp(find(mapt(nlh.subexp)));
if ~isempty(sub)
  xsub = x(nlh.oprj(sub)); 
  if ~isempty(fval)
     fval(sub) = fval(sub) + nlh.oprf(sub).*exp(nlh.oprg(sub).*xsub);
  end   
  
  if ~isempty(gval)
     gval(sub) = gval(sub) + nlh.oprf(sub).*nlh.oprg(sub).*exp(nlh.oprg(sub).*xsub);
  end
  
  if ~isempty(hval)
     hval(sub) = hval(sub) +nlh.oprf(sub).*nlh.oprg(sub).*nlh.oprg(sub).*exp(nlh.oprg(sub).*xsub) ;
  end 
end  

% Logarithm

sub = nlh.sublog(find(mapt(nlh.sublog)));
%nlh.sublog
%fprintf('sub log\n');
%sub
if ~isempty(sub)
  xsub = x(nlh.oprj(sub)); 
  if ~isempty(fval)
     fval(sub) = fval(sub) + nlh.oprf(sub).*log(xsub);
  end   
  
  if ~isempty(gval)
     gval(sub) = gval(sub) + nlh.oprf(sub)./xsub;
  %   sub
  %   gval(sub)
  %   pause
  end
  
  if ~isempty(hval)
     hval(sub) = hval(sub) - nlh.oprf(sub)./(xsub.*xsub);
  end 
end  

% Power

sub = nlh.subpow(find(mapt(nlh.subpow)));
if ~isempty(sub)
  xsub = x(nlh.oprj(sub)); 
  if ~isempty(fval)
     fval(sub) = fval(sub) + nlh.oprf(sub).*xsub.^nlh.oprg(sub);
  end   
  
  if ~isempty(gval)
     gval(sub) = gval(sub) + nlh.oprf(sub).*nlh.oprg(sub).*xsub.^(nlh.oprg(sub)-1);
  end
  
  if ~isempty(hval)
     hval(sub) = hval(sub) + nlh.oprf(sub).*nlh.oprg(sub).*(nlh.oprg(sub)-1).*xsub.^(nlh.oprg(sub)-2);
  end 
end  

if ~isempty(findstr(what,'objval')) | ~isempty(findstr(what,'grdobj')) 
   objsub = find(nlh.opri==0);

   if ~isempty(findstr(what,'objval'))
      ret.objval = sum(fval(objsub));
   end

   if ~isempty(findstr(what,'grdobj')) 
      ret.grdobj = sparse(nlh.oprj(objsub),...
                          ones(size(objsub)),...
                          gval(objsub),...
                          numvar,1);
   end
end              

if ~isempty(findstr(what,'conval')) | ~isempty(findstr(what,'grdcon'))
   invi           = zeros(numcon+1,1);
   invi(whichi+1) = 1:length(whichi); 
   subt           = find(invi(nlh.opri+1));
   invi           = invi(2:end);

   if ~isempty(findstr(what,'conval'))
      ret.conval = sparse(invi(nlh.opri(subt)),...
                          ones(size(subt)),...
                          fval(subt),... 
                          length(whichi),1);
   end

   if ~isempty(findstr(what,'grdcon'))
      ret.grdcon = sparse(nlh.oprj(subt),...
                          invi(nlh.opri(subt)),...
                          gval(subt),...
                          numvar,length(whichi));

     % ret.grdcon                        
   end                    
end

if ~isempty(findstr(what,'grdlag')) | ~isempty(findstr(what,'hes'))
   y  = [yo;-yc(:)];
   
   % y
   
   if ~isempty(findstr(what,'grdlag'))
      ret.grdlag = sparse(nlh.oprj,...
                          ones(size(nlh.oprj)),...
                          y(1+nlh.opri).*gval,...
                          numvar,1);
      
      %y'
      %x'
      %ret.grdlag
      %pause;
   end   
                    
   if ~isempty(findstr(what,'hes'))
     ret.hes = sparse(nlh.oprj,...
                      nlh.oprj,...
                      y(1+nlh.opri).*hval,...
                      numvar,numvar);
   end 
end               

