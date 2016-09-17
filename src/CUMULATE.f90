!-----------------------------------------------------------------------
! Cumulate diagnostics
!-----------------------------------------------------------------------
subroutine CUMULATE(alb,Roff,snowdepth,SWE)

use CONSTANTS, only : &
  Tm                  ! Melting point (K)

use DIAGNOSTICS, only : &
  Nave,              &! Number of timesteps in average outputs
  diags,             &! Cumulated diagnostics
  SWint,             &! Cumulated incoming solar radiation (J/m^2)
  SWout               ! Cumulated reflected solar radiation (J/m^2)

use DRIVING, only: &
  dt,                &! Timestep (s)
  SW                  ! Incoming shortwave radiation (W/m2)

use STATE_VARIABLES, only : &
  Tsoil,             &! Soil layer temperatures (K)
  Tsurf               ! Surface skin temperature (K)

implicit none

real, intent(in) :: &
  alb,               &! Albedo
  Roff,              &! Runoff from snow (kg/m^2)
  snowdepth,         &! Snow depth (m)
  SWE                 ! Snow water equivalent (kg/m^2)

SWint = SWint + SW*dt
SWout = SWout + alb*SW*dt
diags(1) = diags(1) + Roff * Nave
diags(2) = diags(2) + snowdepth
diags(3) = diags(3) + SWE
diags(4) = diags(4) + Tsurf - Tm
diags(5) = diags(5) + Tsoil(2) - Tm

end subroutine CUMULATE
