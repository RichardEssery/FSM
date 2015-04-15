# FSM

The Factorial Snow Model (FSM) is a multi-physics energy balance model of accumulation and melt of snow on the ground. The model includes 6 parameterizations that can be switched on or off independently, giving 64 possible model configurations. Each configuration is identified by a 6 digit binary number n<sub>a</sub>n<sub>c</sub>d<sub>a</sub>n<sub>e</sub>n<sub>f</sub>n<sub>w</sub> with digits n<sub>a</sub> for prognostic snow albedo, n<sub>c</sub>  for variable thermal conductivity, n<sub>d</sub> for prognostic snow density, n<sub>e</sub> for variable turbulent exchange coefficient and n<sub>w</sub> for prognostic liquid water content; the digits in a configuration number are 0 if a parametrization is switched off and 1 if it is switched on for that configuration. A full description will be given in a forthcoming paper.

## Building the model

FSM is coded in Fortran. An executable `FSM.exe` is produced by the scripts `compil.sh` for Linux or `compil.bat` for Windows using the [gfortran](https://gcc.gnu.org/wiki/GFortran) compiler.

## Running the model

FSM requires meteorological driving data and namelists to set options and parameters. The model is run with the command

    .\FSM.exe < nlst.txt

where 'nlst.txt' is a text file containing five namelists.

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
