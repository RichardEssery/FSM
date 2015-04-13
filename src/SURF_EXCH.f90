!-----------------------------------------------------------------------
! Surface exchange coefficients
!-----------------------------------------------------------------------
subroutine SURF_EXCH(snowdepth,Tsurf,z0,CH)

use CONSTANTS, only : &
  g,                 &! Acceleration due to gravity (m/s^2)
  vkman               ! Von Karman constant

use DRIVING, only : &
  Ta,                &! Air temperature (K)
  Ua,                &! Wind speed (m/s)
  zT,                &! Temperature and humidity measurement height (m)
  zU,                &! Wind measurement height (m)
  zvar                ! Subtract snow depth from measurement height

use MODELS, only: &
  em                  ! Surface exchange model   0 - fixed
                      !                          1 - stability correction

implicit none

real, intent(in) :: &
  snowdepth,         &! Snow depth (m)
  Tsurf,             &! Surface temperature (K)
  z0                  ! Roughness length for momentum (m)

real, intent(out) :: &
  CH                  ! Transfer coefficient for heat and moisture

real :: &
  CD,                &! Drag coefficient
  fh,                &! Stability correction
  RiB,               &! Bulk Richardson number
  z0h,               &! Roughness length for heat and moisture (m)
  zTs                 ! Adjusted temperature measurement height (m)

zTs = zT
if (zvar) then
  zTs = zT - snowdepth
  zTs = max(zTs, 1.)
end if

! Neutral exchange coefficients
z0h = 0.1*z0
CD = (vkman / log(zU/z0))**2
CH = vkman**2 / (log(zU/z0)*log(zTs/z0h))

! Stability correction (Louis et al. 1982, quoted by Beljaars 1992)
if (em == 1) then
  RiB = g*(Ta - Tsurf)*zU**2 / (zTs*Ta*Ua**2)
  if (RiB > 0) then 
    fh = 1/(1 + 15*RiB*sqrt(1 + 5*RiB))
  else
    fh = 1 - 15*RiB / (1 + 75*CD*sqrt(-RiB*zU/z0))
  end if
  CH = fh*CH
end if

end subroutine SURF_EXCH
