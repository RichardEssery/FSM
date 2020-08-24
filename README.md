# FSM

The Factorial Snow Model (FSM) is a multi-physics energy balance model of accumulation and melt of snow on the ground. The model includes 5 parameterizations that can be switched on or off independently, giving 32 possible model configurations identified by decimal numbers between 0 and 31. The corresponding 5 digit binary number n<sub>a</sub>n<sub>c</sub>n<sub>d</sub>n<sub>e</sub>n<sub>w</sub> has digits n<sub>a</sub> for prognostic snow albedo, n<sub>c</sub> for variable thermal conductivity, n<sub>d</sub> for prognostic snow density, n<sub>e</sub> for stability adjustment of the turbulent exchange coefficient and n<sub>w</sub> for prognostic liquid water content; the digits are 0 if a parametrization is switched off and 1 if it is switched on. FSM uses a four-layer soil model extending to 1.5 m depth and one snow layer for snow depths up to 0.2 m, two layers for depths up to 0.5 m or three layers for greater depths. A full description is given by [Essery (2015)](#Essery).

## Building the model

FSM is coded in Fortran. A linux executable `FSM` or a Windows executable `FSM.exe` is produced by running the script `compil.sh` or the batch file `compil.bat`. Both use the [gfortran](https://gcc.gnu.org/wiki/GFortran) compiler but could be edited to use other compilers. The `bin` directory holds precompiled executables.

## Running the model

FSM requires meteorological driving data and namelists to set options and parameters. The model is run with the command

    ./FSM < nlst.txt

or

    FSM.exe < nlst.txt

where `nlst.txt` is a text file containing five namelists described below; `nlst_CdP_0506.txt` gives an example to run FSM for the winter of 2005-2006 at Col de Porte ([Morin et al. 2011](#Morin)). All of the namelists have to be present in the same order as in the example, but any or all of the namelist variables listed in the tables below can be omitted; defaults are then used.

The executable runs a single configuration of FSM, but a Python script is provided to run an ensemble of simulations. For example,

    python FSMens.py nlst_CdP_0506.txt

will run all configurations of FSM for Col de Porte and write output files tagged with the binary configuration numbers to directory `output`.

### Driving data

Meteorological driving data are read from a text file named in namelist `&drive`. A driving data file has 12 columns containing the variables listed in the table below. Each row of the file corresponds with a timestep. Driving data for the Col de Porte example are given in file `data/met_CdP_0506.txt`.

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
| SnowMIP  | .FALSE.   | logical | Read driving data in ESM-SnowMIP format |
| zT       | 2         | m       | Temperature measurement height |
| zU       | 10        | m       | Wind speed measurement height  |
| zvar     | .TRUE.    | logical | Subtract snow depth from measurement height |

`SnowMIP = .TRUE.` is required for driving data files from ESM-SnowMIP ([Krinner et al. 2018](#Krinner)). These files can be downloaded from [https://www.geos.ed.ac.uk/~ressery/ESM-SnowMIP.html](https://www.geos.ed.ac.uk/~ressery/ESM-SnowMIP.html).

Switch `zvar` is provided because the temperature and relative humidity sensors at Col de Porte are moved during site visits to maintain a constant height above the snow surface (`zvar = .FALSE.`). This will not be the case at sites that are not regularly attended.

### Parameter namelist 

`&params`

| Variable | Default | Units | Description |
|----------|---------|-------|-------------|
| alb0 | 0.2  | -    | Snow-free ground albedo                                         |
| asmx | 0.8  | -    | Maximum albedo for fresh snow                                   |
| asmn | 0.5  | -    | Minimum albedo for melting snow                                 |
| bstb | 5    | -    | Atmospheric stability adjustment parameter (if n<sub>e</sub>=1) |
| bthr | 2    | -    | Thermal conductivity exponent (if n<sub>c</sub>=1)              |
| fcly | 0.3  | -    | Soil clay fraction                                              |
| fsnd | 0.6  | -    | Soil sand fraction                                              |
| gsat | 0.01 | m s<sup>-1</sup>  | Surface conductance for saturated soil             |
| hfsn | 0.1  | m    | Snow cover fraction depth scale                                 |
| kfix | 0.24 | W m<sup>-1</sup> K<sup>-1</sup> | Fixed thermal conductivity (if n<sub>c</sub>=0) |
| rho0 | 300  | kg m<sup>-3</sup> | Fixed snow density (if n<sub>d</sub>=0)               |
| rhof | 100  | kg m<sup>-3</sup> | Fresh snow density (if n<sub>d</sub>=1)               |
| rcld | 300  | kg m<sup>-3</sup> | Maximum density for cold snow (if n<sub>d</sub>=1)    |
| rmlt | 500  | kg m<sup>-3</sup> | Maximum density for melting snow (if n<sub>d</sub>=1) |
| Salb | 10   | kg m<sup>-2</sup> | Snowfall to refresh albedo (if n<sub>a</sub>=1)       |
| Talb | -2   | &deg;C| Albedo decay temperature threshold (if n<sub>a</sub>=0)           |
| tcld | 1000 | h    | Cold snow albedo decay timescale (if n<sub>a</sub>=1)              |
| tmlt | 100  | h    | Melting snow albedo decay timescale (if n<sub>a</sub>=1)           |
| trho | 200  | h    | Compaction time scale (if n<sub>d</sub>=1)                         |
| Wirr | 0.03 | -    | Irreducible liquid water content (if n<sub>w</sub>=1)              |
| z0sf | 0.1  | m    | Snow-free roughness length                                         |
| z0sn | 0.01 | m    | Snow roughness length                                              |

### Initial values namelist 

`&initial`

| Variable   | Default | Units  | Description |
|------------|---------|--------|-------------|
| start_file | 'none'  | string | Start file  |
| fsat       | 4 * 0.5 | -      | Initial moisture content of soil layers as fractions of saturation |
| Tsoil      | 4 * 285 | K      | Initial temperatures of soil layers |

Soil temperature and moisture content are taken from the namelist and FSM is initialized in a snow-free state by default. If a start file is named, it should be a text file containing initial values for each of the state variables in order:

| Variable    |  Units             | Description |
|-------------|--------------------|-------------|
|  albs       |  -                 | Snow albedo |
|  Ds(1:3)    |  m                 | Snow layer thicknesses        |
|  Nsnow      |  -                 | Number of snow layers         | 
|  Sice(1:3)  |  kg m<sup>-2</sup> | Ice content of snow layers    |
|  Sliq(1:3)  |  kg m<sup>-2</sup> | Liquid content of snow layers |
|  theta(1:4) |  -                 | Volumetric moisture content of soil layers |
|  Tsnow(1:3) |  K                 | Snow layer temperatures       | 
|  Tsoil(1:4) |  K                 | Soil layer temperatures       |
|  Tsurf      |  K                 | Surface skin temperature      |

Snow and soil layers are numbered from the top downwards. File `data/dump.txt` is an example of a dump file produced at the end of a run which could be used to restart the model.

### Output namelist 

`&outputs`

| Variable  | Default    | Description |
|-----------|------------|-------------|
| Nave      | 24         | Number of timesteps in averaged outputs |
| out_file  | 'out.txt'  | Output file name |
| dump_file | 'dump.txt' | Dump file name   |

At present a simple fixed output format is used. The output text file has 10 columns:

| Variable | Units  | Description       |
|----------|--------|-------------------|
| year     | years  | Year              |
| month    | months | Month of the year |
| day      | days   | Day of the month  |
| hour     | hours  | Hour of the day   |
| alb      | -      | Effective albedo  |
| Rof      | kg m<sup>-2</sup> | Cumulated runoff from snow    |
| snd      | m      | Average snow depth                       |
| SWE      | kg m<sup>-2</sup> | Average snow water equivalent |
| Tsf      | &deg;C | Average surface temperature              |
| Tsl      | &deg;C | Average soil temperature at 20 cm depth  |

Example file `data/out_CdP_0506.txt` contains output from a run of FSM configuration 31; `data/obs_CdP_0506.txt` contains daily observations of the same variables, with -99 indicating missing data.

At the end of a run, the state variables are written to a dump file with the same format as the start file.
 
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

<a name="Essery"></a> Essery (2015). A Factorial Snowpack Model (FSM 1.0). *Geoscientific Model Development*, **8**, 3867-3876, [doi:10.5194/gmd-8-3867-2015](http://www.geosci-model-dev.net/8/3867/2015/)

<a name="Krinner"></a> Krinner et al. (2018). ESM-SnowMIP: assessing snow models and quantifying snow-related climate feedbacks. *Geoscientific Model Development*, **11**, 5027-5049, [doi:10.5194/gmd-11-5027-2018](https://gmd.copernicus.org/articles/11/5027/2018/)

<a name="Morin"></a> Morin et al. (2012). A 18-yr long (1993-2011) snow and meteorological dataset from a mid-altitude mountain site (Col de Porte, France, 1325 m alt.) for driving and evaluating snowpack models. *Earth System Science Data*, **4**(1), 13-21, [doi:10.5194/essd-4-13-2012](http://www.earth-syst-sci-data.net/4/13/2012/essd-4-13-2012.html)

