sdo1 <- list(sense="min")
sdo1$c     <- c(1,0,0)
sdo1$A     <- Matrix(c(1,0,0,
                       0,1,1), nrow=2, byrow=TRUE, sparse=TRUE)
sdo1$bc    <- rBind(blc = c(1, 0.5), buc = c(1, 0.5))
sdo1$bx    <- rBind(blx = rep(-Inf,3), bux = rep(Inf,3))
sdo1$cones <- cBind(list("quad", c(1,2,3)))

# One semidefinite matrix variable size 3x3:
N <- 3
sdo1$bardim <- c(N)

# Block triplet format specifying the lower triangular part 
# of the symmetric coefficient matrix 'barc':
sdo1$barc$j <- c(1, 1, 1, 1, 1)
sdo1$barc$k <- c(1, 2, 3, 2, 3)
sdo1$barc$l <- c(1, 2, 3, 1, 2)
sdo1$barc$v <- c(2, 2, 2, 1, 1)

# Block triplet format specifying the lower triangular part 
# of the symmetric coefficient matrix 'barA':
sdo1$barA$i <- c(1, 1, 1, 2, 2, 2, 2, 2, 2)
sdo1$barA$j <- c(1, 1, 1, 1, 1, 1, 1, 1, 1)
sdo1$barA$k <- c(1, 2, 3, 1, 2, 3, 2, 3, 3)
sdo1$barA$l <- c(1, 2, 3, 1, 2, 3, 1, 1, 2)
sdo1$barA$v <- c(1, 1, 1, 1, 1, 1, 1, 1, 1)

r <- mosek(sdo1)
barx   <- 1.0 * bandSparse(N, k=0:(1-N), symm=TRUE)
barx@x <- r$sol$itr$barx[[1]]