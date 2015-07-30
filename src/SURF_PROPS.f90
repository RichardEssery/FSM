!-----------------------------------------------------------------------
! Surface, surface layer and soil properties
!-----------------------------------------------------------------------
subroutine SURF_PROPS(Nsnow,Ds,Mf,Mu,Sice,Sliq,snowdepth,Tsnow,Tsoil,Tsurf, &
                      albs,alb,csoil,Dz1,gs,ksnow,ksoil,ksurf,rfs,Ts1,z0)

use CONSTANTS, only : &
  g,                 &! Acceleration due to gravity (m/s^2)
  hcap_ice,          &! Specific heat capacity of ice (J/K/kg)
  hcap_wat,          &! Specific heat capacity of water (J/K/kg)
  hcon_air,          &! Thermal conductivity of air (W/m/K)
  hcon_ice,          &! Thermal conducivity of ice (W/m/K)
  hcon_wat,          &! Thermal conductivity of water (W/m/K)
  Lf,                &! Latent heat of fusion (J/kg)
  rho_ice,           &! Density of ice (kg/m^3)
  rho_wat,           &! Density of water (kg/m^3)
  Tm                  ! Melting point (K)

use DRIVING, only : &
  dt,                &! Timestep (s)
  Sf,                &! Snowfall rate (kg/m2/s)
  zU                  ! Wind speed measurement height (m)

use GRID, only : &
  Dzsoil,            &! Soil layer thicknesses (m)
  Nsmax,             &! Maximum number of snow layers
  Nsoil               ! Number of soil layers

use MODELS, only: &
  am,                &! Albedo model             0 - diagnostic
                      !                          1 - prognostic
  cm,                &! Snow conductivity model  0 - fixed
                      !                          1 - density function
  dm                  ! Snow density model       0 - fixed
                      !                          1 - prognostic

use PARAMETERS, only : &
  alb0,              &! Snow-free ground albedo
  asmx,              &! Maximum albedo for fresh snow
  asmn,              &! Minimum albedo for melting snow
  bthr,              &! Snow thermal conductivity exponent
  gsat,              &! Surface conductance for saturated soil (m/s)
  hfsn,              &! Snow cover fraction depth scale (m)
  kfix,              &! Thermal conductivity at fixed snow density (W/m/K)
  rho0,              &! Fixed snow density (kg/m^3)
  rhof,              &! Fresh snow density (kg/m^3)
  Salb,              &! Snowfall to refresh albedo (kg/m^2)
  Talb,              &! Albedo decay temperature threshold (C)
  tcld,              &! Cold snow albedo decay timescale (h)
  tmlt,              &! Melting snow albedo decay timescale (h)
  z0sf,              &! Snow-free roughness length (m)
  z0sn                ! Snow roughness length (m)

use SOIL_PARAMS, only : &
  b,                 &! Clapp-Hornberger exponent
  hcap_soil,         &! Volumetric heat capacity of dry soil (J/K/m^3)
  hcon_soil,         &! Thermal conductivity of dry soil (W/m/K)
  sathh,             &! Saturated soil water pressure (m)
  Vcrit,             &! Volumetric soil moisture concentration at critical point
  Vsat                ! Volumetric soil moisture concentration at saturation

implicit none

integer, intent(in) :: &
  Nsnow               ! Number of snow layers

real, intent(in) :: &
  Ds(Nsmax),         &! Snow layer thicknesses (m)
  Mf(Nsoil),         &! Frozen moisture content of soil layers (kg/m^2)
  Mu(Nsoil),         &! Unfrozen moisture content of soil layers (kg/m^2)
  Sice(Nsmax),       &! Ice content of snow layers (kg/m^2)
  Sliq(Nsmax),       &! Liquid content of snow layers (kg/m^2)
  snowdepth,         &! Snow depth (m)
  Tsnow(Nsmax),      &! Snow layer temperatures (K)
  Tsoil(Nsoil),      &! Soil layer temperatures (K)
  Tsurf               ! Surface skin temperature (K)

real, intent(inout) :: &
  albs                ! Snow albedo

real, intent(out) :: &
  alb,               &! Albedo
  csoil(Nsoil),      &! Areal heat capacity of soil (J/K/m^2)
  Dz1,               &! Surface layer thickness (m)
  gs,                &! Surface moisture conductance (m/s)
  ksnow(Nsmax),      &! Thermal conductivity of snow (W/m/K)
  ksoil(Nsoil),      &! Thermal conductivity of soil (W/m/K)
  ksurf,             &! Surface thermal conductivity (W/m/K)
  rfs,               &! Fresh snow density (kg/m^3) 
  Ts1,               &! Surface layer temperature (K)
  z0                  ! Surface roughness length (m)

