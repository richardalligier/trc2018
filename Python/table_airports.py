import pandas as pd
import numpy as np
import gc
import os
from config import DATA_PATH, TABLE_FOLDER, TRAIN, VALID, TEST, MODELS

# count the airports
def count_apt(model, sets):
    dcount = {}
    for m in model:
        print(m)
        fileapt = os.path.join(DATA_PATH, "anonym", m, TEST + "_fromICAO.csv")
        dicao = {}
        with open(fileapt,'r') as f:
            for line in f:
                icao, i, _ = line.strip().split(",")
                dicao[int(i)] = icao
        for s in sets:
            print(s)
            filename = os.path.join(DATA_PATH, "trajs/{}_{}.csv.xz".format(m,s))
            df = pd.read_csv(filename,usecols = ['maxtimestep', 'segment', 'fromICAO']).query('maxtimestep>=300')
            li = df.groupby(['segment'])['fromICAO'].mean()
            del df
            gc.collect()
            for i in li:
#                print(i)
                if i == 0:
                    icao = '-'
                else:
                    icao = dicao[i]
                dcount[icao] = 1 + dcount.get(icao, 0)
    return dcount



def mostfrequent(d):
    s = sum(d.values())
    l = sorted(d.items(), key=lambda x:x[1], reverse=True)
    return [(icao, n/s*100) for (icao, n) in l]

def sumfrequent(d):
    return sum(f for (_, f) in d)

def main():
	d = count_apt(MODELS, [TRAIN, VALID, TEST])
	df = mostfrequent(d)
	fileout = os.path.join(TABLE_FOLDER, 'table3.tex')
	n = 10
	model = [x for (x,_) in df[:n]]
	data = [["", "{:.2f}".format(x)] for (name, x) in df[:n]]
	count = pd.DataFrame(data=(np.array(data)), columns=['airport name','frequency'], index=[name for (name,x) in df[:n]])
	count.columns = pd.MultiIndex.from_tuples([(i,) for i in count.columns], names=['ICAO airport code'])
	with open(fileout,'w') as f:
		f.write(count.to_latex(multirow=True,escape=False))

if __name__ == '__main__':
    main()




