import pandas as pd
import numpy as np
import gc
import os
from constants import FEET2METER,KTS2MS
from config import TABLE_FOLDER, DATA_PATH, MODELS, TEST, MASSES, bmean, bmass, bmassunlimited, bpred, bpredto
import config

def getpath(method, variables = ""):
	if variables == "":
		return os.path.join(DATA_PATH, "{model:}", "{yvar:}", method+".csv")
	else:
		return os.path.join(DATA_PATH, "{model:}", "{yvar:}", variables, "gbmpredicted.csv")

mpath={\
       bmean:getpath("mean"),\
       bmass:getpath("massPast"),\
       bmassunlimited:getpath("massPast"),\
       bpred:getpath("pred", "abdemopst"),\
       bpredto:getpath("pred", "admost"),\
}

# Compute the table for a specified variable
# unit: how the values are scaled
# models: list of aircraft types in the table
# which: which operational factor is concerned
# fileout: where the table will be dumped (in .tex)
# methods: which methods to compare in the table
# form: how the float values are printed
# filters: how the examples are filtered
def compute_table_factor(unit, models, which, fileout, methods, form, filters=None):
    if filters is None:
        filters = []
    data = []
    out = "\numprint{{" + form + "}}" if which !="target_Mach" else form
    for model in models:
        filename = os.path.join(DATA_PATH, "foldedtrajs", ("{}_"+TEST+".csv.xz").format(model))
        print(model)
        usecols = list(np.unique([which, 'maxtimestep', 'timestep']))
        df = pd.read_csv(filename, usecols=usecols)
        for method in methods:
            h = pd.read_csv(mpath[method].format(model=model,yvar=which))
            if method == bmass and which == "massFutur":
            	h['pred' + which] = config.limit(MASSES[model], h['pred' + which].values)
            df[method]=h['pred' + which].values - df[which].values
        for fil in filters:
            df=df.query(fil)
        data.append([])
        for method in methods:
            data[-1].append(out.format(unit * np.mean(df[method].values)))
            data[-1].append(out.format(unit * np.sqrt(np.mean(df[method].values**2))))
        del df
        gc.collect()
    count=pd.DataFrame(data=np.array(data), columns=[(m,s) for m in methods for s in ['mean', 'rmse']], index=models)
    count.columns = pd.MultiIndex.from_tuples( count.columns, names=['method', 'statistic'])
    with open(fileout,'w') as f:
        f.write(count.to_latex(multirow=True, escape=False))

# only keeps the nan values on the specified column x
def nangen(x):
    return '{0}!={0}'.format(str(x))

# only keeps the non nan values on the specified column x
def notnangen(x):
    return '{0}=={0}'.format(str(x))

# only keeps the non nan values on the column 'baroaltitudepx'
def notnan(x):
    return 'baroaltitudep{0}==baroaltitudep{0}'.format(str(x))

def main():
        import argparse
        parser = argparse.ArgumentParser(description='stat on table')
        parser.add_argument('-which', type=str, required=True)
        args = parser.parse_args()
        print(MODELS)
        methods = [bmean, bmass, bpred, bmassunlimited] if args.which == "massFutur" else [bmean, bpred]
        unit = 1 / KTS2MS if "cas" in args.which else 1
        form = "{:.0f}" if "massFutur" == args.which else ("{:.4g}" if "target_Mach" == args.which else "{:.2f}")
        filenameout = os.path.join(TABLE_FOLDER, args.which.replace('_','')+'factor.tex')
        compute_table_factor(unit, MODELS, args.which, filenameout, methods, form, ['timestep>=135', 'maxtimestep>=timestep+600', notnangen(args.which)])

if __name__ == '__main__':
    main()
