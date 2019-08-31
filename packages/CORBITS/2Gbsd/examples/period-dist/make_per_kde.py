# produces kde of various period ratio distributions
# requires matplotlib

import numpy as np
import matplotlib.pyplot as plt
import pylab as P
from scipy.stats import gaussian_kde

def parse_list(line):
    return [float(x) for x in line.split(" ")]

fig = plt.figure()

# key resonances
res = [[1.5, '3:2'], [2, '2:1'], [2.5, '5:2'], [3, '3:1'], [7/3.0, '7:3'], [8/3.0, '8:3'], [5/3.0, '5:3'], [4/3.0, '4:3']]

kde_name=["adj", "snr", "all"];
kde_title={"adj":"Geometrically Debiased Resonance Distribution",\
            "snr":"SNR and Impact Parameter Cut Resonance Distribution",\
            "all":"Resonance Distribution"\
}
kde_color={"adj":"green",\
            "snr":"blue",\
            "all":"red"\
}
data_dir = "../../data/"

for name in kde_name:
    # start of kde
    ax = fig.add_subplot(111)
    fdata = open(data_dir + "per_" + name + '_hist_py.txt', 'r')
    fstat= open(data_dir + "per_" + name + "_stat.txt", 'r')
    
    # period ratios
    x = parse_list(fdata.readline());

    # weight of each period ratio
    w = parse_list(fdata.readline());
    
    # discretized size
    size = 10000

    # plot histogram
    # n, bins, patches = P.hist(x, b, range = (1, 4), weights = w, facecolor = hist_color[name], histtype='barstacked', stacked=True)
    
    period_ratio_data = list()
    for i in range(len(x)):
        period_ratio_data += [x[i]] * int(w[i] * size)

    # adapted from http://stackoverflow.com/questions/4150171/how-to-create-a-density-plot-in-matplotlib
    period_ratio_density = gaussian_kde(period_ratio_data)
    period_ratio_density.covariance_factor = lambda : .003
    period_ratio_density._compute_covariance()
    bins = np.linspace(1, 4, 1200)
    y = period_ratio_density(bins)
    ax.plot(bins, y, color = kde_color[name])
    ax.fill_between(bins, y, color = kde_color[name])

    ax.set_xlabel('Period Ratio')
    ax.set_ylabel('Density')
    # ax.set_title(kde_title[name])
    
    # plot resonance values
    for p in res:
        ax.axvline (x = p[0], ls = 'dashed', color = 'black')
        ax.text (p[0], .965, p[1], ha='center', color = kde_color[name])

    P.ylim([0, 1])

    # read mu and sd
    mu = float(fstat.readline())
    sd = float(fstat.readline())

    # plot best-fit distribution
    tot = 0
    for i in range (0, len (x) - 1):
        if x[i] <= 4:
            tot += w[i]

    y = list (map (lambda x: (1/(x * sd * np.sqrt (2 * np.pi))) * np.exp(-(np.log(x) - mu)**2 / (2 * sd ** 2)) * tot, bins))
    l = P.plot (bins, y, 'k--', linewidth=1.5)

    # output figure and close files
    fdata.close()
    fstat.close()

    fig.savefig(data_dir + "per_" + name + "_kde.eps", format="eps")

    fig.clear()
# end of kde
