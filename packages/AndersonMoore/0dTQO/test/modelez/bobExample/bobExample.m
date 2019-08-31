function res=bobExample
%template for program comparing Root cofb and oldVersion cofb
%clear all;
%provide 
%name for test pgm(must be dir name also filename without .m added)
res=0;
[ss,ww]=unix('uname');
if(length(strmatch('SunOS',ww))==0)
disp('To be successful, must run on solaris machine so that C parser works.')
disp('Tests not run.')
else
testnam='bobExample'; 
parnam='setexample';   %name for parameter file
modnam='example7';         %name for model file
%each of these file should be in a subdir of tests with name= testnam
%note, running ant substitutes actual path name for @string@ values

addpath(SPSolvePreviousVersionDir);
if(SPWindowsQ)
dirnam=[strcat(SPSolveTestDir,'bobExample\') ];
system(['erase ' dirnam '*data.m']);
system(['erase ' dirnam '*matrices.m']);
else
dirnam=[strcat(SPSolveTestDir,'bobExample/') ];
unix(['rm ' dirnam '*data.m']);
unix(['rm ' dirnam '*matrices.m']);
end

SPEraseFile([dirnam,'example7_aim_data.m' ]);

[newUsed,newInParm,newInCof,newOutParm,newRts,newCofb,newScof]=...
		SPRunOneScript(SPSolvePreviousVersionDir,dirnam,parnam,modnam);

newPgmQ=...
		and(length(findstr(newUsed,'sp_solve'))>0,...
		length(findstr(newUsed,'previousVersion'))==0);

%successful test should have last line evaluate to true value(ie 1.0 in matlab)
load 'bobBenchData';

res=SPMatrixMatchQ(newCofb,oldCofb);
end
