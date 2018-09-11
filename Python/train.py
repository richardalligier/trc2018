import os.path
import regressionlightgbm as rlgb
import lightgbm as lgb
import numpy as np
import pandas as pd
import gc
import pickle
from subprocess import call
from config import DATA_PATH


# Variables quantized into MAX_BIN bins. It is more memory efficient
MAX_BIN = 511
# Number of threads used to grow the trees
NUM_THREADS = 4
# Maximumu number of trees for our model
NUM_BOOST_ROUND = 2000
# Early stopping on the number of trees
EARLY_STOPPING_ROUND = 20
# Minimum number of examples in the leaf; used for regularization
MIN_DATA_IN_LEAF = 50
# A large number has been used => the split on categorical features will always be of type "one-vs-all other"
MAX_CAT_TO_ONEHOT = 100011
# At each round, only a fraction of the data is used to build the tree. Faster training and regularization.
BAGGING_FRACTION = 0.5
# bagging frequency, each BAGGING_FREQ rounds, the data is drawn
BAGGING_FREQ = 1
# feature fraction, at each node split, only a fraction of features is considered. Faster training and regularization.
FEATURE_FRACTION = 0.7
# Max number of leaves for each tree: control model complexity. NUM_LEAVES defines the grid of hyperparameters to test
NUM_LEAVES = [5] + list(range(10, 200, 10))
# Learning rate
LEARNING_RATE = [0.05, 0.02]

# The explanatory variables used are specified as an argument, a string.
# Each letter of this string refers to the set of variables to considered
# as explanatory variables

# Group of float explanatory variables, you can acces a group of variable with letter
vargroupfloat = {
    'b':["massPast", "mseEnergyRatePast", "tempkalman", "ukalman", "vkalman", "heading",
         "baroaltitudekalman", "velocity", "taskalman", "vertratecorr"]+\
    ["baroaltitudekalmanm" + str(i) for i in range(1, 10)]+["taskalmanm" + str(i) for i in range(1, 10)]+\
    ["vertratecorrm" + str(i) for i in range(1, 10)]+["temp" + str(i) + "kalman" for i in range(1000, 12000, 1000)],
    'p':['lat', 'lon'],
    'e':['energyratem' + str(i) for i in range(1, 10)],
    'd':['trip_distance'],
    's':['temp_surfacekalman'],
}
# Group of categorical explanatory variables, you can acces a group of variable with letter
vargroupcat = {
               't':['dayofweek'],
                'i':["icao24"],
                'm':["modeltype"],
                'o':["operator"],
                'a':["fromICAO","toICAO"],
                'c':["callsign"],
               }

# load the dataset efficiently, and quantized the variables into MAX_BIN bins
def get_data(varxcat, varxfloat, yvariable, name, reference=None):
    with open(name,'r') as f:
        header = f.readline().strip().split(",")
    selected = set(varxcat + varxfloat + [yvariable])
    notselected = set(header) - selected
    assert len(selected) + len(notselected) == len(header)
    ignore_column = ",".join(notselected)
    datasetparam = {'label':"name:"+yvariable, 'header':True, 'two_round':True, 'ignore_column':'name:'+ignore_column, 'max_bin':MAX_BIN}
    if varxcat != []:
        datasetparam['categorical_feature']='name:'+",".join(varxcat)
    data = lgb.Dataset(data=name, reference=reference, params=datasetparam, free_raw_data=False)
    data.set_feature_name([x for x in header if x!=yvariable])
    df = pd.read_csv(name, usecols=[yvariable])
    # removing examples where the yvariable is not known/available. This happens, for instance, when cas1 cannot be fitted as the climbing segments starts at high altitude.
    used_indices = np.where(df[yvariable] == df[yvariable])[0]
    nrows = df.shape[0]
    del df
    print("# examples used for training:", used_indices.shape[0])
    if used_indices.shape[0] != nrows:
        data = data.subset(used_indices=used_indices)
    gc.collect()
    data.construct()
    return data

