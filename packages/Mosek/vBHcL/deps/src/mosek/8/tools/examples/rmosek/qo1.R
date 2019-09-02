qo1 <- list()
qo1$sense <- "min"
qo1$c <- c(0,-1,0)
qo1$A <- Matrix(c(1,1,1), nrow=1, byrow=TRUE, sparse=TRUE)
qo1$bc <- rbind(blc = 1, 
                buc = Inf) 
qo1$bx <- rbind(blx = rep(0,3), 
                bux = rep(Inf,3))

qo1$qobj <- list(i = c(1,  3,   2, 3),
                 j = c(1,  1,   2, 3),
                 v = c(2, -1, 0.2, 2))

r <- mosek(qo1)