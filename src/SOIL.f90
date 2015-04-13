!-----------------------------------------------------------------------
! Update soil temperatures
!-----------------------------------------------------------------------
subroutine SOIL(csoil,Gsoil,ksoil,Tsoil)

use DRIVING, only : &
  dt                  ! Timestep (s)

use GRID, only : &
  Dzsoil,            &! Soil layer thicknesses (m)
  Nsoil               ! Number of soil layers

implicit none

real, intent(in) :: &
  csoil(Nsoil),      &! Areal heat capacity of soil (J/K/m^2)
  Gsoil,             &! Heat flux into soil (W/m^2)
  ksoil(Nsoil)        ! Thermal conductivity of soil (W/m/K)

real, intent(inout) :: &
  Tsoil(Nsoil)        ! Soil layer temperatures (K)

integer :: &
  k                   ! Level counter

real :: &
  a(Nsoil),          &! Below-diagonal matrix elements
  b(Nsoil),          &! Diagonal matrix elements
  c(Nsoil),          &! Above-diagonal matrix elements
  dTs(Nsoil),        &! Temperature increments (k)
  Gs(Nsoil),         &! Thermal conductivity between layers (W/m^2/k)
  rhs(Nsoil)          ! Matrix equation rhs

do k = 1, Nsoil - 1
  Gs(k) = 2 / (Dzsoil(k)/ksoil(k) + Dzsoil(k+1)/ksoil(k+1))
end do
a(1) = 0
b(1) = csoil(1) + Gs(1)*dt
c(1) = - Gs(1)*dt
rhs(1) = (Gsoil - Gs(1)*(Tsoil(1) - Tsoil(2)))*dt
do k = 2, Nsoil - 1
  a(k) = c(k-1)
  b(k) = csoil(k) + (Gs(k-1) + Gs(k))*dt
  c(k) = - Gs(k)*dt
  rhs(k) = Gs(k-1)*(Tsoil(k-1) - Tsoil(k))*dt  &
           + Gs(k)*(Tsoil(k+1) - Tsoil(k))*dt 
end do
k = Nsoil
Gs(k) = ksoil(k)/Dzsoil(k)
a(k) = c(k-1)
b(k) = csoil(k) + (Gs(k-1) + Gs(k))*dt
c(k) = 0
rhs(k) = Gs(k-1)*(Tsoil(k-1) - Tsoil(k))*dt
call TRIDIAG(Nsoil,Nsoil,a,b,c,rhs,dTs)
do k = 1, Nsoil
  Tsoil(k) = Tsoil(k) + dTs(k)
end do

end subroutine SOIL
