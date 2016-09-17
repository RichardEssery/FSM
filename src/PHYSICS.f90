!-----------------------------------------------------------------------
! Call physics subroutines
!-----------------------------------------------------------------------
subroutine PHYSICS

use GRID, only : &
  Nsmax,             &! Maximum number of snow layers
  Nsoil               ! Number of soil layers

implicit none

! Surface properties
real :: &
  alb,               &! Albedo
  CH,                &! Transfer coefficient for heat and moisture
  Dz1,               &! Surface layer thickness (m)
  gs,                &! Surface moisture conductance (m/s)
  ksurf,             &! Surface thermal conductivity (W/m/K)
  Ts1,               &! Surface layer temperature (K)
  z0                  ! Surface roughness length (m)

! Snow properties
real :: &
  ksnow(Nsmax),      &! Thermal conductivity of snow (W/m/K)
  rfs,               &! Fresh snow density (kg/m^3) 
  snowdepth,         &! Snow depth (m)
  SWE                 ! Snow water equivalent (kg/m^2)

 ! Soil properties
real :: &
  csoil(Nsoil),      &! Areal heat capacity of soil (J/K/m^2)
  ksoil(Nsoil)        ! Thermal conductivity of soil (W/m/K)

! Fluxes
real :: &
  Esnow,             &! Snow sublimation rate (kg/m^2/s)
  Gsurf,             &! Heat flux into surface (W/m^2)
  Gsoil,             &! Heat flux into soil (W/m^2)
  Melt,              &! Surface melt rate (kg/m^2/s)
  Roff                ! Runoff from snow (kg/m^2)

call SURF_PROPS(alb,csoil,Dz1,gs,ksnow,ksoil,ksurf,rfs,Ts1,z0)

call SURF_EXCH(z0,CH)

call SURF_EBAL(alb,CH,Dz1,gs,ksurf,Ts1,Esnow,Gsurf,Melt)

call SNOW(Esnow,Gsurf,ksnow,ksoil,Melt,rfs,Gsoil,Roff,snowdepth,SWE)

call SOIL(csoil,Gsoil,ksoil)

call CUMULATE(alb,Roff,snowdepth,SWE)

end subroutine PHYSICS
