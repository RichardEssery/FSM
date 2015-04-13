#############################################################################
# Factorial Snow Model compilation script
#
# Richard Essery
# School of GeoSciences
# University of Edinburgh
#############################################################################
cd src
FC=gfortran
$FC -o FSM -O3 \
MODULES.f90 CUMULATE.f90 DRIVE.f90 FSM.f90 INITIALIZE.f90 OUTPUT.f90    \
PHYSICS.f90 QSAT.f90 SET_PARAMETERS.f90 SNOW.f90 SOIL.f90 SURF_EBAL.f90 \
SURF_EXCH.f90 SURF_PROPS.f90 TRIDIAG.f90
mv FSM ../FSM
rm *.mod
cd ..

