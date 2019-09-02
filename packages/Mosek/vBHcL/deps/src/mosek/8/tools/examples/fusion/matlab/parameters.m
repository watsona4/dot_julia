%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      parameters.m
%
%  Purpose :   Demonstrates a very simple example about how to set
%              parameters and read information items
%              with MOSEK Fusion
%
function parameters()
import mosek.fusion.*;

% Create the Model        
M = Model();

disp('Test MOSEK parameter get/set functions');

% Select interior-point optimizer... (parameter with symbolic string values)
M.setSolverParam('optimizer', 'intpnt');
% ... without basis identification (parameter with symbolic string values)
M.setSolverParam('intpntBasis', 'never');
% Set relative gap tolerance (double parameter)
M.setSolverParam('intpntCoTolRelGap', 1.0e-7);

% The same in a different way
M.setSolverParam('intpntCoTolRelGap', '1.0e-7');

% Incorrect value
try 
    M.setSolverParam('intpntCoTolRelGap', -1);
catch
    disp('Wrong parameter value');
end


% Define and solve an optimization problem here
% M.solve()
% After optimization: 

disp('Get MOSEK information items');

tm = M.getSolverDoubleInfo('optimizerTime');
it = M.getSolverIntInfo('intpntIter');

tm, it