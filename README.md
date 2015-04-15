# FSM

The Factorial Snow Model (FSM) is a multi-physics energy balance model of accumulation and melt of snow on the ground. The model includes 6 parameterizations that can be switched on or off independently, giving 64 possible model configurations. Each configuration is identified by a 6 digit binary number n<sub>a</sub>n<sub>c</sub>d<sub>a</sub>n<sub>e</sub>n<sub>f</sub>n<sub>w</sub> with digits n<sub>a</sub> for prognostic snow albedo, n<sub>c</sub>  for variable thermal conductivity, n<sub>d</sub> for prognostic snow density, n<sub>e</sub> for variable turbulent exchange coefficient and n<sub>w</sub> for prognostic liquid water content; the digits in a configuration number are 0 if a parametrization is switched off and 1 if it is switched on for that configuration. A full description will be given in a forthcoming paper.

## Building the model

FSM is coded in Fortran. An executable `FSM.exe` is produced by the scripts `compil.sh` for Linux or `compil.bat` for Windows using the [Gfortran](https://gcc.gnu.org/wiki/GFortran) compiler.

## Running the model

FSM requires meteorological driving data and namelists to set options and parameters. 

| Configuration  | n<sub>a</sub>|  n<sub>c</sub> | n<sub>d</sub> | n<sub>e</sub> | n<sub>w</sub> |
|--------------:-|:---:|:---:|:---:|:---:|:---:|
|  1 | 0 | 0 | 0 | 0 | 1 |
|  2 | 0 | 0 | 0 | 1 | 0 |
| 10 | 0 | 0 | 0 | 1 | 1 |
