import configparser
import os
import numpy as np

# read the file config in the same folder than Makefile
def read(filename):
    with open(filename) as f:
        sfile = f.read()
    header = "DEFAULT"
    sfile = "[{}]\n".format(header) + sfile
    config = configparser.ConfigParser(delimiters=(':=', '='), inline_comment_prefixes=('#',))
    config.read_string(sfile)
    return dict(config[header])

# resize the figure f
def resize_figure(f, h_over_w=None):
    size=f.get_size_inches()
    if h_over_w is None:
        h_over_w=size[1]/size[0]
    f.set_tight_layout({'pad':0})
    f.set_figwidth(TEXT_WIDTH)
    f.set_figheight(TEXT_WIDTH * h_over_w)

config = read("config")

DATA_PATH = config['data_path']
TABLE_FOLDER = config['table_folder']
FIGURE_FOLDER = config['figure_folder']

TRAIN = 'train'
TEST = 'test'
VALID = 'valid'
TEXT_WIDTH = 4.7747#inch

MODELS = config['models'].split()

MASSES = {\
          'B738':(41150,78300),\
          'A320':(39000,77000),\
          'A319':(40000,77000),\
          'A321':(47800,83000),\
          'E195':(28667,52290),\
          'E190':(27837,51800),\
          'DH8D':(17604,29257),\
          'B737':(38100,70080),\
          'CRJ9':(22200,38000),\
          'A332':(120600,230000),\
          'B77W':(167820,351530),\
}

def limit(limits, x):
	lmin, lmax = limits
	return np.maximum(lmin, np.minimum(x, lmax))

def rmse(x):
	return np.sqrt(np.mean(x**2))

# LaTeX names for the tables
bmean = '${\text{BADA}}_{\text{mean}}$'
bmass = '${\text{BADA}}_{\text{mass}}$'
bmassunlimited = '${\text{BADA}}_{\text{mass-unlimited}}$'
bpred = '${\text{BADA}}_{\text{pred}}$'
bpredto = '${\text{BADA}}_{\text{pred-take-off}}$'

def pathbadapredicted(method, variables = ""):
        return os.path.join(DATA_PATH, "badapredicted", "_".join([TEST,method,"{}",variables]) + ".csv.xz")

mpath={\
       bmean:pathbadapredicted("mean"),\
       bmass:pathbadapredicted("massPast"),\
       bpred:pathbadapredicted("pred","abdemopst"),\
       bpredto:pathbadapredicted("pred","admost"),\
}
