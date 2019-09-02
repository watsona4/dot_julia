%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      callbackex.m
%
%  Purpose : An example of a callback function writing to a log file
%

clear prob;

% Specifies c vector.
prob.c = [ 1 2 0]';

% Specify a in sparse format.
subi   = [1 2 2 1];
subj   = [1 1 2 3];
valij  = [1.0 1.0 1.0 1.0];

prob.a = sparse(subi,subj,valij);

% Specify lower bounds on the constraints.
prob.blc  = [4.0 1.0]';

% Specify  upper bounds on the constraints.
prob.buc  = [6.0 inf]';

% Specify lower bounds on the variables.
prob.blx  = sparse(3,1);

% Specify upper bounds on the variables.
prob.bux = [];   % There are no bounds.


% Specify log function
callback.log       = 'myprint';
fid                = fopen('mosek.log','wt');
callback.loghandle = fid;

% Specify iter function

% Define user defined handle.
[r,res]             = mosekopt('echo(0) symbcon');                 
data.maxtime        = 100.0;
data.symbcon        = res.symbcon;

callback.iter       = 'myiter';
callback.iterhandle = data;

% Perform the optimization.
[r,res] = mosekopt('minimize',prob,[],callback); 

% Show the optimal x solution.
res.sol.itr.xx

fclose(fid);

% type mosek.log
