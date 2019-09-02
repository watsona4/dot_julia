function [c,a,map] = mskgpread (filename)
% Syntax : [c,a,map] = mskgpread (filename)
%
% Purpose: Read a GP problem from the file name 'filename' using
%          the format specified in mskgpwri.m.  
%           
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

fid = fopen (filename, 'r');
 
if fid < 0
  error ('Could not open file "%s" for reading', filename);
end

readdata = textscan(fid, '%f', 3, ...
             'commentStyle', '*', ...
             'whiteSpace',   ' \n\t');
numcon = readdata{1}(1);
numvar = readdata{1}(2);
numter = readdata{1}(3);
 
readdata = textscan(fid, '%f', numter, ...
             'commentStyle', '*',...
             'whiteSpace',   ' \n\t');

c = readdata{1};

readdata = textscan(fid, '%f', numter, ...
             'commentStyle', '*',...
             'whiteSpace',   ' \n\t');

map = readdata{1};

readdata = textscan(fid, '%f %f %f', ...
             'commentStyle', '*',...
             'whiteSpace',   ' \n\t');

fclose (fid);

numanz = size(readdata{1},1);
idxj = readdata{1} + ones(numanz,1);
idxk = readdata{2} + ones(numanz,1);

a = sparse (idxj,idxk,readdata{3});

m = numcon;
n = numvar;
L = numter;
