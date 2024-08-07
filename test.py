
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("white")
sns.set_context("talk")

import pynetlogo

netlogo = pynetlogo.NetLogoLink(
    gui=True,
    jvm_path="C:\\Java\\openjdk-21.0.2\\bin\\server\\jvm.dll",
)

netlogo.load_model("D:\\OneDrive - EvertLevert\\Bureaublad\\fooddelivery.nlogo")
netlogo.command("setup")
counts = netlogo.repeat_report(["ticks", "ordered_this_tick", "delivered_this_tick", "discarded_this_tick"], 60*24, go="go")

df = pd.DataFrame(counts)

data_preproc = pd.DataFrame({
    'time': df["ticks"],
    'ordered': df["ordered_this_tick"],
    'delivered': df["delivered_this_tick"],
    'discarded': df["discarded_this_tick"],
  }
)

dfl = pd.melt(data_preproc, ['time'])

result_df = dfl.loc[dfl['value'] != 0]


# Plot the responses for different events and regions
sns.set_style("darkgrid")
sns.set_context("paper", rc={"grid.linewidth": 0.6})

# sns.stripplot(data=result_df, x="time", y="value", hue='variable')
# plt.show()
grid = sns.FacetGrid(result_df, col="variable", col_wrap=3)
grid.map(sns.stripplot, "time")
plt.show()