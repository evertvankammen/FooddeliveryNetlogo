import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import pynetlogo

netlogo = pynetlogo.NetLogoLink(
    gui=False,
    jvm_path="C:\\Java\\openjdk-21.0.2\\bin\\server\\jvm.dll",
)

  
def aggregates(dataframe):
    data_preproc = pd.DataFrame({
        'time': dataframe["ticks"],
        'ordered': dataframe["ordered_this_tick"].cumsum(),
        'delivered': dataframe["delivered_this_tick"].cumsum(),
        'discarded': dataframe["discarded_this_tick"].cumsum(),
    }
    )

    return pd.melt(data_preproc, ['time'])


def take2(res, cust, dels, time=60 * 24, ptime=10, wait=60):
    netlogo.load_model(".\\NetLogo\\fooddelivery.nlogo")
    netlogo.command(f"set number-of-restaurants {res}")
    netlogo.command(f"set number-of-customers {cust}")
    netlogo.command(f"set number-of-deliverers {dels}")
    netlogo.command("set order_frequency \"once a week\"")
    netlogo.command(f"set prepair_time_mean {ptime}")
    netlogo.command("set prepair_time_stdev 5")
    netlogo.command(f"set wait_for_deliverer {wait}")
    netlogo.command("setup")
    counts = netlogo.repeat_report(["ticks", "ordered_this_tick", "delivered_this_tick", "discarded_this_tick"],
                                   time, go="go")

    netlogo.kill_workspace()
    result_df = aggregates(counts)

    plot = sns.lineplot(data=result_df, x='time', y='value', hue='variable')

    plot.set(xlabel="time of day", ylabel="number of meals", title=f"number of meals r={res} c={cust}, d={dels}, p={ptime}, w={wait}")
    plt.yticks(np.arange(0, 100, step=10))
    plt.xticks(np.arange(0, 24 * 60 + 1, step=120))

    x_labels = []

    for x in plot.get_xticks():
        hour = int(x / 60)
        x_labels.append(f"{hour}")

    plot.set_xticklabels(x_labels)
    plt.show()
    fig = plot.get_figure()
    fig.savefig(f"food_ordering_distribution_{cust}_{res}_{dels}_{wait}.png")

def run1():
    take2(10,500, 10, wait=60)
    take2(10,500, 20, wait=60)
    take2(10,500, 30, wait=60)
    take2(10,500, 40, wait=60)
    take2(10,500, 50, wait=10)
    take2(10,500, 50, wait=20)
    take2(10,500, 50, wait=40)
    take2(10,500, 50, wait=60)
    take2(10,500, 50, wait=80)
    take2(10,500, 50, wait=100)
    take2(10,500, 50, wait=120)
    take2(10,500, 50, wait=60, ptime=5)
    take2(10,500, 50, wait=60, ptime=10)
    take2(10,500, 50, wait=60, ptime=15)
    take2(10,500, 50, wait=60, ptime=20)
    take2(10,500, 50, wait=60, ptime=25)
    take2(10,500, 50, wait=60, ptime=30)
    take2(10,500, 50, wait=62, ptime=35)

take2(10,500, 50, wait=30, ptime=10)