!-----------------------------------------------------------------------
! Set default parameter values and read namelists
!-----------------------------------------------------------------------
subroutine SET_PARAMETERS

use CONSTANTS, only : &
  hcon_air,          &! Thermal conductivity of air (W/m/K)
  hcon_clay,         &! Thermal conductivity of clay (W/m/K)
  hcon_sand           ! Thermal conductivity of sand (W/m/K)

use DRIVING, only : &
  dt,                &! Timestep (s)
  zT,                &! Temperature measurement height (m)
  zU,                &! Wind measurement height (m)
  zvar                ! Subtract snow depth from measurement height

use IOUNITS, only : &
  umet                ! Driving file unit number

use MODELS, only: &
  am,                &! Snow albedo model        0 - diagnostic
                      !                          1 - prognostic
  cm,                &! Snow conductivity model  0 - fixed
                      !                          1 - density function
  dm,                &! Snow density model       0 - fixed
                      !                          1 - prognostic
  em,                &! Surface exchange model   0 - fixed
                      !                          1 - stability correction
  hm                  ! Snow hydraulics model    0 - free draining 
                      !                          1 - bucket storage

use PARAMETERS, only : &
  alb0,              &! Snow-free ground albedo
  asmx,              &! Maximum albedo for fresh snow
  asmn,              &! Minimum albedo for melting snow
  bstb,              &! Stability slope parameter
  bthr,              &! Snow thermal conductivity exponent
  gsat,              &! Surface conductance for saturated soil (m/s)
  hfsn,              &! Snow cover fraction depth scale (m)
  kfix,              &! Thermal conductivity at fixed snow density (W/m/K)
  rho0,              &! Fixed snow density (kg/m^3)
  rhof,              &! Fresh snow density (kg/m^3)
  rcld,              &! Maximum density for cold snow (kg/m^3)
  rmlt,              &! Maximum density for melting snow (kg/m^3)
  Salb,              &! Snowfall to refresh albedo (kg/m^2)
  Talb,              &! Albedo decay temperature threshold (C)
  tcld,              &! Cold snow albedo decay timescale (h)
  tmlt,              &! Melting snow albedo decay timescale (h)
  trho,              &! Snow compaction time scale (h)
  Wirr,              &! Irreducible liquid water content of snow
  z0sf,              &! Snow-free roughness length (m)
  z0sn                ! Snow roughness length (m)

use SOIL_PARAMS, only : &
  b,                 &! Clapp-Hornberger exponent
  fcly,              &! Soil clay fraction
  fsnd,              &! Soil sand fraction
  hcap_soil,         &! Volumetric heat capacity of dry soil (J/K/m^3)
  hcon_soil,         &! Thermal conductivity of dry soil (W/m/K)
  sathh,             &! Saturated soil water pressure (m)
  Vcrit,             &! Volumetric soil moisture concentration at critical point
  Vsat                ! Volumetric soil moisture concentration at saturation 

implicit none

character(len=70) :: &
  met_file            ! Driving file name

integer :: &
  nconfig             ! Configuration number

real :: &
  hcon_min            ! Thermal conductivity of soil minerals (W/m/K)

namelist /config/ nconfig
namelist /drive/ met_file,dt,zT,zU,zvar
namelist /params/ alb0,asmx,asmn,bstb,bthr,fcly,fsnd,gsat,hfsn,kfix,rho0,  &
                  rhof,rcld,rmlt,Salb,Talb,tcld,tmlt,trho,Wirr,z0sf,z0sn

! Read configuration number and set model swithches
nconfig = 31
read(5,config)
am = mod(nconfig/16,2)
cm = mod(nconfig/8,2)
dm = mod(nconfig/4,2)
em = mod(nconfig/2,2)
hm = mod(nconfig,2)

! Driving data parameters
met_file = 'met.txt'
dt = 3600
zT = 2
zU = 10
zvar = .TRUE.
read(5,drive)
open(umet, file = met_file)

! Defaults for snow parameters
asmx = 0.8
asmn = 0.5
bstb = 5
bthr = 2
hfsn = 0.1
kfix = 0.24
rho0 = 300
rhof = 100
rcld = 300
rmlt = 500
Salb = 10
Talb = -2
tcld = 1000
tmlt = 100
trho = 200
Wirr = 0.03
z0sn = 0.01

! Defaults for surface parameters
alb0 = 0.2
bstb = 5
gsat = 0.01
z0sf = 0.1

! Defaults for soil parameters
fcly = 0.3
fsnd = 0.6

! Read parameter namelist and overwrite defaults
read(5,params)

! Derived soil parameters
if (fcly + fsnd > 1) fcly = 1 - fsnd
b = 3.1 + 15.7*fcly - 0.3*fsnd
hcap_soil = (2.128*fcly + 2.385*fsnd)*1E6 / (fcly + fsnd)
sathh = 10**(0.17 - 0.63*fcly - 1.58*fsnd)
Vsat = 0.505 - 0.037*fcly - 0.142*fsnd
Vcrit = Vsat*(sathh/3.364)**(1/b)
hcon_min = (hcon_clay**fcly) * (hcon_sand**(1 - fcly))
hcon_soil = (hcon_air**Vsat) * (hcon_min**(1 - Vsat))

end subroutine SET_PARAMETERS
