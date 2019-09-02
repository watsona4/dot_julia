simple <- function( filename)
{

  r <- mosek_read(filename, list(usesol=FALSE, useparam=TRUE))

  if (identical(r$response$code, 0)) {
  
    print("Successfully read the optimization model")
    prob <- r$prob

    r <- try(mosek(prob, list(verbose=0)), silent=TRUE)
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
  }
}
