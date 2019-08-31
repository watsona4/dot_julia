# produces histograms of various period ratio distributions
# requires matplotlib

import numpy as np
import matplotlib.pyplot as plt
import pylab as P

def parse_list(line):
    return [float(x) for x in line.split(" ")]

fig = plt.figure()

# key resonances
res = [[1.5, '3:2'], [2, '2:1'], [2.5, '5:2'], [3, '3:1'], [7/3.0, '7:3'], [8/3.0, '8:3'], [5/3.0, '5:3'], [4/3.0, '4:3']]

hist_name=["adj", "snr", "all"];
hist_title={"adj":"Geometrically Debiased Resonance Distribution",\
            "snr":"SNR and Impact Parameter Cut Resonance Distribution",\
            "all":"Resonance Distribution"\
}
hist_color={"adj":"green",\
            "snr":"blue",\
            "all":"red"\
}
data_dir = "../../data/"

for name in hist_name:
    # start of histogram
    ax = fig.add_subplot(111)
    fdata = open(data_dir + "per_" + name + '_hist_py.txt', 'r')
    fstat= open(data_dir + "per_" + name + "_stat.txt", 'r')
    
    # period ratios
    x = parse_list(fdata.readline());
    
    # weight of each period ratio
    w = parse_list(fdata.readline());
    
    # number of bins
    b = 30
    
    # plot histogram
    n, bins, patches = P.hist(x, b, range = (1, 4), weights = w, facecolor = hist_color[name], histtype='barstacked', stacked=True)
    ax.set_xlabel('Period Ratio')
    ax.set_ylabel('Frequency')
#    ax.set_title(hist_title[name])
    
    # plot resonance values
    for p in res:
        ax.axvline (x = p[0], ls = 'dashed', color = 'black')
        ax.text (p[0], .0775, p[1], ha='center', color = hist_color[name])

    P.ylim([0, .08])

    # read mu and sd
    mu = float(fstat.readline())
    sd = float(fstat.readline())

    # plot best-fit distribution
    tot = 0
    for i in range (0, len (x) - 1):
        if x[i] <= 4:
            tot += w[i]

    y = list (map (lambda x: (1/(x * sd * np.sqrt (2 * np.pi))) * np.exp(-(np.log(x) - mu)**2 / (2 * sd ** 2))/10 * tot, bins))
    l = P.plot (bins, y, 'k--', linewidth=1.5)

    # output figure and close files
    fdata.close()
    fstat.close()

    fig.savefig(data_dir + "per_" + name + "_hist.eps", format="eps")

    fig.clear()
# end of histogram
