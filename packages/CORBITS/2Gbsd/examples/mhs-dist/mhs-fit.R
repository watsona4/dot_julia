require(ADGofTest)
require(psych)

files <- c("../../data/mhs_all_hist_r.txt",
           "../../data/mhs_snr_hist_r.txt",
	   "../../data/mhs_adj_hist_r.txt")

output <- c("../../data/mhs_all_stat.txt",
            "../../data/mhs_snr_stat.txt",
	    "../../data/mhs_adj_stat.txt")

mu.steps <- 200
sd.steps <- 200
list.len <- 1000
epsilon <- 1e-9

o = 0
for (file in files) {
    o = o + 1
    mhs.data <- read.table (file)
    mhs.data[, 2] <- mhs.data[, 2] / sum(mhs.data[, 2])

    mu.lo <- mean(mhs.data[, 1]) * .9
    mu.hi <- mean(mhs.data[, 1]) * 1.1
    mu.step <- (mu.hi - mu.lo) / mu.steps
    
    sd.lo <- sd(mhs.data[, 1]) * .9
    sd.hi <- sd(mhs.data[, 1]) * 1.1
    sd.step <- (sd.hi - sd.lo) / sd.steps

    mhs.list <- c()
    for (koi in 1:nrow(mhs.data)) {
    	for (i in 1:(list.len * mhs.data[koi, 2])) {
	    ## add epsilon so that Anderson-Darling test works
	    mhs.list <- c(mhs.list, mhs.data[koi, 1] + epsilon * rnorm(1))
	}
    }
    ## print(describe(mhs.list))
    ## print(str(ad.test(mhs.list, pnorm, mean(mhs.list), sd(mhs.list))))
    stat.best = Inf
    mu.best = mu.lo
    sd.best = sd.lo

    for (i in 0:mu.steps) {
    	for (j in 0:sd.steps) {
	    mu.cur <- mu.lo + i * mu.step
	    sd.cur <- sd.lo + j * sd.step
	    # print (c(mu.cur, sd.cur))
	    mhs.stat <- ad.test(mhs.list, pnorm, mu.cur, sd.cur)
	    if (mhs.stat$statistic < stat.best) {
	       stat.best = mhs.stat$statistic
	       mu.best = mu.cur
	       sd.best = sd.cur
	    }
	}
    }

    print (paste0(as.character(file), ": (",
    	  as.character(mu.best), ", ",
	  as.character(sd.best), ") ",
    	  as.character(stat.best)))

    sink(output[o])
    cat(as.character(mu.best))
    cat("\n")
    cat(as.character(sd.best))
    cat("\n")
    sink()
}
