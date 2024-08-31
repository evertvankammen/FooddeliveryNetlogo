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


def day(nr_restaurants=10, max_nr_customers=500, nr_deliverers=15, preparation_mean_time=15,
        wait_time_for_deliverer=30, distribution_method="equally_distributed", filename_extra="",
        deliverers_may_quit="false", radius_allowed=32

        ):
    netlogo.load_model(".\\NetLogo\\fooddelivery.nlogo")
    netlogo.command(f"set number-of-restaurants {nr_restaurants}")
    netlogo.command(f"set number-of-customers {max_nr_customers}")
    netlogo.command(f"set number-of-deliverers {nr_deliverers}")
    netlogo.command(f"set prepair_time_mean {preparation_mean_time}")
    netlogo.command("set prepair_time_stdev 5")
    netlogo.command(f"set wait_for_deliverer {wait_time_for_deliverer}")
    netlogo.command(f"set distribution_method \"{distribution_method}\"")
    netlogo.command(f"set deliverers_may_quit \"{deliverers_may_quit}\"")
    netlogo.command(f"set radius_allowed \"{radius_allowed}\"")
    netlogo.command("setup")
    counts = netlogo.repeat_report(["ticks", "ordered_this_tick", "delivered_this_tick", "discarded_this_tick"],
                                   60 * 24, go="go")

    netlogo.kill_workspace()
    result_df = aggregates(counts)

    plot = sns.lineplot(data=result_df, x='time', y='value', hue='variable')

    plot.set(xlabel="day", ylabel="number of meals",
             title=f"number of meals r={nr_restaurants} c={max_nr_customers}, d={nr_deliverers}, p={preparation_mean_time}, w={wait_time_for_deliverer}")

    plt.yticks(np.arange(0, 90, step=10))
    plt.xticks(np.arange(0, 24 * 60 + 1, step=120))

    x_labels = []

    for x in plot.get_xticks():
        hour = int((x / 60))
        x_labels.append(f"{hour}")

    plot.set_xticklabels(x_labels)
    plt.show()
    fig = plot.get_figure()
    fig.savefig(
        f"day_{filename_extra}food_ordering_distribution_{max_nr_customers}_{nr_restaurants}_{nr_deliverers}_{wait_time_for_deliverer}.png")


def week(nr_restaurants=10, max_nr_customers=500, nr_deliverers=15, preparation_mean_time=15,
         wait_time_for_deliverer=30, distribution_method="equally_distributed", filename_extra=""
         , deliverers_may_quit="false", radius_allowed=64
         ):
    netlogo.load_model(".\\NetLogo\\fooddelivery.nlogo")
    netlogo.command(f"set number-of-restaurants {nr_restaurants}")
    netlogo.command(f"set max-number-of-customers {max_nr_customers}")
    netlogo.command(f"set number-of-deliverers {nr_deliverers}")
    netlogo.command(f"set prepair_time_mean {preparation_mean_time}")
    netlogo.command("set prepair_time_stdev 5")
    netlogo.command(f"set wait_for_deliverer {wait_time_for_deliverer}")
    netlogo.command(f"set distribution_method \"{distribution_method}\"")
    netlogo.command(f"set deliverers_may_quit {deliverers_may_quit}")
    netlogo.command(f"set radius_allowed {radius_allowed}")

    netlogo.command("setup")
    counts = netlogo.repeat_report(["ticks", "ordered_this_tick", "delivered_this_tick", "discarded_this_tick"],
                                   60 * 24 * 7, go="go")

    netlogo.kill_workspace()
    result_df = aggregates(counts)

    plot = sns.lineplot(data=result_df, x='time', y='value', hue='variable')

    plot.set(xlabel="day", ylabel="number of meals",
             title=f"number of meals r={nr_restaurants} c={max_nr_customers}, d={nr_deliverers}, p={preparation_mean_time}, w={wait_time_for_deliverer}")

    plt.yticks(np.arange(0, 600, step=100))
    plt.xticks(np.arange(0, 7 * 1440 + 1, step=1440))

    x_labels = []

    for x in plot.get_xticks():
        day = int((x / 60) / 24)
        x_labels.append(f"{day}")

    plot.set_xticklabels(x_labels)
    plt.show()
    fig = plot.get_figure()
    fig.savefig(
        f"week_{filename_extra}food_ordering_distribution_{max_nr_customers}_{nr_restaurants}_{nr_deliverers}_{wait_time_for_deliverer}.png")


def run_vary_deliverers(): # ready
    week(nr_deliverers=10, distribution_method="equally_distributed", filename_extra="ed_")
    week(nr_deliverers=25, distribution_method="equally_distributed", filename_extra="ed_")
    week(nr_deliverers=50, distribution_method="equally_distributed", filename_extra="ed_")
    week(nr_deliverers=10, distribution_method="nearest_meal", filename_extra="nm_")
    week(nr_deliverers=25, distribution_method="nearest_meal", filename_extra="nm_")
    week(nr_deliverers=50, distribution_method="nearest_meal", filename_extra="nm_")


