# produces kde of various period ratio distributions
# requires matplotlib

import numpy as np
import matplotlib.pyplot as plt
import pylab as P
from scipy.stats import gaussian_kde

def parse_list(line):
    return [float(x) for x in line.split(" ")]

fig = plt.figure()

kde_name = ["adj", "snr", "all"];
kde_title = {"adj":"Geometrically Debiased MHS Distribution",\
            "snr":"SNR and Impact Parameter Cut MHS Distribution",\
            "all":"MHS Distribution"\
}
kde_color = {"adj":"green",\
            "snr":"blue",\
            "all":"red"\
}
data_dir = "../../data/"

for name in kde_name:
    # start of kde
    ax = fig.add_subplot(111)
    fdata = open(data_dir + "mhs_" + name + '_hist_py.txt', 'r')
    fstat = open(data_dir + "mhs_" + name + "_stat.txt", 'r')
    
    # period ratios
    x = parse_list(fdata.readline());
    
    # weight of each period ratio
    w = parse_list(fdata.readline());
    
    # discretized size
    size = 10000
    
    # plot kde
    # n, bins, patches = P.kde(x, b, range = (0, 60), weights = w, facecolor = kde_color[name], kdetype='barstacked', stacked=True)
    
    period_ratio_data = list()
    for i in range(len(x)):
        period_ratio_data += [x[i]] * int(w[i] * size)

    # adapted from http://stackoverflow.com/questions/4150171/how-to-create-a-density-plot-in-matplotlib 
    period_ratio_density = gaussian_kde(period_ratio_data)
    period_ratio_density.covariance_factor = lambda : .05
    period_ratio_density._compute_covariance()
    bins = np.linspace(0, 60, 1200)
    y = period_ratio_density(bins)
    ax.plot(bins, y, color = kde_color[name])
    ax.fill_between(bins, y, color = kde_color[name])

    ax.set_xlabel('Mutual Hill Sphere Distance')
    ax.set_ylabel('Density')
    # ax.set_title(kde_title[name])

    P.ylim([0, .06])
    P.xlim([0, 60])

    # read mu and sd
    mu = float(fstat.readline())
    sd = float(fstat.readline())

    # plot best-fit distribution
    tot = 0
    for i in range (0, len (x) - 1):
        if x[i] <= 100:
            tot += w[i]
    y = list (map (lambda x: (1/(sd * np.sqrt (2 * np.pi))) * \
        np.exp(-(x - mu)**2 / (2 * sd ** 2)) * tot, bins))
    l = P.plot (bins, y, 'k--', linewidth=1.5)

    fdata.close()
    fstat.close()

    fig.savefig(data_dir + "mhs_" + name + "_kde.eps", format="eps")

    fig.clear()
# end of kde
