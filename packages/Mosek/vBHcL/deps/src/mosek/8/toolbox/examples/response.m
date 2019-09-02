%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      response.m
%
%  Purpose:   This example demonstrates proper response handling.
%

function response(inputfile, solfile)


  cmd      = sprintf('read(%s)', inputfile)
  % Read the problem from file
  [r, res] = mosekopt(cmd)
  
  if strcmp( res.rcodestr , 'MSK_RES_OK')

      % Perform the optimization.
      [r,res] = mosekopt('minimize', res.prob); 
      r
      res
      %Expected result: The solution status of the basic solution is optimal.
      if strcmp(res.rcodestr, 'MSK_RES_OK')
      
          solsta = strcat('MSK_SOL_STA_', res.sol.itr.solsta)

          if strcmp( solsta , 'MSK_SOL_STA_OPTIMAL') || ...
             strcmp( solsta , 'MSK_SOL_STA_NEAR_OPTIMAL')

              fprintf('An optimal basic solution is located.');
              
          elseif strcmp( solsta , 'MSK_SOL_STA_DUAL_INFEAS_CER') || ...
                 strcmp( solsta , 'MSK_SOL_STA_NEAR_DUAL_INFEAS_CER')
              fprintf('Dual infeasibility certificate found.');

          elseif strcmp( solsta , 'MSK_SOL_STA_PRIM_INFEAS_CER') || ...
                 strcmp( soslta , 'MSK_SOL_STA_NEAR_PRIM_INFEAS_CER')
            fprintf('Primal infeasibility certificate found.');

          elseif strcmp( solsta , 'MSK_SOL_STA_UNKNOWN') 
          
              % The solutions status is unknown. The termination code 
              % indicates why the optimizer terminated prematurely. 

              fprintf('The solution status is unknown.');
      
              if ~strcmp(res.rcodestr, 'MSK_RES_OK' ) 
                  
                  % A system failure e.g. out of space.
                  fprintf('  Response code: %s\n', res);  
            
              else
            
                  %No system failure e.g. an iteration limit is reached.
                  printf('  Termination code: %s\n', res);  
              end
            
          else
            fprintf('An unexpected solution status is obtained.');
          end
        
      
      else
        fprintf('Could not obtain the solution status for the requested solution.');  
    
  end

  fprintf('Return code: %d (0 means no error occurred.)\n',r);

end