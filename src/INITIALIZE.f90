!-----------------------------------------------------------------------
! Initialize state variables and cumulated diagnostics
!-----------------------------------------------------------------------
subroutine INITIALIZE

use CONSTANTS, only : &
  rho_wat,           &! Density of water (kg/m^3)
  Tm                  ! Melting point (K)

use DIAGNOSTICS, only : &
  diags,             &! Cumulated diagnostics
  Nave,              &! Number of timesteps in average outputs
  SWint,             &! Cumulated incoming solar radiation (J/m^2)
  SWout               ! Cumulated reflected solar radiation (J/m^2)

use GRID, only : &
  Nsoil,             &! Number of soil layers
  Dzsoil              ! Soil layer thicknesses (m)

use IOUNITS, only : &
  udmp,              &! Dump file unit number
  uout,              &! Output file unit number
  ustr                ! Start file unit number

use SOIL_PARAMS, only : &
  Vsat                ! Volumetric soil moisture content at saturation

use STATE_VARIABLES, only : &
  albs,              &! Snow albedo
  Ds,                &! Snow layer thicknesses (m)
  Mf,                &! Frozen moisture content of soil layers (kg/m^2)
  Mu,                &! Unfrozen moisture content of soil layers (kg/m^2) 
  Nsnow,             &! Number of snow layers 
  Sice,              &! Ice content of snow layers (kg/m^2)
  Sliq,              &! Liquid content of snow layers (kg/m^2)
  Tsnow,             &! Snow layer temperatures (K)
  Tsoil,             &! Soil layer temperatures (K)
  Tsurf               ! Surface skin temperature (K)

implicit none

character(len=70) :: &
  dump_file,         &! Dump file name
  out_file,          &! Output file name
  start_file          ! Start file name

integer :: &
  k                   ! Level counter

real :: &
  fsat(Nsoil)         ! Initial moisture content of soil layers as fractions of saturation

namelist /initial/ fsat,Tsoil,start_file
namelist /outputs/ Nave,dump_file,out_file

! Cumulated diagnostics
diags(:) = 0
SWint = 0
SWout = 0

! Set state variables if no start file is specified
start_file = 'none'

! No snow in initial state
albs = 0.8
Ds(:) = 0
Nsnow = 0
Sice(:) = 0
Sliq(:) = 0
Tsnow(:) = Tm

! Initial soil profiles from namelist
fsat(:) = 0.5
Tsoil(:) = 285.
read(5, initial)
Tsurf = Tsoil(1)
do k = 1, Nsoil
  Mf(k) = 0
  Mu(k) = rho_wat*Dzsoil(k)*fsat(k)*Vsat
end do

! Initialize state variables from a named start file
if (start_file /= 'none') then
  open(ustr, file = start_file)
  read(ustr,*) albs
  read(ustr,*) Ds(:)
  read(ustr,*) Mf(:)
  read(ustr,*) Mu(:)
  read(ustr,*) Nsnow
  read(ustr,*) Sice(:)
  read(ustr,*) Sliq(:)
  read(ustr,*) Tsnow(:)
  read(ustr,*) Tsoil(:)
  read(ustr,*) Tsurf
  close(ustr)
end if

! Output options
Nave = 24
out_file = 'out.txt'
dump_file = 'dump.txt'
read(5, outputs)
open(uout, file = out_file)
open(udmp, file = dump_file)

end subroutine INITIALIZE
