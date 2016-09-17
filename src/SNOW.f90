!-----------------------------------------------------------------------
! Snow thermodynamics and hydrology
!-----------------------------------------------------------------------
subroutine SNOW(Esnow,Gsurf,ksnow,ksoil,Melt,rfs,Gsoil,Roff,snowdepth,SWE)
 
use CONSTANTS, only : &
  hcap_ice,          &! Specific heat capacity of ice (J/K/kg)
  hcap_wat,          &! Specific heat capacity of water (J/K/kg)
  Lf,                &! Latent heat of fusion (J/kg)
  rho_ice,           &! Density of ice (kg/m^3)
  rho_wat,           &! Density of water (kg/m^3)
  Tm                  ! Melting point (K)

use DRIVING, only : &
  dt,                &! Timestep (s)
  Rf,                &! Rainfall rate (kg/m^2/s)
  Sf,                &! Snowfall rate (kg/m^2/s)
  Ta                  ! Air temperature (K)

use GRID, only : &
  Dzsnow,            &! Minimum snow layer thicknesses (m)
  Dzsoil,            &! Soil layer thicknesses (m)
  Nsmax,             &! Maximum number of snow layers
  Nsoil               ! Number of soil layers

use MODELS, only: &
  dm,                &! Snow density model       0 - fixed
                      !                          1 - prognostic
  hm                  ! Snow hydraulics model    0 - free draining 
                      !                          1 - bucket storage

use PARAMETERS, only : &
  rho0,              &! Fixed snow density (kg/m^3)
  rcld,              &! Maximum density for cold snow (kg/m^3)
  rmlt,              &! Maximum density for melting snow (kg/m^3)
  trho,              &! Snow compaction time scale (h)
  Wirr                ! Irreducible liquid water content of snow

use STATE_VARIABLES, only : &
  Ds,                &! Snow layer thicknesses (m)
  Nsnow,             &! Number of snow layers
  Sice,              &! Ice content of snow layers (kg/m^2)
  Sliq,              &! Liquid content of snow layers (kg/m^2)
  Tsnow,             &! Snow layer temperatures (K)
  Tsoil               ! Soil layer temperatures (K)

implicit none

real, intent(in) :: &
  Esnow,             &! Snow sublimation rate (kg/m^2/s)
  Gsurf,             &! Heat flux into surface (W/m^2)
  ksnow(Nsmax),      &! Thermal conductivity of snow (W/m/K)
  ksoil(Nsoil),      &! Thermal conductivity of soil (W/m/K)
  Melt,              &! Surface melt rate (kg/m^2/s)
  rfs                 ! Fresh snow density (kg/m^3)

real, intent(out) :: &
  Gsoil,             &! Heat flux into soil (W/m^2)
  Roff,              &! Runoff from snow (kg/m^2)
  snowdepth,         &! Snow depth (m)
  SWE                 ! Snow water equivalent (kg/m^2) 

real :: &
  a(Nsmax),          &! Below-diagonal matrix elements
  b(Nsmax),          &! Diagonal matrix elements
  c(Nsmax),          &! Above-diagonal matrix elements
  csnow(Nsmax),      &! Areal heat capacity of snow (J/K/m^2)
  dTs(Nsmax),        &! Temperature increments (k)
  D(Nsmax),          &! Layer thickness before adjustment (m)
  E(Nsmax),          &! Energy contents before adjustment (J/m^2)
  Gs(Nsmax),         &! Thermal conductivity between layers (W/m^2/k)
  rhs(Nsmax),        &! Matrix equation rhs
  S(Nsmax),          &! Ice contents before adjustment (kg/m^2)
  U(Nsmax),          &! Layer internal energy contents (J/m^2)
  W(Nsmax)            ! Liquid contents before adjustment (kg/m^2)

real :: &
  coldcont,          &! Layer cold content (J/m^2)
  dnew,              &! New snow layer thickness (m)
  dSice,             &! Change in layer ice content (kg/m^2)
  phi,               &! Porosity
  rhos,              &! Density of snow layer (kg/m^3)
  SliqMax,           &! Maximum liquid content for layer (kg/m^2)
  tau,               &! Snow compaction timescale (s)
  wt                  ! Layer weighting

integer :: & 
  k,                 &! Snow layer pointer
  knew,              &! New snow layer pointer
  kold,              &! Old snow layer pointer
  Nold                ! Previous number of snow layers

