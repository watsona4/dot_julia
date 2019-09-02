function mskgpwri(c,a,map,filename)
% Syntax : mskgpwri(c,a,map,filename)
%
% Purpose: Write a GP problem specified by c, a and map 
%          to a file named 'filename'.
%

%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

[numter,numvar] = size(a);

f = fopen(filename,'w');

if f < 0
  error ('Could not open file "%s" for writing', filename);
end

numcon = max(map); 

fprintf(f,'%d\n',numcon);
fprintf(f,'%d\n',numvar);
fprintf(f,'%d\n',numter);

for i=1:length(c)
  fprintf(f,'%.20e\n',c(i));
end

for i=1:length(map)
  fprintf(f,'%d\n',map(i));
end

at = a';

k=0;
for i=1:numter
  [sub,tmp,val] = find(at(:,i));  
  for j=1:length(val)
      fprintf(f,'%d %d %.20e\n',k,sub(j)-1,val(j));
  end
  k = k + 1;
end

fclose(f);

  
