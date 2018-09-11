
import os
import numpy as np
import pandas as pd
import gc
import pickle
import time
from subprocess import call
from config import DATA_PATH, TRAIN, VALID, TEST
from test import write_nparray

# Compute the mean value of a variable. Can be used to compute the mass estimated on past points
def compute_mean(args):
	nametrain = "{}/foldedtrajs/{}_{}.csv.xz".format(DATA_PATH,args.model,TRAIN)
	namevalid = "{}/foldedtrajs/{}_{}.csv.xz".format(DATA_PATH,args.model,VALID)
	nametest = "{}/foldedtrajs/{}_{}.csv.xz".format(DATA_PATH,args.model,TEST)
	if args.method == "massPast":
		assert (args.var == "massFutur")
		test = pd.read_csv(nametest, usecols=['massPast'])
		filename = "massPast"
		nparray = test.massPast.values
	elif args.method == "mean":
		train = pd.read_csv(nametrain, usecols=[args.var])
		valid = pd.read_csv(namevalid, usecols=[args.var])
		test = pd.read_csv(nametest, usecols=[args.var])
		varmean = np.nanmean(np.concatenate((train[args.var].values, valid[args.var].values)))
		nparray = np.repeat(varmean, test.shape[0])
	else:
		raise Exception("computemean.py: args.method unknown: "+str(args.method))
	del test
	filename = "{}/{}/{}/{}.csv".format(DATA_PATH,args.model,args.var,args.method)
	write_nparray(nparray, filename, "pred" + args.var)


def main():
	import argparse
	parser = argparse.ArgumentParser(description='train a predictive model.')
	parser.add_argument('-model', help='aircraft model', required=True)
	parser.add_argument('-method', help='method')
	parser.add_argument('-var', help='variable to consider')
	args = parser.parse_args()
	compute_mean(args)


if __name__ == '__main__':
    main()

