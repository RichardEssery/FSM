!-----------------------------------------------------------------------
! Saturation specific humidity
!-----------------------------------------------------------------------
subroutine QSAT(water,P,T,Qs)

use Constants, only : &
  eps,               &! Ratio of molecular weights of water and dry air
  e0,                &! Saturation vapour pressure at Tm (Pa)
  Tm                  ! Melting point (K)

implicit none

logical, intent(in) :: &
  water               ! Saturation wrt water if TRUE

real, intent(in) :: &
  P,                 &! Air pressure (Pa)
  T                   ! Temperature (K)

real, intent(out) :: &
  Qs                  ! Saturation specific humidity

real :: &
  Tc,                &! Temperature (C)
  es                  ! Saturation vapour pressure (Pa)

Tc = T - Tm
if (Tc > 0 .or. water) then
  es = e0*exp(17.5043*Tc / (241.3 + Tc))
else
  es = e0*exp(22.4422*Tc / (272.186 + Tc))
end if
Qs = eps*es / P

end subroutine QSAT