Gsoil = Gsurf
Roff = Rf*dt

if (Nsnow > 0) then   ! Existing snowpack

! Heat capacity
  do k = 1, Nsnow
    csnow(k) = Sice(k)*hcap_ice + Sliq(k)*hcap_wat
  end do

! Heat conduction
  if (Nsnow == 1) then
    Gs(1) = 2 / (Ds(1)/ksnow(1) + Dzsoil(1)/ksoil(1))
    dTs(1) = (Gsurf + Gs(1)*(Tsoil(1) - Tsnow(1)))*dt /  &
             (csnow(1) + Gs(1)*dt)
  else
    do k = 1, Nsnow - 1
      Gs(k) = 2 / (Ds(k)/ksnow(k) + Ds(k+1)/ksnow(k+1))
    end do
    a(1) = 0
    b(1) = csnow(1) + Gs(1)*dt
    c(1) = - Gs(1)*dt
    rhs(1) = (Gsurf - Gs(1)*(Tsnow(1) - Tsnow(2)))*dt
    do k = 2, Nsnow - 1
      a(k) = c(k-1)
      b(k) = csnow(k) + (Gs(k-1) + Gs(k))*dt
      c(k) = - Gs(k)*dt
      rhs(k) = Gs(k-1)*(Tsnow(k-1) - Tsnow(k))*dt  &
               + Gs(k)*(Tsnow(k+1) - Tsnow(k))*dt 
    end do
    k = Nsnow
    Gs(k) = 2 / (Ds(k)/ksnow(k) + Dzsoil(1)/ksoil(1))
    a(k) = c(k-1)
    b(k) = csnow(k) + (Gs(k-1) + Gs(k))*dt
    c(k) = 0
    rhs(k) = Gs(k-1)*(Tsnow(k-1) - Tsnow(k))*dt  &
             + Gs(k)*(Tsoil(1) - Tsnow(k))*dt
    call TRIDIAG(Nsnow,Nsmax,a,b,c,rhs,dTs)
  end if 
  do k = 1, Nsnow
    Tsnow(k) = Tsnow(k) + dTs(k)
  end do
  Gsoil = Gs(Nsnow)*(Tsnow(Nsnow) - Tsoil(1))

! Convert melting ice to liquid water
  dSice = Melt*dt
  do k = 1, Nsnow
    coldcont = csnow(k)*(Tm - Tsnow(k))
    if (coldcont < 0) then
      dSice = dSice - coldcont/Lf
      Tsnow(k) = Tm
    end if
    if (dSice > 0) then
      if (dSice > Sice(k)) then  ! Layer melts completely
        dSice = dSice - Sice(k)
        Ds(k) = 0
        Sliq(k) = Sliq(k) + Sice(k)
        Sice(k) = 0
      else                       ! Layer melts partially
        Ds(k) = (1 - dSice/Sice(k))*Ds(k)
        Sice(k) = Sice(k) - dSice
        Sliq(k) = Sliq(k) + dSice
        dSice = 0                ! Melt exhausted
      end if
    end if
  end do

! Remove snow by sublimation 
  dSice = max(Esnow, 0.)*dt
  if (dSice > 0) then
    do k = 1, Nsnow
      if (dSice > Sice(k)) then  ! Layer sublimates completely
        dSice = dSice - Sice(k)
        Ds(k) = 0
        Sice(k) = 0
      else                       ! Layer sublimates partially
        Ds(k) = (1 - dSice/Sice(k))*Ds(k)
        Sice(k) = Sice(k) - dSice
        dSice = 0                ! Sublimation exhausted
      end if
    end do
  end if

! Snow hydraulics
  select case(hm)
  case(0)  !  Free-draining snow 
    do k = 1, Nsnow
      Roff = Roff + Sliq(k)
      Sliq(k) = 0
    end do
  case(1)  !  Bucket storage 
    do k = 1, Nsnow
      phi = 0
      if (Ds(k) > epsilon(Ds)) phi = 1 - Sice(k)/(rho_ice*Ds(k))
      SliqMax = rho_wat*Ds(k)*phi*Wirr
      Sliq(k) = Sliq(k) + Roff
      Roff = 0
      if (Sliq(k) > SliqMax) then  ! Liquid capacity exceeded
        Roff = Sliq(k) - SliqMax   ! so drainage to next layer
        Sliq(k) = SliqMax
      end if
      coldcont = csnow(k)*(Tm - Tsnow(k))
      if (coldcont > 0) then       ! Liquid can freeze
        dSice = min(Sliq(k), coldcont/Lf)
        Sliq(k) = Sliq(k) - dSice
        Sice(k) = Sice(k) + dSice
        Tsnow(k) = Tsnow(k) + Lf*dSice/csnow(k)
      end if
    end do
  end select

