require(ADGofTest)
require(psych)
set.seed(0)

files <- c("../../data/per_all_hist_r.txt",
           "../../data/per_snr_hist_r.txt",
	   "../../data/per_adj_hist_r.txt")

output <- c("../../data/per_all_stat.txt",
            "../../data/per_snr_stat.txt",
	    "../../data/per_adj_stat.txt")

mu.steps <- 200
sd.steps <- 200
list.len <- 1000
epsilon <- 1e-9

o = 0
for (file in files) {
    o = o + 1
    per.data <- read.table (file)
    ok <- (per.data[, 1] <= 4)
    per.data <- per.data[ok,]

    # per.data[, 1] <- log (per.data[, 1])
    per.data[, 2] <- per.data[, 2] / sum(per.data[, 2])

    mu.lo <- epsilon
    mu.hi <- 2
    mu.step <- (mu.hi - mu.lo) / mu.steps

    sd.lo <- epsilon
    sd.hi <- 2
    sd.step <- (sd.hi - sd.lo) / sd.steps

    per.list <- c()
    for (koi in 1:nrow(per.data)) {
    	## print(list.len * per.data[koi, 2])
    	for (i in 1:(list.len * per.data[koi, 2])) {
	    ## add epsilon so that Anderson-Darling test works
	    per.list <- c(per.list, per.data[koi, 1] + epsilon * rnorm(1))
	}
    }
    print(describe(per.list))
    ## print(str(ad.test(per.list, pnorm, mean(per.list), sd(per.list))))
    stat.best = Inf
    mu.best = mu.lo
    sd.best = sd.lo
    p.best = 0

    for (i in 0:mu.steps) {
    	for (j in 0:sd.steps) {
	    mu.cur <- mu.lo + i * mu.step
	    sd.cur <- sd.lo + j * sd.step
	    # print (c(mu.cur, sd.cur))
	    per.stat <- ad.test(per.list, plnorm, meanlog = mu.cur, sdlog = sd.cur)
	    if (per.stat$statistic < stat.best) {
	       stat.best = per.stat$statistic
	       mu.best = mu.cur
	       sd.best = sd.cur
	       p.best = per.stat$p.value
	    }
	}
    }
    # str(ad.test(per.list, plnorm, .8, .3))
    print (paste0(as.character(file), ": (",
    	  as.character(mu.best), ", ",
	  as.character(sd.best), ") ",
    	  as.character(stat.best), ", ",
	  as.character(p.best)))
    
    sink(output[o])
    cat(as.character(mu.best))
    cat("\n")
    cat(as.character(sd.best))
    cat("\n")
    sink()
}