integer :: &
  k                   ! Level counter

real :: &
  alim,              &! Limiting albedo
  dPsidT,            &! Rate of change of ice potential with temperature (m/K)
  dthudT,            &! Rate of change of unfrozen moisture concentration with temperature (1/K)
  fsnow,             &! Snow cover fraction
  hcon_sat,          &! Thermal conductivity of saturated soil (W/m/K)
  rhos,              &! Snow density (kg/m^3)
  rt,                &! Reciprocal timescale for albedo adjustment (1/s)
  Smf,               &! Fractional frozen soil moisture concentration
  Smu,               &! Fractional unfrozen soil moisture concentration
  tau,               &! Snow albedo decay timescale (s)
  Tc,                &! Soil temperature (C)
  theta,             &! Total soil moisture concentration
  thice,             &! Soil ice saturation at current liquid / ice ratio
  thwat,             &! Soil water saturation at current liquid / ice ratio
  Tmax                ! Maximum temperature for frozen soil moisture (K)

! Snow albedo
select case(am)
case(0)  ! Diagnosed snow albedo
  albs = asmn + (asmx - asmn)*(Tsurf - Tm) / Talb
case(1)  ! Prognostic snow albedo
  tau = 3600*tcld
  if (Tsurf >= Tm) tau = 3600*tmlt
  rt = 1/tau + Sf/Salb
  alim = (asmn/tau + Sf*asmx/Salb)/rt
  albs = alim + (albs - alim)*exp(-rt*dt)
end select
if (albs > asmx) albs = asmx
if (albs < asmn) albs = asmn

! Density of fresh snow
rfs = rho0
if (dm == 1) rfs = rhof

! Thermal conductivity of snow
ksnow(:) = kfix    ! Fixed 
if (cm == 1) then  ! Density function
  do k = 1, Nsnow
    rhos = rfs
    if (dm == 1 .and. Ds(k) > epsilon(Ds)) rhos = (Sice(k) + Sliq(k)) / Ds(k)
    ksnow(k) = hcon_ice*(rhos/rho_ice)**bthr
  end do
end if

! Partial snow cover
fsnow = tanh(snowdepth/hfsn)
alb = fsnow*albs + (1 - fsnow)*alb0
z0 = (z0sn**fsnow) * (z0sf**(1 - fsnow))

! Soil
dPsidT = - rho_ice*Lf/(rho_wat*g*Tm)
do k = 1, Nsoil
  csoil(k) = hcap_soil*Dzsoil(k)
  ksoil(k) = hcon_soil
  theta = (Mu(k) + Mf(k)) / (rho_wat*Dzsoil(k))
  if (theta > epsilon(theta)) then
    Tc = Tsoil(k) - Tm
    dthudT = 0
    Tmax = Tm + (sathh/dPsidT)*(Vsat/theta)**b
    if (Tsoil(k) < Tmax) dthudT = (-dPsidT*Vsat/(b*sathh)) *  &
                                  (dPsidT*Tc/sathh)**(-1/b - 1)
    csoil(k) = hcap_soil*Dzsoil(k) + hcap_ice*Mf(k) + hcap_wat*Mu(k)  &
               + rho_wat*Dzsoil(k)*((hcap_wat - hcap_ice)*Tc + Lf)*dthudT
    Smf = Mf(k) / (rho_wat*Dzsoil(k)*Vsat)
    Smu = Mu(k) / (rho_wat*Dzsoil(k)*Vsat)
    if (k == 1) gs = gsat*(Smu*Vsat/Vcrit)**2
    thice = 0
    if (Smf > 0) thice = Vsat*Smf / (Smu + Smf) 
    thwat = 0
    if (Smu > 0) thwat = Vsat*Smu / (Smu + Smf)
    hcon_sat = hcon_soil*(hcon_wat**thwat)*(hcon_ice**thice) / (hcon_air**Vsat)
    ksoil(k) = (hcon_sat - hcon_soil)*(Smf + Smu) + hcon_soil
  end if
end do

! Surface layer
Dz1 = max(Dzsoil(1), Ds(1))
Ts1 = Tsoil(1) + (Tsnow(1) - Tsoil(1))*ds(1)/Dzsoil(1)
ksurf = Dzsoil(1) / (2*Ds(1)/ksnow(1) + (Dzsoil(1) - 2*Ds(1))/ksoil(1))
if (Ds(1) > 0.5*Dzsoil(1)) ksurf = ksnow(1)
if (Ds(1) > Dzsoil(1)) Ts1 = Tsnow(1)

end subroutine SURF_PROPS
