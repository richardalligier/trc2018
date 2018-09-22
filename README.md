# Learning Aircraft Operational Factors to Improve Aircraft Climb Prediction: A Large Scale Multi-Airport Study

This Github page hosts most of the code producing the results published in the paper "Learning Aircraft Operational Factors to Improve Aircraft Climb Prediction: A Large Scale Multi-Airport Study" ([https://doi.org/10.1016/j.trc.2018.08.012](https://doi.org/10.1016/j.trc.2018.08.012)). The code missing is the code related to the Eurocontrol BADA model.

The trajectory data are automatically downloaded by the script. They are hosted at [https://opensky-network.org/datasets/publication-data/climbing-aircraft-dataset](https://opensky-network.org/datasets/publication-data/climbing-aircraft-dataset).

With this code, you can reproduce the Tables 1, 2, 3, 6, 7, 8 and 9 and Figures 6 and 7 of the publication.

If you have any problems using the provided code, please feel free to open an issue in this Github repository.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

In order to run the Python3 scripts, you will need to install different packages. These packages can be installed with the command:

```
pip3 install pandas numpy matplotlib seaborn cartopy lightgbm==2.1.1
```

In order to compile the OCaml binaries, you will need to install the OCaml compiler. Using Debian/Ubuntu, just type:

```
apt-get update
apt-get install ocaml ocaml-native-compilers
```

(Optional) If you want to reproduce the worldmap of the traffic (Figure 7), you have to install datashader. To do so, just type:

```
git clone https://github.com/bokeh/datashader.git
cd datashader
pip install -e .
```
For more information on datashader, go to [https://github.com/bokeh/datashader](https://github.com/bokeh/datashader).

### Installing
To install the project, you just have to clone or download this github repository. To clone this repository, just type:

```
git clone https://github.com/richardalligier/trc2018.git
```
## Running the Scripts

### Configuring the Scripts

Before running the scripts you might want to edit the file `config`. In this file, you can edit where the generated tables and figures will be created by modifying the variables `FIGURE_FOLDER` and `TABLE_FOLDER`. Likewise, you can edit `DATA_PATH`, this variable is the folder storing the trajectory data, the generated models and predictions. The trajectory data are automatically downloaded.


### Computing the Predicted Operational Factors

You might want to compute the operational factors on a single aircraft type to test the script. For instance, if you want to compute the predicted factors for the DH8D, just type:

```
make MODELS="DH8D"
```

To compute the predicted operational factors, you only have to type (**WARNING: Takes a lot of time!!**) :


```
make
```

This script uses 4 cores and takes several days (maybe a week depending on your computer). Depending on the aircraft type being computed it can take up to approximately 9GB of RAM.

If you have a lot of RAM and cores, you can use the option `-j2` and two parallel processes will be launched. More generally, you can use `-jN` and N processes will be launched.



### Reproducing Figures and Tables

Tables 1, 2 and 3 and figures 6 and 7 can be computed without computing the operational factors. For the other tables and figures, the predicted operational factors must have been computed.

You can use the command `make` to compute the figures and tables you want, if you want to compute all the tables and figures, just type:

```
make table1 table2 table3 table6 table7 table8 table9 figure6 figure7
```
If you only want some, remove the figures or tables you do not want.

## Authors

* **Richard Alligier**
* **David Gianazza**


## License

This project is licensed under the GPLv3 License - see the LICENSE file for details

## Acknowledgments

* [The OpenSky Network](https://opensky-network.org/) for providing and hosting the trajectory data
* [FlightAirMap](https://www.flightairmap.com/) for providing data on Routes and ICAO codes
* [World Aircraft Database](https://junzisun.com/adb/) for providing data on ICAO codes

## Appendix: Data Description

The data are hosted on the download page of [The OpenSky Network](https://opensky-network.org/datasets/). These data files are compressed csv.

Except the angles (which are in degrees), all the variables are in SI units.

| Column | Description |
| --- | --- |
| time | Unix date of the point |
| timestep |  (time-time[first point of climbing segment]): Date with the first point of the climbing segment at 0 |
| maxtimestep | Length of the climbing segment |
| icao24 | Anonymized 24-bit ICAO transponder ID |
| outliers | Fraction of points of the climbing segment that were discarded due to unsound values |
| callsign | Anonymized callsign |
| heading | **Track** angle in degree |
| baroaltitude | Barometric altitude |
| lat | Latitude in degree |
| lon | Longitude in degree |
| velocity | Ground speed |
| vertratecorr | Vertical speed |
| baroaltitudeanalysis | Barometric altitude smoothed with a cubic spline |
| dbaroaltitudeanalysis | Derivative of the Barometric altitude, computed with a cubic spline |
| tasanalysis | True AirSpeed smoothed with a cubic spline |
| dtasanalysis | Derivative of the True AirSpeed smoothed, computed with a cubic spline |
| baroaltitudekalman | Barometric altitude "smoothed" with a Kalman filter |
| taskalman | True AirSpeed "smoothed" with a Kalman filter |
| segment | Id of the climbing segment |
| modeltype | Anonymized model type variant |
| operator | Anonymized airline operator |
| ukalman | Eastern wind component, computed at the Kalman filtered baroaltitude |
| vkalman | Northern wind component, computed at the Kalman filtered baroaltitude |
| tempkalman | Temperature computed at the Kalman filtered baroaltitude |
| temp_surfacekalman | Temperature at the surface |
| temp1000kalman | Temperature at baroaltitudekalman + 1000 m |
| temp2000kalman | Temperature at baroaltitudekalman + 2000 m |
| temp3000kalman | Temperature at baroaltitudekalman + 3000 m |
| temp4000kalman | Temperature at baroaltitudekalman + 4000 m |
| temp5000kalman | Temperature at baroaltitudekalman + 5000 m |
| temp6000kalman | Temperature at baroaltitudekalman + 6000 m |
| temp7000kalman | Temperature at baroaltitudekalman + 7000 m |
| temp8000kalman | Temperature at baroaltitudekalman + 8000 m |
| temp9000kalman | Temperature at baroaltitudekalman + 9000 m |
| temp10000kalman | Temperature at baroaltitudekalman + 10000 m |
| temp11000kalman | Temperature at baroaltitudekalman + 11000 m |
| tempanalysis | Temperature at baroaltitudeanalysis |
| target_cas1 | cas1 parameter of a (cas1,cas2,Mach) speed profile, fitted on the whole climbing segment |
| target_cas2 | cas2 parameter of a (cas1,cas2,Mach) speed profile, fitted on the whole climbing segment |
| target_Mach | Mach parameter of a (cas1,cas2,Mach) speed profile, fitted on the whole climbing segment |
| mseSpeed | Mean Squared Error between the fitted speed profile and the observed one |
| n_cas1 | Number of points inside the cas1 phase |
| n_cas2 | Number of points inside the cas2 phase |
| n_mach | Number of points inside the Mach phase |
| fromICAO | Anonymized departure airport |
| toICAO | Anonymized arrival airport |
| distance_from_dep | Distance between the current position and the departure airport |
| trip_distance | Distance between the departure airport and arrival airport |
| massPast | Mass fitted on the 10 past points using only the BADA 3.14 physical model |
| mseEnergyRatePast | Mean Squared Error between the fitted energy-rate and the observed one |
| massFutur | Mass fitted on the 40 future points using only the BADA 3.14 physical model |
| mseEnergyRateFutur | Mean Squared Error between the fitted energy-rate and the observed one |
| u | Eastern wind component, computed at interpolated baroaltitude |
| v | Northern wind component, computed at interpolated baroaltitude |
| temp | Temperature computed at the interpolated baroaltitude |
| tas | True AirSpeed linearly interpolated |


