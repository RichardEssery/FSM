::-------------------------------------------------------------------------------------------
:: Factorial Snow Model DOS compilation script
::
:: Richard Essery
:: School of GeoSciences
:: University of Edinburgh
::-------------------------------------------------------------------------------------------

cd src
set mods= MODULES.f90
set routines= CUMULATE.f90 DRIVE.f90 FSM.f90 INITIALIZE.f90 OUTPUT.f90 PHYSICS.f90 QSAT.f90 ^
SET_PARAMETERS.f90 SNOW.f90 SOIL.f90 SURF_EBAL.f90 SURF_EXCH.f90 SURF_PROPS.f90 TRIDIAG.f90
gfortran %mods% %routines% -o FSM
del *.mod
move FSM.exe ../FSM.exe
cd ..

