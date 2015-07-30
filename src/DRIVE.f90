!-----------------------------------------------------------------------
! Read point driving data
!-----------------------------------------------------------------------
subroutine DRIVE(EoR)

use DRIVING, only: &
  year,              &! Year
  month,             &! Month of year
  day,               &! Day of month
  hour,              &! Hour of day
  LW,                &! Incoming longwave radiation (W/m2)
  Ps,                &! Surface pressure (Pa)
  Qa,                &! Specific humidity (kg/kg)
  Rf,                &! Rainfall rate (kg/m2/s)
  Sf,                &! Snowfall rate (kg/m2/s)
  SW,                &! Incoming shortwave radiation (W/m2)
  Ta,                &! Air temperature (K)
  Ua                  ! Wind speed (m/s)

use IOUNITS, only : &
  umet                ! Driving file unit number

implicit none

logical, intent(out) :: &
  EoR                 ! End-of-run flag

real :: &
  Qs,                &! Saturation specific humidity
  RH                  ! Relative humidity (%)

read(umet,*,end=1) year,month,day,hour,SW,LW,Sf,Rf,Ta,RH,Ua,Ps
Ua = max(Ua, 0.1)
call QSAT(.TRUE.,Ps,Ta,Qs)
Qa = (RH/100)*Qs
return

! End of driving data file
1 EoR = .true.

end subroutine DRIVE
