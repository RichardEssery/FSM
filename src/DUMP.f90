!-----------------------------------------------------------------------
! Write out state variables at end of run
!-----------------------------------------------------------------------
subroutine DUMP

use IOUNITS, only : &
  udmp                ! Dump file unit number

use STATE_VARIABLES, only : &
  albs,              &! Snow albedo
  Ds,                &! Snow layer thicknesses (m)
  Nsnow,             &! Number of snow layers 
  Sice,              &! Ice content of snow layers (kg/m^2)
  Sliq,              &! Liquid content of snow layers (kg/m^2)
  theta,             &! Volumetric moisture content of soil layers
  Tsnow,             &! Snow layer temperatures (K)
  Tsoil,             &! Soil layer temperatures (K)
  Tsurf               ! Surface skin temperature (K)

implicit none

write(udmp,*) albs
write(udmp,*) Ds(:)
write(udmp,*) Nsnow
write(udmp,*) Sice(:)
write(udmp,*) Sliq(:)
write(udmp,*) theta(:)
write(udmp,*) Tsnow(:)
write(udmp,*) Tsoil(:)
write(udmp,*) Tsurf
close(udmp)

end subroutine DUMP
