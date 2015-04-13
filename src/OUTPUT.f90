!-----------------------------------------------------------------------
! Write output
!-----------------------------------------------------------------------
subroutine OUTPUT

use DRIVING, only: &
  year,              &! Year
  month,             &! Month of year
  day                 ! Day of month

use IOUNITS, only : &
  uout                ! Output file unit number

use DIAGNOSTICS, only : &
  diags,             &! Cumulated diagnostics
  Nave,              &! Number of timesteps in average outputs
  SWint,             &! Cumulated incoming solar radiation (J/m^2)
  SWout               ! Cumulated reflected solar radiation (J/m^2)

implicit none

real :: &
  alb                 ! Effective albedo

if (SWint > 0) then
  alb = SWout / SWint
else
  alb = -9
end if

! Averages
diags(:) = diags(:) / Nave

write(uout,100) year,month,day,alb,diags(:)

diags(:) = 0
SWint = 0
SWout = 0

100 format(i4,2(2x,i2),6(2x,f8.3))

end subroutine OUTPUT
