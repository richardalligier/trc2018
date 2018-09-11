import lightgbm as lgb


class MyLGBM:
    '''
    Class memorizing the header and taking care of the hyperparameters
    '''
    def fit(self, params, header, lgb_train, lgb_valid=None):
        self.header = header
        self.params = params
        self.evals_result = None
        datasets = [lgb_train]
        namesets = ['lgb_train']
        if lgb_valid is not None:
            datasets.append(lgb_valid)
            namesets.append('lgb_valid')
            self.evals_result = {}
        print('Start training...')
        num_boost_round = self.params['num_boost_round']
        del self.params['num_boost_round']
        print(params)
        if lgb_valid is not None:
            self.h = lgb.train(self.params, lgb_train, num_boost_round=num_boost_round, valid_sets=datasets, valid_names=namesets, evals_result=self.evals_result)
        else:
            self.h = lgb.train(self.params, lgb_train, num_boost_round=num_boost_round, valid_sets=datasets, valid_names=namesets)
        self.params['num_boost_round'] = num_boost_round

    def predict(self, df):
        return self.h.predict(df.loc[:, self.header])
