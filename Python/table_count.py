import pandas as pd
import numpy as np
from config import DATA_PATH, TABLE_FOLDER, TRAIN, VALID, TEST
import gc
import os

# Compute the count of examples for the models in the sets. The result is dumped in fileout
def compute_table_count(models, sets, fileout):
    data = []
    for m in models:
        c = 0
        for s in sets:
            filename = "{}/foldedtrajs/{}_{}.csv.xz".format(DATA_PATH, m, s)
            df = pd.read_csv(filename, usecols=['segment'])
            c += df.segment.nunique()
            del df
            gc.collect()
        data.append("\numprint{{{}}}".format(c))
    count = pd.DataFrame(data=np.array([data]), columns=models, index=['count'])
    count.columns = pd.MultiIndex.from_tuples([(i,) for i in count.columns], names=['model'])
    with open(fileout, 'w') as f:
        f.write(count.to_latex(multirow=True, escape=False))


def main():
	import argparse
	parser = argparse.ArgumentParser(description='stat on table')
	parser.add_argument('-first', action="store_true")
	parser.add_argument('-test', action="store_true")
	args = parser.parse_args()
	(sets, tabnum) = ([TEST], 1) if args.test else ([TRAIN, VALID], 2)
	m1 = ['B738', 'A320', 'A319', 'A321', 'E195']
	m2 = ['E190', 'DH8D', 'B737', 'CRJ9', 'A332', 'B77W']
	(models, subtab) = (m1, 1) if args.first else (m2, 2)
	fileout = os.path.join(TABLE_FOLDER, 'table{}{}.tex'.format(tabnum, subtab))
	compute_table_count(models, sets, fileout)


if __name__ == '__main__':
    main()
