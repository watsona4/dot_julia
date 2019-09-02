function  [res] = mskscwri(filename,opr,opri,oprj,oprf,oprg,c,a,blc,buc,blx,bux,param,cmd)
%
% Syntax : mskscwri(filename,opr,opri,oprj,oprf,oprg,c,a,blc,buc,blx,bux,param,cmd)
%
% Purpose: Write an scopt problem to the files filename.sco and filename.mps
%

%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

display nargin

prob   = [];  
prob.c = c;
if issparse(a)
   prob.a = a;
else
   prob.a = sparse(a);
end

if nargin>8
   prob.blc = blc;
end

if nargin>9
   prob.buc = buc;
end

if nargin>10
   prob.blx = blx;
end   

if nargin>11
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

fprintf('Number of constraints: %d\n',numcon);
fprintf('Number of variables  : %d\n',numvar);

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
      error(sprintf('opri(%d) has invalid value.',j));
   end   
   
   if oprj(j)<1 | oprj(j)>numvar 
      error(sprintf('oprj(%d) has invalid value of %d',j,oprj(j)));
   end   
end   

nl_fname  = sprintf('%s.sco',filename);
lin_fname = sprintf('%s.mps',filename);

command   = sprintf('%s%s%s','echo(10) write(',lin_fname,')');

param.MSK_IPAR_WRITE_FREE_CON = 'MSK_ON'
[r,res]   = mosekopt(command,prob,param);

fid_nl    = fopen(nl_fname,'W');

objindex  = find(opri==0);
conindex  = find(opri~=0);

opro      = opr(objindex,:); 
oprjo     = oprj(objindex);
oprfo     = oprf(objindex);
oprgo     = oprg(objindex);

oprc      = opr(conindex,:);
opric     = opri(conindex);
oprjc     = oprj(conindex);
oprfc     = oprf(conindex);
oprgc     = oprg(conindex);

[n,m]     = size(opro);
fprintf(fid_nl,'%d\n',n);

for i=1:n
  if strcmp(opro(i,:),'ent')
    transopr = 0;
    transoprg = 1.0;
  elseif strcmp(opro(i,:),'exp')
    transopr = 1;
    transoprg = oprgo(i);
  elseif strcmp(opro(i,:),'log')
    transopr = 2;
    transoprg = 1.0;
  elseif strcmp(opro(i,:),'pow')
    transopr = 3;
    transoprg = oprgo(i);
  else
    error('Unknown objective type')
  end
  fprintf(fid_nl,'%-8d %-8d %-24.16e %-24.16e %-24.16e\n',transopr,oprjo(i)-1,oprfo(i),transoprg,0.0);
end

[n,m]  = size(oprc);
fprintf(fid_nl,'%d\n',n);

for i=1:n
  if strcmp(oprc(i,:),'ent')
    transopr = 0;
    transoprg = 1.0;
  elseif strcmp(oprc(i,:),'exp')
    transopr = 1;
    transoprg = oprgc(i);
  elseif strcmp(oprc(i,:),'log')
    transopr = 2;
    transoprg = 1.0;
  elseif strcmp(oprc(i,:),'pow')
    transopr = 3;
    transoprg = oprgc(i);
  else
    error('Unknown objective type')
  end
  fprintf(fid_nl,'%-8d %-8d %-8d %-24.16e %-24.16e %-24.16e\n',transopr,opric(i)-1,oprjc(i)-1,oprfc(i),transoprg,0.0);
end

fclose (fid_nl);

res = 0;