# read the results obtained during a previous hyperparamater search session
def read_hyperparameters(file_hyperparameters):
    if os.path.exists(file_hyperparameters):
        with open(file_hyperparameters) as f:
            hypers = eval(f.read().strip())
    else:
        hypers = []
    return hypers

# save the results obtained during a previous hyperparamater search session
def write_hyperparameters(evaluated_hypers, file_hyperparameters,overwrite = False):
    dirname = os.path.dirname(file_hyperparameters)
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    if not overwrite:
        evaluated_hypers += read_hyperparameters(file_hyperparameters)
    with open(file_hyperparameters,'w') as f:
        f.write(repr(evaluated_hypers))

# load the pair of sets (training,valid). Depending on the context (hyperparameter search or not),
# the training set will be "train" or "train+valid" and the validation set will be
# "valid" or "test" respectively
def get_train_valid_sets(model, varxcat, varxfloat, yvariable, train_final_model, rsh=""):
    name_train = os.path.join(DATA_PATH, "foldedtrajs", "{}_{}.csv".format(model, "train"))
    name_valid = DATA_PATH + "/foldedtrajs/{}_{}.csv".format(model, "valid")
    name_out = os.path.join(DATA_PATH, "foldedtrajs","{}_{}_{}.csv".format(model, "train", os.getpid()))
    call(rsh + "xzcat {}.xz > {}".format(name_train, name_out), shell=True)
    if train_final_model:
        call(rsh+"xzcat {}.xz | tail -n +2 >> {}".format(name_valid, name_out), shell=True)
        lgb_train = get_data(varxcat, varxfloat, yvariable, name_out, reference=None)
        call("rm -f {}".format(name_out), shell=True)
        lgb_valid = None
        return lgb_train, lgb_valid
    else:
        lgb_train = get_data(varxcat, varxfloat, yvariable, name_out, reference=None)
        call("rm -f {}".format(name_out), shell=True)
        name_out = os.path.join(DATA_PATH, "foldedtrajs", "{}_{}_{}.csv".format(model, "valid", os.getpid()))
        call(rsh+"xzcat -kf {}.xz > {}".format(name_valid, name_out), shell=True)
        lgb_valid = get_data(varxcat, varxfloat, yvariable, name_out, reference=lgb_train)
        call("rm -f {}".format(name_out), shell=True)
        return lgb_train, lgb_valid


# generate the grid for hyperparameter to evaluate
def generate_hyperparameters_to_evaluate(varxcat):
    # common hyperparameters
    params = {
                'task': 'train',
                'device':'cpu',
                'boosting_type': 'gbdt',
                'objective': 'regression_l2',
                'metric': {'rmse'},
                'feature_fraction': FEATURE_FRACTION,
                'bagging_freq': BAGGING_FREQ,
                'bagging_fraction': BAGGING_FRACTION,
                'verbose': 0,
                'is_training_metric':True,
                'boost_from_average':True,
                'num_boost_round': NUM_BOOST_ROUND,
                'num_threads':NUM_THREADS,
                'early_stopping_round': EARLY_STOPPING_ROUND,
                'min_data_in_leaf':MIN_DATA_IN_LEAF,
                'max_cat_to_onehot':MAX_CAT_TO_ONEHOT,
                'categorical_feature':'name:'+",".join(varxcat),
            }
    hypers_to_evaluate = []
    for num in NUM_LEAVES:
        for learning_rate in LEARNING_RATE:
            completeparam = params.copy()
            completeparam.update({'num_leaves':num, 'learning_rate':learning_rate,})
            hypers_to_evaluate.append(completeparam)
    return hypers_to_evaluate

