# see http://matplotlib.org/users/pyplot_tutorial.html
# https://docs.python.org/2/library/csv.html

import numpy as np
import matplotlib.pyplot as plt
import csv

fig = plt.figure()

csv_data = open('kepler_90.csv')
data_reader = csv.reader(csv_data)

x_data = data_reader.next()[1:]
y_data_7 = data_reader.next()[1:]
y_data_6 = data_reader.next()[1:]
y_data_8i_obs = data_reader.next()[1:]
y_data_8i7trans = data_reader.next()[1:]
y_data_8o_obs = data_reader.next()[1:]
y_data_8o7trans = data_reader.next()[1:]

ax = fig.add_subplot(111)
ax.set_xlabel('Mean Mutual Inclination (degrees)')
ax.set_ylabel('Transit Probability')

ax.set_yscale('log')

ax.plot(x_data, y_data_7, 'bp-', label='7')
ax.plot(x_data, y_data_8i_obs, 'gs-', label='8i_obs')
ax.plot(x_data, y_data_8i7trans, 'r^-', label='8i7trans')
ax.plot(x_data, y_data_8o_obs, 'yD-', label='8o_obs')
ax.plot(x_data, y_data_8o7trans, 'k*-', label='8o7trans')

ax.legend()

plt.savefig('kepler-90-transit-prob.eps', format='eps')
