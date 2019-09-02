cqo1 <- list(sense = "min")
cqo1$c <- c(0,0,0,1,1,1)
cqo1$A <- Matrix(c(1,1,2,0,0,0), 
                 nrow=1, byrow=TRUE, sparse=TRUE)
cqo1$bc <- rbind(blc = 1, buc = 1)
cqo1$bx <- rbind(blx = c(0,0,0,-Inf,-Inf,-Inf),
                 bux = rep(Inf,6))
cqo1$cones <- cbind(
  list("QUAD", c(4,1,2)),
  list("RQUAD", c(5,6,3))
)
rownames(cqo1$cones) <- c("type","sub");
r <- mosek(cqo1)