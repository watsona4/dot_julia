# see http://matplotlib.org/users/pyplot_tutorial.html
# https://docs.python.org/2/library/csv.html

import numpy as np
import matplotlib.pyplot as plt
import csv

fig = plt.figure()

csv_data = open('kepler_90_b.csv')
data_reader = csv.reader(csv_data)

x_data = np.arange(0, 21, 1) * .1
print(len(x_data))
y_data = list()
for row in data_reader:
    y_data.append(row[1:])
    print(len(y_data[0]))

ax = fig.add_subplot(111)
ax.set_xlabel('Mean Mutual Inclination (degrees)')
ax.set_ylabel('Expected Number of Systems')

ax.set_yscale('log')

color = ['blue', 'green', 'red', 'purple', 'orange', 'teal', 'brown', 'magenta']
param = ['o-', '^-', 's-', 'p-', '*-', 'x-', 'D-', 'h-']

for i in range(0, 8):
    for j in range(0, 21):
        y_data[i][j] = float(y_data[i][j]) / float(y_data[7][j])
    ax.plot(x_data, y_data[i], param[i], label=str(i), color = color[i])

ax.legend()

plt.savefig('kepler-90-expected-transit.eps', format='eps')