# train and evaluate a model for one given hyperparameters
def evaluate_hyperparameter(completeparam, lgb_train, lgb_valid):
    h = rlgb.MyLGBM()
    h.fit(completeparam, lgb_train.feature_name, lgb_train, lgb_valid)
    if h.h.best_iteration != 0:
        completeparam['num_boost_round']=h.h.best_iteration
    if lgb_valid is not None:
        valid_rmse = {'lgb_train':h.evals_result['lgb_train']['rmse'],}
        valid_rmse['lgb_valid']=h.evals_result['lgb_valid']['rmse']
    else:
        valid_rmse = None
    evaluation = (completeparam, valid_rmse)
    return (h, evaluation)

# select the hyperparameters with the lowest validation result
def select_best_evaluated_hyperparameters(evaluated_hypers):
    def best_round(x):
        return x[0]['num_boost_round']-1
    return min(evaluated_hypers,key=lambda x:x[1]['lgb_valid'][best_round(x)])[0]

# print a table containing the hypeparameters paramtab and the associated performance results
def print_evaluated_hyperparameters(evaluated_hypers, paramtab):
    print((len(paramtab)*"{:<20}"+"{:<20}").format('valid_rmse', *tuple( v for v in paramtab)))
    for p in sorted(evaluated_hypers, key=lambda p: tuple( p[0][v] for v in paramtab)):
        print((len(paramtab)*"{:<20}").format(p[1]['lgb_valid'][-1], *tuple( p[0][v] for v in paramtab)))
    print(select_best_evaluated_hyperparameters(evaluated_hypers))

# save the model h in the file filename
def write_model(h, filename):
    dirname = os.path.dirname(filename)
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    with open(filename, 'wb') as f:
        pickle.dump(h, f)

# read a model from the file
def read_model(file_finalmodel):
    with open(file_finalmodel, 'br') as f:
        h = pickle.load(f)
    return h


def main():
    import argparse
    parser = argparse.ArgumentParser(description='train a predictive model.')
    parser.add_argument('-model', help='aircraft model', required=True)
    parser.add_argument('-yvariable', help='variable to predict', required=True)
    parser.add_argument('-xvariables', help='variables used to predict', required=True)
    parser.add_argument("-overwrite", help="overwrite hyperparameters in /hyperresults", action="store_true")
    parser.add_argument("-final", help="the hyperparameters search has been done, let's train the final model", action="store_true")
    args = parser.parse_args()
    model = args.model
    yvariable = args.yvariable
    xvariables = "".join(sorted(args.xvariables))
    # store the hyperparameters and the associated results in this file
    file_hyperparameters = os.path.join(DATA_PATH, model, yvariable, xvariables, 'hyperparameters')
    # if --final, then the obtained model will be stored in this file
    file_finalmodel = os.path.join(DATA_PATH, model, yvariable, xvariables, 'finalmodel.pkl')

    # compute the explanatory variables
    varxfloat = [x for l in xvariables if l in vargroupfloat for x in vargroupfloat[l]]
    varxcat = [x for l in xvariables if l in vargroupcat for x in vargroupcat[l]]

    print("float vars", varxfloat)
    print("cat vars", varxcat)

    lgb_train, lgb_valid = get_train_valid_sets(model, varxcat, varxfloat, yvariable, args.final)
    if args.final:
        hypers = read_hyperparameters(file_hyperparameters)
        selectedparam = select_best_evaluated_hyperparameters(hypers)
        print("selected hyperparameter")
        print(selectedparam)
        h, _ = evaluate_hyperparameter(selectedparam, lgb_train, lgb_valid)
        write_model(h, file_finalmodel)
    else:
        hyperparamters_to_evaluate = generate_hyperparameters_to_evaluate(varxcat)
        evaluated_hypers = []
        for i, completeparam in enumerate(hyperparamters_to_evaluate):
            gc.collect()
            _, evaluation = evaluate_hyperparameter(completeparam, lgb_train, lgb_valid)
            evaluated_hypers.append(evaluation)
        print_evaluated_hyperparameters(evaluated_hypers, ['num_leaves', 'learning_rate'])
        write_hyperparameters(evaluated_hypers, file_hyperparameters, args.overwrite)


if __name__ == '__main__':
    main()
