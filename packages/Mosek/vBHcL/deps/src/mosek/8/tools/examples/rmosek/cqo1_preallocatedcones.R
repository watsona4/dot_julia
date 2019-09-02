NUMCONES <- 2
cqo1$cones <- matrix(list(), nrow=2, ncol=NUMCONES)
  rownames(cqo1$cones) <- c("type","sub")
cqo1$cones[,1] <- list("QUAD", c(5,1,3))
cqo1$cones[,2] <- list("QUAD", c(6,2,4))