def run_vary_waittimesaa():
    week(nr_deliverers=10, distribution_method="nearest_meal", filename_extra="nm_rad_32",radius_allowed=32,wait_time_for_deliverer=60)
    week(nr_deliverers=25, distribution_method="nearest_meal", filename_extra="nm_rad_32",radius_allowed=32,wait_time_for_deliverer=60)
    week(nr_deliverers=50, distribution_method="nearest_meal", filename_extra="nm_rad_32",radius_allowed=32,wait_time_for_deliverer=60)
    run_vary_waittimesaa()

def run_vary_waittimes_50():
    week(nr_deliverers=50, distribution_method="nearest_meal", filename_extra="nd_1_",radius_allowed=32,wait_time_for_deliverer=60)
    week(nr_deliverers=50, distribution_method="nearest_meal", filename_extra="nd_2_",radius_allowed=32,wait_time_for_deliverer=60)
    week(nr_deliverers=50, distribution_method="nearest_meal", filename_extra="nd_3_",radius_allowed=32,wait_time_for_deliverer=60)


def run_vary_waittimes_25():
    week(nr_deliverers=25, distribution_method="nearest_meal", filename_extra="nd_1_",radius_allowed=32,wait_time_for_deliverer=60)
    week(nr_deliverers=25, distribution_method="nearest_meal", filename_extra="nd_2_",radius_allowed=32,wait_time_for_deliverer=60)
    week(nr_deliverers=25, distribution_method="nearest_meal", filename_extra="nd_3_",radius_allowed=32,wait_time_for_deliverer=60)


def run_vary_waittimes_50_wait():
    week(nr_deliverers=50, distribution_method="nearest_deliverer", filename_extra="nd_1_", wait_time_for_deliverer=30)
    week(nr_deliverers=50, distribution_method="nearest_deliverer", filename_extra="nd_2_", wait_time_for_deliverer=60)
    week(nr_deliverers=50, distribution_method="nearest_deliverer", filename_extra="nd_3_", wait_time_for_deliverer=90)


def run_vary_waittimes_25_wait():
    week(nr_deliverers=25, distribution_method="nearest_deliverer", filename_extra="nd_1_", wait_time_for_deliverer=30)
    week(nr_deliverers=25, distribution_method="nearest_deliverer", filename_extra="nd_2_", wait_time_for_deliverer=60)
    week(nr_deliverers=25, distribution_method="nearest_deliverer", filename_extra="nd_3_", wait_time_for_deliverer=90)


def ten_weeks(nr_restaurants=10, nr_customers=500, nr_deliverers=15, preparation_mean_time=15,
              wait_time_for_deliverer=30, distribution_method="equally_distributed", deliverers_may_quit="false",
              radius_allowed=32):
    netlogo.load_model(".\\NetLogo\\fooddelivery.nlogo")
    netlogo.command(f"set number-of-restaurants {nr_restaurants}")
    netlogo.command(f"set max-number-of-customers {nr_customers}")
    netlogo.command(f"set number-of-deliverers {nr_deliverers}")
    netlogo.command(f"set prepair_time_mean {preparation_mean_time}")
    netlogo.command("set prepair_time_stdev 5")
    netlogo.command(f"set wait_for_deliverer {wait_time_for_deliverer}")
    netlogo.command(f"set distribution_method \"{distribution_method}\"")
    netlogo.command(f"set deliverers_may_quit {deliverers_may_quit}")
    netlogo.command(f"set radius_allowed {radius_allowed}")
    netlogo.command("setup")
    counts = netlogo.repeat_report(
        ["ticks", "ordered_this_tick", "delivered_this_tick", "discarded_this_tick", "count deliverers", "count restaurants","count customers"],
        60 * 24 * 7 * 10, go="go")

    netlogo.kill_workspace()
    ts = sum(counts["ticks"])
    ord = sum(counts["ordered_this_tick"])
    dels = sum(counts["delivered_this_tick"])
    disc = sum(counts["discarded_this_tick"])
    dd = min(counts["count deliverers"])
    rr = min(counts["count restaurants"])
    cc = min(counts["count customers"])

    return ts, ord, dels, disc, (dels / ord), dd, rr, cc


def run_zzz():
    total = []
    total.append(ten_weeks(nr_deliverers=10, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60))
    total.append(ten_weeks(nr_deliverers=20, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60))
    total.append(ten_weeks(nr_deliverers=30, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60))
    total.append(ten_weeks(nr_deliverers=40, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60))
    total.append(ten_weeks(nr_deliverers=50, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60))
    total.append(ten_weeks(nr_deliverers=60, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60))
    for z in total:
        print(z)

    run_zzz()

def run_dd():
    total = []
    total.append(ten_weeks(nr_deliverers=20, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60, deliverers_may_quit="true"))
    total.append(ten_weeks(nr_deliverers=20, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60, deliverers_may_quit="true"))
    total.append(ten_weeks(nr_deliverers=20, distribution_method="nearest_meal", radius_allowed=32, wait_time_for_deliverer=60, deliverers_may_quit="true"))
    for z in total:
        print(z)

run_dd()
