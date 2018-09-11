import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
import cartopy
import cartopy.crs as ccrs
import numpy as np
from cartopy.io.img_tiles import StamenTerrain

from matplotlib.cm import inferno as infernompl
from datashader.colors import inferno

import datashader as ds
import datashader.transfer_functions as tf
from datashader.utils import export_image
from constants import FEET2METER
from config import DATA_PATH, FIGURE_FOLDER, resize_figure, TEXT_WIDTH, MODELS, TRAIN, VALID, TEST
import gc
import os


from matplotlib.cm import hot

# load all the files
def load_lat_lon_baro(models, sets):
	lat = np.array([])
	lon = np.array([])
	baroaltitude = np.array([])
	filename = os.path.join(DATA_PATH, "trajs/{}_{}.csv.xz")
	for m in models:
		print(m)
		for s in sets:
		    print(s)
		    if s == TEST:
		        df = pd.read_csv(filename.format(m,s),usecols=['lat','lon','baroaltitude','maxtimestep']).query('maxtimestep>=300')
		    else:
		        df = pd.read_csv(filename.format(m,s),usecols=['lat','lon','baroaltitude','maxtimestep'])
		    lat = np.concatenate((lat,df.lat.values))
		    lon = np.concatenate((lon,df.lon.values))
		    baroaltitude = np.concatenate((baroaltitude,df.baroaltitude.values))
		    del df
		    gc.collect()

	df=pd.DataFrame({'lon':lon,'lat':lat,'baroaltitude':baroaltitude})
	print("number of points loaded: ", df.shape[0])
	return df

# df contains all the datapoints
def draw_figure(df, fileout):
	geodetic = ccrs.Geodetic(globe=ccrs.Globe(datum='WGS84'))
	fig=plt.figure(frameon=False)
	tiler = StamenTerrain()
	ax = plt.axes(projection=tiler.crs)
	ax.add_feature(cartopy.feature.OCEAN,zorder=1)
	ax.add_feature(cartopy.feature.COASTLINE,edgecolor='green',linewidth=0.5,zorder=4)
	ax.add_feature(cartopy.feature.BORDERS,edgecolor='green',linewidth=0.5,zorder=4)

	tra = tiler.crs.transform_points(geodetic,df.lon.values,df.lat.values)
	x = tra[:,0]
	y = tra[:,1]
	tra = pd.DataFrame({'lon':x,'lat':y,'baroaltitude':df.baroaltitude.values})
	target = 6000
	ratio = target/(np.max(tra.lon)-np.min(tra.lon))
	cvs = ds.Canvas(plot_width=target, plot_height=int((np.max(tra.lat)-np.min(tra.lat))*ratio))

	agg = cvs.points(tra, 'lon', 'lat',ds.min('baroaltitude'))#, ds.mean('baroaltitude'))
	img = tf.shade(agg, cmap=inferno,how='linear')
	img = tf.set_background(img, 'black')
	r = img.to_pil()

	datas = r.getdata()

	newData = []
	for item in datas:
		if item[0] == 0 and item[1] == 0 and item[2] == 0:
		    newData.append((255, 255, 255, 0))
		else:
		    newData.append(item)

	r.putdata(newData)
	cax = plt.imshow(r,zorder=3,origin='upper',interpolation='gaussian',extent=(np.min(tra.lon),np.max(tra.lon),np.min(tra.lat),np.max(tra.lat)))
	ax1 = fig.add_axes([0.05, 0.18, 0.9, 0.025])
	norm = mpl.colors.Normalize(vmin=np.min(df.baroaltitude.values)/FEET2METER, vmax=np.max(df.baroaltitude.values)/FEET2METER)
	cb1 = mpl.colorbar.ColorbarBase(ax1, cmap=infernompl,norm=norm,orientation='horizontal')
	cb1.set_label('$H_p$ [ft]')

	size = fig.get_size_inches()
	h_over_w = size[1]/size[0]
	fig.set_tight_layout({'pad':0})
	fig.set_figwidth(TEXT_WIDTH)
	fig.set_figheight(TEXT_WIDTH*h_over_w)
	plt.savefig(fileout,format="pdf",pad_inches=0,dpi=2000, bbox_inches='tight')

def main():
	df = load_lat_lon_baro(MODELS, [TRAIN, VALID, TEST])
	draw_figure(df, os.path.join(FIGURE_FOLDER, "figure6.pdf"))

if __name__ == '__main__':
	main()

