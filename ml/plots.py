import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import axes3d

x = [1, 2, 3, 4, 5, 6, 7, 8, 9]
y1 = [1, 3, 5, 3, 1, 3, 5, 3, 1]
y2 = [2, 4, 6, 4, 2, 4, 6, 4, 2]
plt.plot(x, y1, label="Line L")
plt.plot(x, y2, label="Line H")
plt.plot()

plt.xlabel("x axis")
plt.ylabel("y axis")
plt.title("line graph example")
plt.legend()


n = np.random.randn(1000) + 5
m = [m for m in range(len(n))]
plt.bar(m, n)
plt.title("raw data")
plt.show()

plt.hist(n, bins=50)
plt.title("histogram")
plt.show()

plt.hist(n, cumulative=True, bins=50)
plt.title("cumulative histogram")
plt.show()

