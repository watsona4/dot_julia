get_lo1_solution_variables <- function(maxtime) {
  lo1 <- list(sense="max", c=c(3,1,5,1))
  lo1$A <- Matrix(c(3,1,2,0,2,1,3,1,0,2,0,3), 
             nrow=3, byrow=TRUE, sparse=TRUE)
  lo1$bc <- rbind(blc=c(30,15,-Inf), buc=c(30,Inf,25));
  lo1$bx <- rbind(blx=c(0,0,0,0),    bux=c(Inf,10,Inf,Inf));
  lo1$dparam <- list(OPTIMIZER_MAX_TIME=maxtime)

  r <- try(mosek(lo1, list(verbose=0)), silent=TRUE)
  if (inherits(r, "try-error")) { 
    stop("Rmosek failed somehow!") 
  }

  if (!identical(r$response$code, 0)) { 
    cat(paste("**", "Response code:", r$response$code, "\n"))
    cat(paste("**", r$response$msg, "\n"))
    cat("Trying to continue..\n")
  }

  isdef <- try({
    rbas <- r$sol$bas;
    rbas$solsta;  rbas$prosta;  rbas$xx;  
  }, silent=TRUE)
  if (inherits(isdef, "try-error")) { 
    stop("Basic solution was incomplete!")
  }

  switch(rbas$solsta,
    OPTIMAL = {
      cat("The solution was optimal, I am happy!\n")
    },
    NEAR_OPTIMAL = {
      cat("The solution was close to optimal, very good..\n")
    },
    #OTHERWISE:
    {
      cat(paste("**", "Solution status:", rbas$solsta, "\n"))
      cat(paste("**", "Problem status:", rbas$prosta, "\n"))
      stop("Solution could not be accepted!")
    }
  )
  return(rbas$xx)
}