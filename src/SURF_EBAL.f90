!-----------------------------------------------------------------------
! Solve surface energy balance
!-----------------------------------------------------------------------
subroutine SURF_EBAL(alb,CH,Dz1,gs,ksurf,Sice,Ts1,Tsurf,Esurf,Gsurf,Melt)

use CONSTANTS, only : &
  cp,                &! Specific heat of dry air at constant pressure (J/K/kg)
  eps,               &! Ratio of molecular weights of water and dry air
  e0,                &! Saturation vapour pressure at Tm (Pa)
  Lc,                &! Latent heat of condensation (J/kg)
  Lf,                &! Latent heat of fusion (J/kg)
  Ls,                &! Latent heat of sublimation (J/kg)
  Rgas,              &! Gas constant for dry air (J/K/kg)
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

use GRID, only : &
  Nsmax               ! Maximum number of snow layers

implicit none

real, intent(in) :: &
  alb,               &! Albedo
  CH,                &! Transfer coefficient for heat and moisture
  Dz1,               &! Surface layer thickness (m)
  gs,                &! Surface moisture conductance (m/s)
  ksurf,             &! Surface layer thermal conductivity (W/m/K)
  Sice(Nsmax),       &! Ice content of snow layers (kg/m^2)
  Ts1                 ! Surface layer temperature (K)

real, intent(inout) :: &
  Tsurf               ! Surface skin temperature (K)

real, intent(out) :: &
  Esurf,             &! Surface moisture flux (kg/m^2/s)
  Gsurf,             &! Heat flux into surface (W/m^2)
  Melt                ! Surface melt rate (kg/m^2/s)

real :: &
  D,                 &! dQsat/dT (1/K)
  dE,                &! Change in surface moisture flux (kg/m^2/s)
  dG,                &! Change in surface heat flux (W/m^2)
  dTs,               &! Change in surface skin temperatures (K)
  H,                 &! Sensible heat flux (W/m^2)
  LE,                &! Latent heat flux (W/m^2)
  Lh,                &! Latent heat (J/kg)
  psi,               &! Moisture availability factor
  Qs,                &! Saturation humidity at surface layer temperature
  rho,               &! Air density (kg/m^3)
  rKH,               &! rho*CH*Ua (kg/m^2/s)
  Rn                  ! Net radiation (W/m^2)

call QSAT(.FALSE.,Ps,Tsurf,Qs)
psi = gs / (gs + CH*Ua)
if (Qs < Qa .or. Sice(1) > 0) psi = 1
Lh = Ls
if (Tsurf > Tm) Lh = Lc
rho = Ps / (Rgas*Ta)
rKH = rho*CH*Ua

! Surface energy balance without melt
D = eps*Lh*Qs/(Rgas*Tsurf**2)
Esurf = psi*rKH*(Qs - Qa)
Gsurf = 2*ksurf*(Tsurf - Ts1)/Dz1
H = cp*rKH*(Tsurf - Ta)
LE = Lh*Esurf
Melt = 0
Rn = (1 - alb)*SW + LW - sb*Tsurf**4
dTs = (Rn - H - LE - Gsurf) /  &
      ((cp + Lh*psi*D)*rKH + 2*ksurf/Dz1 + 4*sb*Tsurf**3)
dE = psi*rKH*D*dTs
dG = 2*ksurf*dTs/Dz1

! Surface melting
if (Tsurf + dTs > Tm .and. Sice(1) > 0) then
  Melt = sum(Sice)/dt
  dTs = (Rn - H - LE - Gsurf - Lf*Melt) /  &
        ((cp + Ls*psi*D)*rKH + 2*ksurf/Dz1 + 4*sb*Tsurf**3)
  dE = rKH*D*dTs
  dG = 2*ksurf*dTs/Dz1
  if (Tsurf + dTs < Tm) then
      call QSAT(.FALSE.,Ps,Tm,Qs)
      Esurf = rKH*(Qs - Qa)  
      Gsurf = 2*ksurf*(Tm - Ts1)/Dz1
      H = cp*rKH*(Tm - Ta)
      LE = Ls*Esurf
      Rn = (1 - alb)*SW + LW - sb*Tm**4
      Melt = (Rn - H - LE - Gsurf) / Lf
      Melt = max(Melt, 0.)
      dE = 0
      dG = 0
      dTs = Tm - Tsurf
  end if
end if

Esurf = Esurf + dE
Gsurf = Gsurf + dG
Tsurf = Tsurf + dTs
if (Tsurf > Tm) Esurf = 0

end subroutine SURF_EBAL
