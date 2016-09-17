!-----------------------------------------------------------------------
! Solve surface energy balance
!-----------------------------------------------------------------------
subroutine SURF_EBAL(alb,CH,Dz1,gs,ksurf,Ts1,Esnow,Gsurf,Melt)

use CONSTANTS, only : &
  cp,                &! Specific heat capacity of dry air (J/K/kg)
  Lc,                &! Latent heat of condensation (J/kg)
  Lf,                &! Latent heat of fusion (J/kg)
  Ls,                &! Latent heat of sublimation (J/kg)
  Rgas,              &! Gas constant for dry air (J/K/kg)
  Rwat,              &! Gas constant for water vapour (J/K/kg)
  sb,                &! Stefan-Boltzmann constant (W/m^2/K^4)
  Tm                  ! Melting point (K)

use DRIVING, only: &
  dt,                &! Timestep (s)
  LW,                &! Incoming longwave radiation (W/m2)
  Ps,                &! Surface pressure (Pa)
  Qa,                &! Specific humidity (kg/kg)
  Rf,                &! Rainfall rate (kg/m2/s)
  Sf,                &! Snowfall rate (kg/m2/s)
  SW,                &! Incoming shortwave radiation (W/m2)
  Ta,                &! Air temperature (K)
  Ua                  ! Wind speed (m/s)

use STATE_VARIABLES, only : &
  Sice,              &! Ice content of snow layers (kg/m^2)
  Tsurf               ! Surface skin temperature (K)

implicit none

real, intent(in) :: &
  alb,               &! Albedo
  CH,                &! Transfer coefficient for heat and moisture
  Dz1,               &! Surface layer thickness (m)
  gs,                &! Surface moisture conductance (m/s)
  ksurf,             &! Surface layer thermal conductivity (W/m/K)
  Ts1                 ! Surface layer temperature (K)

real, intent(out) :: &
  Esnow,             &! Snow sublimation rate (kg/m^2/s)
  Gsurf,             &! Heat flux into surface (W/m^2)
  Melt                ! Surface melt rate (kg/m^2/s)

real :: &
  D,                 &! dQsat/dT (1/K)
  dE,                &! Change in surface moisture flux (kg/m^2/s)
  dG,                &! Change in surface heat flux (W/m^2)
  dH,                &! Change in sensible heat flux (W/m^2)
  dTs,               &! Change in surface skin temperatures (K)
  Esurf,             &! Surface moisture flux (kg/m^2/s)
  Esoil,             &! Soil evaporation rate (kg/m^2/s)
  Hsurf,             &! Sensible heat flux (W/m^2)
  LEsrf,             &! Latent heat flux (W/m^2)
  Lh,                &! Latent heat (J/kg)
  psi,               &! Moisture availability factor
  Qs,                &! Saturation humidity at surface layer temperature
  rho,               &! Air density (kg/m^3)
  rKH,               &! rho*CH*Ua (kg/m^2/s)
  Rnet                ! Net radiation (W/m^2)

call QSAT(.FALSE.,Ps,Tsurf,Qs)
psi = gs / (gs + CH*Ua)
if (Qs < Qa .or. Sice(1) > 0) psi = 1
Lh = Ls
if (Tsurf > Tm) Lh = Lc
rho = Ps / (Rgas*Ta)
rKH = rho*CH*Ua

! Surface energy balance without melt
D = Lh*Qs/(Rwat*Tsurf**2)
Esurf = psi*rKH*(Qs - Qa)
Gsurf = 2*ksurf*(Tsurf - Ts1)/Dz1
Hsurf = cp*rKH*(Tsurf - Ta)
LEsrf = Lh*Esurf
Melt = 0
Rnet = (1 - alb)*SW + LW - sb*Tsurf**4
dTs = (Rnet - Hsurf - LEsrf - Gsurf) / &
      ((cp + Lh*psi*D)*rKH + 2*ksurf/Dz1 + 4*sb*Tsurf**3)
dE = psi*rKH*D*dTs
dG = 2*ksurf*dTs/Dz1
dH = cp*rKH*dTs

! Surface melting
if (Tsurf + dTs > Tm .and. Sice(1) > 0) then
  Melt = sum(Sice)/dt
  dTs = (Rnet - Hsurf - LEsrf - Gsurf - Lf*Melt) / &
        ((cp + Ls*psi*D)*rKH + 2*ksurf/Dz1 + 4*sb*Tsurf**3)
  dE = rKH*D*dTs
  dG = 2*ksurf*dTs/Dz1
  dH = cp*rKH*dTs
  if (Tsurf + dTs < Tm) then
      call QSAT(.FALSE.,Ps,Tm,Qs)
      Esurf = rKH*(Qs - Qa)  
      Gsurf = 2*ksurf*(Tm - Ts1)/Dz1
      Hsurf = cp*rKH*(Tm - Ta)
      LEsrf = Ls*Esurf
      Rnet = (1 - alb)*SW + LW - sb*Tm**4
      Melt = (Rnet - Hsurf - LEsrf - Gsurf) / Lf
      Melt = max(Melt, 0.)
      dE = 0
      dG = 0
      dH = 0
      dTs = Tm - Tsurf
  end if
end if

! Update surface temperature and fluxes
Tsurf = Tsurf + dTs
Esurf = Esurf + dE
Gsurf = Gsurf + dG
Hsurf = Hsurf + dH
Esnow = 0
Esoil = 0
if (Sice(1) > 0 .or. Tsurf < Tm) then
  Esnow = Esurf
  LEsrf = Ls*Esurf
else
  Esoil = Esurf
  LEsrf = Lc*Esurf
end if

end subroutine SURF_EBAL
