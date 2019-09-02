###
##  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
##
##  File :      solutionquality.R
##
##  Purpose :   To demonstrate how to examine the quality of a solution. 
###
lo1 <- list(sense="max", c=c(3,1,5,1))
lo1$A <- Matrix(c(3,1,2,0,2,1,3,1,0,2,0,3), 
             nrow=3, byrow=TRUE, sparse=TRUE)
lo1$bc <- rbind(blc=c(30,15,-Inf), buc=c(30,Inf,25));
lo1$bx <- rbind(blx=c(0,0,0,0),    bux=c(Inf,10,Inf,Inf));

## Note we need to obtain details of the solution to inspect primal/dual obj fun value
r <- try(mosek(lo1, list(verbose=0, soldetail=2)), silent=TRUE)

if (inherits(r, "try-error")) { 
  stop("Rmosek failed somehow!") 
}

if (!identical(r$response$code, 0)) { 
  cat(paste("**", "Response code:", r$response$code, "\n"))
  cat(paste("**", r$response$msg, "\n"))
  cat("Trying to continue..\n")
}

isdef <- try({
  itr <- r$sol$itr;
  itr$solsta;  itr$prosta;  itr$xx; itr$sol;
  }, silent=TRUE)

if (inherits(isdef, "try-error")) { 
    stop("Interior solution was incomplete!")
}

if (itr$solsta == "OPTIMAL" |
    itr$solsta == "NEAR_OPTIMAL" ) {

  cat("The solution was (near) optimal, I am happy!\n")

  pobj<- r$sol$itr$pobjval
  dobj<- r$sol$itr$dobjval

  abs_obj_gap     <- abs(dobj-pobj)
  rel_obj_gap     <- abs_obj_gap/(1.0 + min(abs(pobj),abs(dobj)))


  max_primal_viol <- max( itr$maxinfeas$pcon, itr$maxinfeas$pbound)
  max_primal_viol <- max( max_primal_viol  , itr$maxinfeas$pbarvar) 
  max_primal_viol <- max( max_primal_viol  , itr$maxinfeas$pcone) 

  max_dual_viol <- max( itr$maxinfeas$dcon, itr$maxinfeas$dbound)
  max_dual_viol <- max( max_dual_viol    , itr$maxinfeas$dbarvar) 
  max_dual_viol <- max( max_dual_viol    , itr$maxinfeas$dcone) 


  ## Assume the application needs the solution to be within
  ## 1e-6 of optimality in an absolute sense. Another approach
  ## would be looking at the relative objective gap 

  cat("\n\n")
  cat("Customized solution information.\n")
  cat("  Absolute objective gap: ",abs_obj_gap,"\n")
  cat("  Relative objective gap: ",rel_obj_gap,"\n")
  cat("  Max primal violation  : ",max_primal_viol,"\n")
  cat("  Max dual violation    : ",max_dual_viol,"\n")

  accepted<- TRUE

  if (rel_obj_gap>1e-6){
    print ("Warning: The relative objective gap is LARGE.")
    accepted <- FALSE
  }

  ## We will accept a primal infeasibility of 1e-8 and
  ## dual infeasibility of 1e-6. These number should chosen problem
  ## dependent.

  if ( max_primal_viol>1e-8) {
    print ("Warning: Primal violation is too LARGE")
    accepted <- FALSE
  }

  if ( max_dual_viol>1e-6 ) {
    print ("Warning: Dual violation is too LARGE.")
    accepted <- FALSE
  }

  if ( accepted ) {
    numvar <- task.getnumvar()
    print ("Optimal primal solution")
    print(rbas$xx)
  }

} else {
    #Print detailed information about the solution
    cat(paste("**", "Solution status:", rbas$solsta, "\n"))
    cat(paste("**", "Problem status:", rbas$prosta, "\n"))
    stop("Solution could not be accepted!")
}