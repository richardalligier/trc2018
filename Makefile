
include config

export PATH := $(shell pwd)/OCaml/bin:$(PATH)

.PHONY: all mean masspast foldedtrajs table1 table2 table3 table6 table7 table8 table9 figure6 figure7
.SECONDARY:

SETS := train valid test
$(DATA_PATH)/%:	MODEL = $(wordlist 1,1, $(subst /, ,$*))
$(DATA_PATH)/%:	YVAR = $(wordlist 2,2, $(subst /, ,$*))
$(DATA_PATH)/%:	XVAR = $(wordlist 3,3, $(subst /, ,$*))

OPENSKYURL=https://opensky-network.org/datasets/publication-data/climbing-aircraft-dataset

all: PREDICTED MEAN MASSPAST

MEAN: $(foreach model, $(MODELS),$(foreach yvar, $(YVARS), $(DATA_PATH)/$(model)/$(yvar)/mean.csv))

MASSPAST: $(foreach model, $(MODELS),  $(DATA_PATH)/$(model)/massFutur/massPast.csv)

PREDICTED: $(foreach model, $(MODELS),$(foreach yvar, $(YVARS), $(foreach xvar, $(XVARS), $(DATA_PATH)/$(model)/$(yvar)/$(xvar)/gbmpredicted.csv)))

ANONYM: $(foreach model, $(MODELS), $(DATA_PATH)/anonym/$(model)/test_fromICAO.csv $(DATA_PATH)/anonym/$(model)/test_toICAO.csv)

$(DATA_PATH)/trajs/%:
	wget $(OPENSKYURL)/trajs/$* -P $(@D)

$(DATA_PATH)/anonym/%:
	wget $(OPENSKYURL)/anonym/$* -P $(@D)

$(DATA_PATH)/foldedtrajs/%_test.csv.xz: $(DATA_PATH)/trajs/%_test.csv.xz
	@echo "============= Building test example set $@ ============="
	@make -C ./OCaml all
	@mkdir -p $(DATA_PATH)/foldedtrajs
	xzcat $(DATA_PATH)/trajs/$*_test.csv.xz | csvaddenergyrate -alt baroaltitudekalman -tas taskalman -temp tempkalman | csvfold -c energyrate -npast 1:2:3:4:5:6:7:8:9 | csvremove -c energyrate -all | csvfold -c baroaltitudekalman -npast 1:2:3:4:5:6:7:8:9 | csvfold -c taskalman -npast 1:2:3:4:5:6:7:8:9 | csvfold -c vertratecorr -npast 1:2:3:4:5:6:7:8:9 | csvaddfeatures | csvfold -c baroaltitude -nfutur 1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20:21:22:23:24:25:26:27:28:29:30:31:32:33:34:35:36:37:38:39:40 | xz -1 > $@

$(DATA_PATH)/foldedtrajs/%.csv.xz: $(DATA_PATH)/trajs/%.csv.xz
	@echo "============= Building train/valid example set $@ ============="
	@make -C ./OCaml all
	@mkdir -p $(DATA_PATH)/foldedtrajs
	xzcat $(DATA_PATH)/trajs/$*.csv.xz  | csvaddenergyrate -alt baroaltitudekalman -tas taskalman -temp tempkalman | csvfold -c energyrate -npast 1:2:3:4:5:6:7:8:9 | csvremove -c energyrate -all | csvfold -c baroaltitudekalman -npast 1:2:3:4:5:6:7:8:9 | csvfold -c taskalman -npast 1:2:3:4:5:6:7:8:9 | csvfold -c vertratecorr -npast 1:2:3:4:5:6:7:8:9 | csvfold -c baroaltitude -nfutur 40 | csvremove -c baroaltitudep40 -empty | csvremove -c baroaltitudekalmanm9 -empty | csvaddfeatures | xz -1 > $@


.SECONDEXPANSION:
# computing the performance the obtained models for various hyperparameters
$(DATA_PATH)/%/hyperparameters: $(DATA_PATH)/foldedtrajs/$$(MODEL)_valid.csv.xz $(DATA_PATH)/foldedtrajs/$$(MODEL)_train.csv.xz
	@mkdir -p $(DATA_PATH)/$*
	@echo "===Searching for hyperparameter: $(MODEL) $(YVAR) $(XVAR) ==="
	python3 ./Python/train.py -model $(MODEL) -yvariable $(YVAR) -xvariables $(XVAR)

# training the model on the first ten month
$(DATA_PATH)/%/finalmodel.pkl: $(DATA_PATH)/%/hyperparameters
	@echo "inside hyperparameter=>finalmodel"
	@echo $(MODEL) $(YVAR) $(XVAR)
	python3 ./Python/train.py -model $(MODEL) -yvariable $(YVAR) -xvariables $(XVAR) -final

# last step, computing the prediction
$(DATA_PATH)/%/gbmpredicted.csv: $(DATA_PATH)/foldedtrajs/$$(MODEL)_test.csv.xz $(DATA_PATH)/%/finalmodel.pkl
	@echo "inside finalmodel=>gbmpredicited"
	@echo $(MODEL) $(YVAR) $(XVAR)
	@mkdir -p $(@D)
	python3 ./Python/test.py -model $(MODEL) -yvariable $(YVAR) -xvariables $(XVAR) -out
# computing mean values
$(DATA_PATH)/%/mean.csv: $(foreach set, $(SETS), $(DATA_PATH)/foldedtrajs/$$(MODEL)_$(set).csv.xz)
	@echo "compute mean values"
	@echo $(MODEL) $(YVAR) $(XVAR)
	@mkdir -p $(@D)
	python3 ./Python/computemean.py -model $(MODEL) -var $(YVAR) -method mean

#computing the mass estimated on past points using physical model
$(DATA_PATH)/%/massPast.csv: $(DATA_PATH)/foldedtrajs/$$(MODEL)_test.csv.xz
	@echo "compute massPast values"
	@echo $(MODEL) $(YVAR) $(XVAR)
	python3 ./Python/computemean.py -model $(MODEL) -var massFutur -method massPast

table1:
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_count.py -test -first
	python3 ./Python/table_count.py -test

table2:
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_count.py -first
	python3 ./Python/table_count.py

table3: ANONYM
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_airports.py

table6:
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_factors.py -which massFutur

table7:
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_factors.py -which target_cas1

table8:
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_factors.py -which target_cas2

table9:
	@mkdir -p $(TABLE_FOLDER)
	python3 ./Python/table_factors.py -which target_Mach

figure6:
	@mkdir -p $(FIGURE_FOLDER)
	python3 ./Python/figure_altitude_number.py

figure7:
	@mkdir -p $(FIGURE_FOLDER)
	python3 ./Python/figure_worldmap.py
