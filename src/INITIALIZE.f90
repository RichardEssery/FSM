!-----------------------------------------------------------------------
! Initialize state variables and cumulated diagnostics
!-----------------------------------------------------------------------
subroutine INITIALIZE

use CONSTANTS, only : &
  g,                 &! Acceleration due to gravity (m/s^2)
  Lf,                &! Latent heat of fusion (J/kg)
  rho_ice,           &! Density of ice (kg/m^3)
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
  uout                ! Output file unit number

use SOIL_PARAMS, only : &
  b,                 &! Clapp-Hornberger exponent
  sathh,             &! Saturated soil water pressure (m)
  Vsat                ! Soil moisture concentration at saturation

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

character(len=70) :: &
  out_file            ! Output file name

integer :: &
  k                   ! Level counter

real :: &
  dPsidT,            &! Rate of change of ice potential with temperature (m/K)
  sthf,              &! Frozen soil moisture concentration
  sthu,              &! Unfrozen soil moisure concentration
  Tmax                ! Maximum temperature for any frozen moisture (K)

real :: &
  fsat(Nsoil),       &! Initial moisture content of soil layers as fractions of saturation
  theta(Nsoil)        ! Total soil moisture concentration

namelist /initial/ fsat,Tsoil
namelist /outputs/ Nave,out_file

! Cumulated diagnostics
diags(:) = 0
SWint = 0
SWout = 0

! No snow in initial state
albs = 0.8
Ds(:) = 0
Nsnow = 0
Sice(:) = 0
Sliq(:) = 0
snowdepth = 0
SWE = 0
Tsnow(:) = Tm

! Initial soil profiles from namelist
fsat(:) = 0.5
Tsoil(:) = 285.
read(5,initial)
Tsurf = Tsoil(1)
dPsidT = - rho_ice*Lf/(rho_wat*g*Tm)
do k = 1, Nsoil
  theta(k) = fsat(k)*Vsat
  Tmax = 0
  if (theta(k) > epsilon(theta))  &
    Tmax = Tm + (sathh/dPsidT)*(Vsat/theta(k))**b
  if (Tsoil(k) > Tmax) then
    sthu = theta(k)
    sthf = 0
  else
    sthu = Vsat*(dPsidT*(Tsoil(k) - Tm)/sathh)**(-1/b)
    sthu = min(sthu, theta(k))
    sthf = (theta(k) - sthu)*rho_wat/rho_ice
  end if
  Mf(k) = rho_ice*Dzsoil(k)*sthf
  Mu(k) = rho_wat*Dzsoil(k)*sthu
end do

! Output options
Nave = 24
out_file = 'out.txt'
read(5,outputs)
open(uout, file = out_file)

end subroutine INITIALIZE
