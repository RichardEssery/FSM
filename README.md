# FSM

**Documentation not yet complete!**

The Factorial Snow Model (FSM) is a multi-physics energy balance model of accumulation and melt of snow on the ground. The model includes 5 parameterizations that can be switched on or off independently, giving 32 possible model configurations. Each configuration is identified by a decimal number between 0 and 31. The corresponding 5 digit binary number n<sub>a</sub>n<sub>c</sub>n<sub>d</sub>n<sub>e</sub>n<sub>w</sub> has digits n<sub>a</sub> for prognostic snow albedo, n<sub>c</sub> for variable thermal conductivity, n<sub>d</sub> for prognostic snow density, n<sub>e</sub> for stability adjustment of the turbulent exchange coefficient and n<sub>w</sub> for prognostic liquid water content; the digits are 0 if a parametrization is switched off and 1 if it is switched. A full description will be given in a forthcoming paper.

## Building the model

FSM is coded in Fortran. An executable `FSM.exe` is produced by running the script `compil.sh` for Linux or `compil.bat` for Windows. Both scripts use the [gfortran](https://gcc.gnu.org/wiki/GFortran) compiler but could be edited to use other compilers.

## Running the model

FSM requires meteorological driving data and namelists to set options and parameters. The model is run with the command

    ./FSM.exe < nlst.txt

where `nlst.txt` is a text file containing five namelists; `nlst_CdP_0506.txt` gives an example to run FSM for the winter of 2005-2006 at Col de Porte ([Morin et al. 2011](#Morin)). All of the namelists have to be present in the same order as in the example, but any or all of the namelist variables liste din the tables below can be omitted; defaults are then used.

### Driving data

Meteorological driving data are read from a text file named in namelist `&drive`. A driving data file has 12 columns containing the variables listed in the table below. Each row of the file corresponds with a timestep. Driving data for the Col de Porte example are given in file `data/met-CdP_0506.txt`.

| Variable | Units  | Description       |
|----------|--------|-------------------|
| year     | years  | Year              |
| month    | months | Month of the year |
| day      | days   | Day of the month  |
| hour     | hours  | Hour of the day   |
| SW       | W m<sup>-2</sup> | Incoming shortwave radiation  |
| LW       | W m<sup>-2</sup> | Incoming longwave radiation   |
| Sf       | kg m<sup>-2</sup> s<sup>-1</sup> | Snowfall rate |
| Rf       | kg m<sup>-2</sup> s<sup>-1</sup> | Rainfall rate |
| Ta       | K      | Air temperature      |
| RH       | RH     | Relative humidity    |
| Ua       | m s<sup>-1</sup> | Wind speed |
| Ps       | Pa     | Surface air pressure |

### Model configuration namelist 

`&config`

| Variable | Range | Default | Description |
|----------|-------|---------|-------------|
| [nconfig](#configs) | 0 - 31 | 31 | Configuration number |

### Driving data namelist 

`&drive`

| Variable | Default | Units | Description |
|----------|---------|-------|-------------|
| met_file | 'met.txt' | string  | Driving file name |
| dt       | 3600      | s       | Time step         |
| zT       | 2         | m       | Temperature measurement height |
| zU       | 10        | m       | Wind speed measurement height  |
| zvar     | .TRUE.    | logical | Subtract snow depth from measurement height? |


### Parameter namelist 

`&params`

| Variable | Default | Units | Description |
|----------|---------|-------|-------------|
| adct | 1000 | h    | Cold snow albedo decay timescale                   |
| admt | 100  | h    | Melting snow albedo decay timescale                |
| alb0 | 0.2  | -    | Snow-free ground albedo                            |
| asmx | 0.8  | -    | Maximum albedo for fresh snow                      |
| asmn | 0.5  | -    | Minimum albedo for melting snow                    |
| eta0 | 1e7  | Pa s | Snow compactive viscosity (n<sub>d</sub>=1)        |
| fcly | 0.3  | -    | Soil clay fraction                                 |
| fsnd | 0.6  | -    | Soil sand fraction                                 |
| gcrt | 0.01 | m s<sup>-1</sup>  | Surface conductance at critical point |
| kfix | 0.24 | W m<sup>-1</sup> K<sup>-1</sup> | Fixed thermal conductivity of snow (n<sub>c</sub>=0) |
| rho0 | 300  | kg m<sup>-3</sup> | Fixed snow density (n<sub>d</sub>=0)  |
| rhof | 100  | kg m<sup>-3</sup> | Fresh snow density (n<sub>d</sub>=1)  |
| Sfmn | 10   | kg m<sup>-2</sup> | Minimum snowfall to refresh albedo    |
| smsk | 0.02 | kg m<sup>-2</sup> | Snow masking depth                    |
| Swir | 0.03 | -    | Irreducible liquid water content of snow (n<sub>w</sub>=1) |
| z0sf | 0.1  | m    | Snow-free roughness length                         |
| z0sn | 0.01 | m    | Snow roughness length                              |

### Output namelist 

`&outputs`

| Variable | Default | Description |
|----------|---------|-------------|
| Nave     | 24        | Number of timesteps in averaged outputs |
| out_file | 'out.txt' | Output file name |
 
### <a name="configs"></a> Model configurations

| Configuration | n<sub>a</sub>|  n<sub>c</sub> | n<sub>d</sub> | n<sub>e</sub> | n<sub>w</sub> |
|---:|:-:|:-:|:-:|:-:|:-:|
|  0 | 0 | 0 | 0 | 0 | 0 |
|  1 | 0 | 0 | 0 | 0 | 1 |
|  2 | 0 | 0 | 0 | 1 | 0 |
|  3 | 0 | 0 | 0 | 1 | 1 |
|  4 | 0 | 0 | 1 | 0 | 0 |
|  5 | 0 | 0 | 1 | 0 | 1 |
|  6 | 0 | 0 | 1 | 1 | 0 |
|  7 | 0 | 0 | 1 | 1 | 1 |
|  8 | 0 | 1 | 0 | 0 | 0 |
|  9 | 0 | 1 | 0 | 0 | 1 |
| 10 | 0 | 1 | 0 | 1 | 0 |
| 11 | 0 | 1 | 0 | 1 | 1 |
| 12 | 0 | 1 | 1 | 0 | 0 |
| 13 | 0 | 1 | 1 | 0 | 1 |
| 14 | 0 | 1 | 1 | 1 | 0 |
| 15 | 0 | 1 | 1 | 1 | 1 |
| 16 | 1 | 0 | 0 | 0 | 0 |
| 17 | 1 | 0 | 0 | 0 | 1 |
| 18 | 1 | 0 | 0 | 1 | 0 |
| 19 | 1 | 0 | 0 | 1 | 1 |
| 20 | 1 | 0 | 1 | 0 | 0 |
| 21 | 1 | 0 | 1 | 0 | 1 |
| 22 | 1 | 0 | 1 | 1 | 0 |
| 23 | 1 | 0 | 1 | 1 | 1 |
| 24 | 1 | 1 | 0 | 0 | 0 |
| 25 | 1 | 1 | 0 | 0 | 1 |
| 26 | 1 | 1 | 0 | 1 | 0 |
| 27 | 1 | 1 | 0 | 1 | 1 |
| 28 | 1 | 1 | 1 | 0 | 0 |
| 29 | 1 | 1 | 1 | 0 | 1 |
| 30 | 1 | 1 | 1 | 1 | 0 |
| 31 | 1 | 1 | 1 | 1 | 1 |

## References

<a name="Morin"></a> Morin et al. (2012). A 18-yr long (1993-2011) snow and meteorological dataset from a mid-altitude mountain site (Col de Porte, France, 1325 m alt.) for driving and evaluating snowpack models. *Earth System Science Data*, **4**(1), 13-21, doi:10.5194/essd-4-13-2012

