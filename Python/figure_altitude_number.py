import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import numpy as np
from constants import FEET2METER
import gc
import os
from config import DATA_PATH, resize_figure, FIGURE_FOLDER, MODELS, TEST
from matplotlib.legend_handler import HandlerLine2D
import matplotlib.lines as mlines

def draw_figure(models):
        #name of the file to load
	name = os.path.join(DATA_PATH, "trajs", "{}_" + TEST + ".csv.xz")
	sns.set_style("whitegrid")
	sns.set_context("paper")
	colors = sns.color_palette("Set3", n_colors=len(models), desat=1)

	f, ax = plt.subplots()
	handles = []
	for i, m in enumerate(models):
		print(m)
		df = pd.read_csv(name.format(m), usecols=['segment', 'baroaltitude'])
		sns.distplot(df.baroaltitude / FEET2METER, bins=40, kde=False, hist_kws={"color": colors[i], "histtype":"step", "normed":True, "label":m, "linestyle":"-", "linewidth":2, "alpha":1}, ax=ax)
		del df
		gc.collect()
		handles.append(mlines.Line2D([], [], color=colors[i], marker='', label=m))

	ax.set(xlabel='$H_p$ [ft]', ylabel='Frequency [-]')
	ax.legend(ncol=1, loc='best', handles=handles, labelspacing=0.01)

	resize_figure(f, h_over_w=0.6)
	plt.savefig(os.path.join(FIGURE_FOLDER, "figure5.pdf"), format="pdf",dpi=300)

if __name__ == '__main__':
	draw_figure(MODELS)
