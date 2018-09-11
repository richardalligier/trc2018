import os
import pandas as pd
import numpy as np
import gc
import train
from config import DATA_PATH

# Write the predicted operational factor in a file. Please refer to arguments in the main() function to see how to use this module.



# load NBUFF lines at a time, limits the memory usage.
# High NBUFF implies more memory used, but faster prediction
NBUFF = 2500000

VARINT64 = ["time", "segment", "callsign"]
VARINT16 = ["n_cas1", "n_cas2", "n_mach", "modeltype", "icao24", "fromICAO", "toICAO", "operator"]

# Load the csv file by reading only the columns and rows specified
def load_csv(filename, usecols, nrows=None, skiprows=None):
    dicttype = dict((v, np.float32) for v in usecols)
    for v in VARINT64:
        if v in usecols:
            dicttype[v] = np.uint64
    for v in VARINT16:
        if v in usecols:
            dicttype[v] = np.uint16
    df = pd.read_csv(filename, usecols=usecols, dtype=dicttype, engine='c', sep=',', nrows=nrows, skiprows=skiprows)
    return df

# compute the predicted values and the true values
# h is the predictive model, yvariable the explained variable and file_test the name of the csv file.
def compute_predicted_and_true(h, yvariable, file_test):
    pred=np.array([])
    y=np.array([])
    toread=True
    n=0
    while toread:
        vs = load_csv(file_test, usecols=h.header+[yvariable], skiprows=lambda i: 0<i<n*NBUFF+1 or i >= (n+1)*NBUFF+1)#nrows=NBUFF,
        toread = vs.shape[0]==NBUFF
        print('read:',n,vs.shape[0])
        n += 1
        y=np.concatenate((y,vs.loc[:,yvariable].values))
        pred=np.concatenate((pred,h.predict(vs.loc[:,h.header])))
        del vs
        gc.collect()
    return (pred, y)

# Write the predicted values in a file
def write_nparray(nparray, filename, colname):
    df=pd.DataFrame(nparray, columns=[colname])
    dirname=os.path.dirname(filename)
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    df.to_csv(filename,index=False)


def main():
    import argparse
    parser = argparse.ArgumentParser(description='train a predictive model.')
    parser.add_argument('-model', help='aircraft model',required=True)
    parser.add_argument('-yvariable', help='variable to predict',required=True)
    parser.add_argument('-xvariables', help='variables used to predict',required=True)
    parser.add_argument('-out', help='output file containing the predicted values',action="store_true")
    args = parser.parse_args()

    model = args.model
    yvariable = args.yvariable
    xvariables = "".join(sorted(args.xvariables))
    path_pred = os.path.join(DATA_PATH, model, yvariable, xvariables)
    file_gbmpredicted = os.path.join(path_pred, 'gbmpredicted.csv')
    file_finalmodel = os.path.join(path_pred, 'finalmodel.pkl')

    file_test = os.path.join(DATA_PATH, "foldedtrajs", "{}_test.csv.xz".format(model))

    h = train.read_model(file_finalmodel)
    gc.collect()
    pred, y = compute_predicted_and_true(h, yvariable, file_test)
    err = pred - y
    print(np.sqrt(np.nanmean(err**2)))
    if args.out:
        write_nparray(pred, file_gbmpredicted, 'pred' + yvariable)


if __name__ == '__main__':
    main()
