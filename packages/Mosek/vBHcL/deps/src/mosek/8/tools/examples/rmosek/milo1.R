milo1 <- list(sense = "max")
milo1$c <- c(1, 0.64)
milo1$A <- Matrix(c( 50, 31 ,
                      3, -2 ),
                  nrow  = 2, 
                  byrow = TRUE, 
                  sparse= TRUE)
milo1$bc <- 
  rbind(blc = c(-Inf,-4),
        buc = c(250,Inf))
milo1$bx <- 
  rbind(blx = c(0,0),
        bux = c(Inf,Inf))
milo1$intsub <- c(1,2)
r <- mosek(milo1)