###
##  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
##
##  File :      scopt1.R
##
##  Purpose :   Demonstrates how to solve a simple non-liner separable problem
##              using the SCopt interface for Rmosek. Then problem is this:
##
##              Minimize   exp(x2) - ln(x1)
##              Such that  x2 ln(x2)   <= 0
##                         x1^0.5 - x2 >= 0
##                              x1, x2 >= 0.5
##                              x1, x2 <= 1.0
##
###

sco1 <- list(sense = "min")
sco1$c <- c(0,0)
sco1$A <- Matrix( c(0, 0, 
                    0,-1), nrow=2, byrow=TRUE, sparse=TRUE)

sco1$bc <- rbind(blc = c(-Inf ,  0.),
                 buc = c(   0., Inf))
sco1$bx <- rbind(blx = rep(0.5, 2),
                 bux = rep(1.0, 2))

NUMOPRO <- 2; NUMOPRC <- 2;
opro <- matrix(list(), nrow=5, ncol=NUMOPRO)
oprc <- matrix(list(), nrow=6, ncol=NUMOPRC)
rownames(opro) <- c("type","j","f","g","h")
rownames(oprc) <- c("type","i","j","f","g","h")

##                type  j     f    g    h
opro[,1] <- list("LOG", 1,  -1.0, 1.0, 0.0)
opro[,2] <- list("EXP", 2,   1.0, 1.0, 0.0)

##                type  i     j    f    g    h
oprc[,1] <- list("ENT", 1,    2, 1.0, 0.0, 0.0)
oprc[,2] <- list("POW", 2,    1, 1.0, 0.5, 0.0)

sco1$scopt <- list(opro=opro, oprc=oprc)

r <- mosek(sco1)