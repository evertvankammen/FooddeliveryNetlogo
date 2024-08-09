import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn.objects as so

np.random.seed(22)
x_data = np.random.uniform(low = 0, high = 100, size = 100)
np.random.seed(22)
np.random.normal(size = 50)
y_data = x_data + np.random.normal(size = 100, loc = 0, scale = 10)

point_data = pd.DataFrame({'x_var':x_data

                          ,'y_var':y_data

                          })

x = (so.Plot(data = point_data

         ,x = 'x_var'

         ,y = 'y_var'

         )

    .add(so.Dot())

)

x.save("a.png")

