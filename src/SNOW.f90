!-----------------------------------------------------------------------
! Snow thermodynamics and hydrology
!-----------------------------------------------------------------------
subroutine SNOW(Esurf,Gsurf,ksnow,ksoil,Melt,rfs,Tsoil,Nsnow,  &
                Ds,Sice,Sliq,Tsnow,Gsoil,Roff,snowdepth,SWE)
 
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

implicit none

real, intent(in) :: &
  Esurf,             &! Surface moisture flux (kg/m^2/s)
  Gsurf,             &! Heat flux into surface (W/m^2)
  ksnow(Nsmax),      &! Thermal conductivity of snow (W/m/K)
  ksoil(Nsoil),      &! Thermal conductivity of soil (W/m/K)
  Melt,              &! Surface melt rate (kg/m^2/s)
  rfs,               &! Fresh snow density (kg/m^3)
  Tsoil(Nsoil)        ! Soil layer temperatures (K)

integer, intent(inout) :: &
  Nsnow               ! Number of snow layers

real, intent(inout) :: &
  Ds(Nsmax),         &! Snow layer thicknesses (m)
  Sice(Nsmax),       &! Ice content of snow layers (kg/m^2)
  Sliq(Nsmax),       &! Liquid content of snow layers (kg/m^2)
  Tsnow(Nsmax)        ! Snow layer temperatures (K)

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
  d0(0:Nsmax),       &! Layer thickness before adjustment (m)
  E(0:Nsmax),        &! Energy contents before adjustment (J/m^2)
  Gs(Nsmax),         &! Thermal conductivity between layers (W/m^2/k)
  newthick(Nsmax),   &! Available thickness in new layer (m)
  rhs(Nsmax),        &! Matrix equation rhs
  S(0:Nsmax),        &! Ice contents before adjustment (kg/m^2)
  U(Nsmax),          &! Layer internal energy contents (J/m^2)
  W(0:Nsmax)          ! Liquid contents before adjustment (kg/m^2)

real :: &
  coldcont,          &! Layer cold content (J/m^2)
  dl,                &! Local snow depth (m)
  dSice,             &! Change in layer ice content (kg/m^2)
  oldthick,          &! Remaining thickness in old layer (m)
  phi,               &! Porosity
  rhos,              &! Density of snow layer (kg/m^3)
  Sice0,             &! Ice content of fresh snow (kg/m^2)
  SliqMax,           &! Maximum liquid content for layer (kg/m^2)
  tau,               &! Snow compaction timescale (s)
  Tsnow0,            &! Temperature of fresh snow (K)
  wt                  ! Layer weighting

integer :: & 
  k,kold,knew,kstart,&! Level pointers
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
  dSice = max(Esurf, 0.)*dt
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

! Add snowfall and frost as layer 0
Sice0 = Sf*dt - min(Esurf, 0.)*dt
Tsnow0 = min(Ta, Tm)
d0(0) = Sice0 / rfs
E(0) = Sice0*hcap_ice*(Tsnow0 - Tm)
S(0) = Sice0
W(0) = 0

! Calculate new snow depth
snowdepth = d0(0)
do k = 1, Nsnow
  snowdepth = snowdepth + Ds(k)
end do

! Store state of old layers
do k = 1, Nsnow
  csnow(k) = Sice(k)*hcap_ice + Sliq(k)*hcap_wat
  d0(k) = Ds(k)
  E(k) = csnow(k)*(Tsnow(k) - Tm)
  S(k) = Sice(k)
  W(k) = Sliq(k)  
end do
Nold = Nsnow

! Initialise new layers
Ds(:) = 0
Sice(:) = 0
Sliq(:) = 0
Tsnow(:) = Tm
U(:) = 0
Nsnow = 0

if (snowdepth > 0) then  ! Existing or new snowpack

! Re-assign and count snow layers
  dl = snowdepth
  Ds(1) = dl
  k = 1
  if (Ds(1) > Dzsnow(1)) then 
    do k = 1, Nsmax
      Ds(k) = Dzsnow(k)
      dl = dl - Dzsnow(k)
      if (dl <= Dzsnow(k) .or. k == Nsmax) then
        Ds(k) = Ds(k) + dl
        exit
      end if
    end do
  end if
  Nsnow = k
  newthick(:) = Ds(:)

! Fill new layers from the top downwards
  knew = 1
  do kold = 0, Nold                     ! Loop over old layers
    oldthick = d0(kold)
    kstart = knew
    do k = kstart, Nsnow                ! Loop over new layers with remaining space
      if (oldthick > newthick(k)) then  ! New layer filled
        oldthick = oldthick - newthick(k)  
        if (d0(kold) > epsilon(d0)) then
          wt =  newthick(k) / d0(kold)
          Sice(k) = Sice(k) + S(kold)*wt  
          Sliq(k) = Sliq(k) + W(kold)*wt
          U(k) = U(k) + E(kold)*wt
        endif
        knew = k + 1                    ! Update pointer to next new layer
      else                              ! Old layer will be exhausted by this increment
        newthick(k) = newthick(k) - oldthick
        wt = 1
        if (d0(kold) > epsilon(d0)) wt = oldthick / d0(kold)
        Sice(k) = Sice(k) + S(kold)*wt
        Sliq(k) = Sliq(k) + W(kold)*wt
        U(k) = U(k) + E(kold)*wt
        exit                            ! Proceed to next old layer by exiting new layer loop
      end if
    end do                              ! New layers
  end do                                ! Old layers

end if  ! Existing or new snowpack

! Diagnose snow layer temperatures and bulk SWE
SWE = 0
do k = 1, Nsnow
 csnow(k) = Sice(k)*hcap_ice + Sliq(k)*hcap_wat
 if (csnow(k) > epsilon(csnow)) Tsnow(k) = Tm + U(k) / csnow(k)
 SWE = SWE + Sice(k) + Sliq(k)
end do

end subroutine SNOW
