!-----------------------------------------------------------------------
! Call physics subroutines
!-----------------------------------------------------------------------
subroutine PHYSICS

use DIAGNOSTICS, only : &
  diags,             &! Cumulated diagnostics
  SWint,             &! Cumulated incoming solar radiation (J/m^2)
  SWout               ! Cumulated reflected solar radiation (J/m^2)

use GRID, only : &
  Nsmax,             &! Maximum number of snow layers
  Nsoil               ! Number of soil layers

use STATE_VARIABLES, only : &
  albs,              &! Snow albedo
  Ds,                &! Snow layer thicknesses (m)
  Mf,                &! Frozen moisture content of soil layers (kg/m^2)
  Mu,                &! Unfrozen moisture content of soil layers (kg/m^2) 
  Nsnow,             &! Number of snow layers
  Sice,              &! Ice content of snow layers (kg/m^2)
  Sliq,              &! Liquid content of snow layers (kg/m^2)
  snowdepth,         &! Snow depth (m)
  SWE,               &! Snow water equivalent (kg/m^2) 
  Tsnow,             &! Snow layer temperatures (K)
  Tsoil,             &! Soil layer temperatures (K)
  Tsurf               ! Surface skin temperature (K)

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

! Snow and soil properties
real :: &
  csoil(Nsoil),      &! Areal heat capacity of soil (J/K/m^2)
  ksnow(Nsmax),      &! Thermal conductivity of snow (W/m/K)
  ksoil(Nsoil),      &! Thermal conductivity of soil (W/m/K)
  rfs                 ! Fresh snow density (kg/m^3) 

! Fluxes
real :: &
  Esurf,             &! Surface moisture flux (kg/m^2/s)
  Gsurf,             &! Heat flux into surface (W/m^2)
  Gsoil,             &! Heat flux into soil (W/m^2)
  Melt,              &! Surface melt rate (kg/m^2/s)
  Roff                ! Runoff from snow (kg/m^2)

call SURF_PROPS(Nsnow,Ds,Mf,Mu,Sice,Sliq,snowdepth,Tsnow,Tsoil,Tsurf,  &
                albs,alb,csoil,Dz1,gs,ksnow,ksoil,ksurf,rfs,Ts1,z0)

call SURF_EXCH(snowdepth,Tsurf,z0,CH)

call SURF_EBAL(alb,CH,Dz1,gs,ksurf,Sice,Ts1,Tsurf,Esurf,Gsurf,Melt)

call SNOW(Esurf,Gsurf,ksnow,ksoil,Melt,rfs,Tsoil,Nsnow,  &
          Ds,Sice,Sliq,Tsnow,Gsoil,Roff,snowdepth,SWE)

call SOIL(csoil,Gsoil,ksoil,Tsoil)

call CUMULATE(alb,Roff,snowdepth,SWE,Tsoil,Tsurf,diags,SWint,SWout)

end subroutine PHYSICS