! Snow compaction
  select case(dm)
  case(0)  ! Fixed snow density
    do k = 1, Nsnow
      Ds(k) = (Sice(k) + Sliq(k)) / rho0
    end do
  case(1)  ! Prognostic snow density
    tau = 3600*trho
    do k = 1, Nsnow
      if (Ds(k) > epsilon(Ds)) then
        rhos = (Sice(k) + Sliq(k)) / Ds(k)
        if (Tsnow(k) >= Tm) then
            if (rhos < rmlt) rhos = rmlt + (rhos - rmlt)*exp(-dt/tau)
        else
            if (rhos < rcld) rhos = rcld + (rhos - rcld)*exp(-dt/tau)
        end if
        Ds(k) = (Sice(k) + Sliq(k)) / rhos
      end if
    end do
  end select

end if  ! Existing snowpack

! Add snowfall and frost to layer 1
dSice = Sf*dt - min(Esnow, 0.)*dt
Ds(1) = Ds(1) + dSice / rfs
Sice(1) = Sice(1) + dSice

! New snowpack
if (Nsnow == 0 .and. Sice(1) > 0) then
  Nsnow = 1
  Tsnow(1) = min(Ta, Tm)
end if

! Calculate snow depth and SWE
snowdepth = 0
SWE = 0
do k = 1, Nsnow
  snowdepth = snowdepth + Ds(k)
  SWE = SWE + Sice(k) + Sliq(k)
end do

! Store state of old layers
D(:) = Ds(:)
S(:) = Sice(:)
W(:) = Sliq(:)
do k = 1, Nsnow
  csnow(k) = Sice(k)*hcap_ice + Sliq(k)*hcap_wat
  E(k) = csnow(k)*(Tsnow(k) - Tm)
end do
Nold = Nsnow

! Initialise new layers
Ds(:) = 0
Sice(:) = 0
Sliq(:) = 0
Tsnow(:) = Tm
U(:) = 0
Nsnow = 0

if (SWE > 0) then  ! Existing or new snowpack

! Re-assign and count snow layers
  dnew = snowdepth
  Ds(1) = dnew
  k = 1
  if (Ds(1) > Dzsnow(1)) then 
    do k = 1, Nsmax
      Ds(k) = Dzsnow(k)
      dnew = dnew - Dzsnow(k)
      if (dnew <= Dzsnow(k) .or. k == Nsmax) then
        Ds(k) = Ds(k) + dnew
        exit
      end if
    end do
  end if
  Nsnow = k

! Fill new layers from the top downwards
  knew = 1
  dnew = Ds(1)
  do kold = 1, Nold
    do
      if (D(kold) < dnew) then
! Transfer all snow from old layer and move to next old layer
        Sice(knew) = Sice(knew) + S(kold)
        Sliq(knew) = Sliq(knew) + W(kold)
        U(knew) = U(knew) + E(kold)
        dnew = dnew - D(kold)
        exit
      else
! Transfer some snow from old layer and move to next new layer
        wt = dnew / D(kold)
        Sice(knew) = Sice(knew) + wt*S(kold) 
        Sliq(knew) = Sliq(knew) + wt*W(kold)
        U(knew) = U(knew) + wt*E(kold)
        D(kold) = (1 - wt)*D(kold)
        E(kold) = (1 - wt)*E(kold)
        S(kold) = (1 - wt)*S(kold)
        W(kold) = (1 - wt)*W(kold)
        knew = knew + 1
        if (knew > Nsnow) exit
        dnew = Ds(knew)
      end if
    end do
  end do

! Diagnose snow layer temperatures
  do k = 1, Nsnow
    csnow(k) = Sice(k)*hcap_ice + Sliq(k)*hcap_wat
    if (csnow(k) > epsilon(csnow)) Tsnow(k) = Tm + U(k) / csnow(k)
  end do

end if  ! Existing or new snowpack

end subroutine SNOW
