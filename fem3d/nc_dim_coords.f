!
! convert nc files to fem files: dimension and coordinates
!
! contents :
!
!
! revision log :
!
! 03.07.2018    ggu     revision control introduced
!
!*****************************************************************
!*****************************************************************
!*****************************************************************

!================================================================
        module ncnames
!================================================================

        implicit none

        type, private :: entry

          character*5  :: what
          character*80 :: descrp
          character*10 :: short
          logical :: bclip
          integer :: ilen

        end type entry

        integer, save, private :: idlast = 0
        integer, save, private :: ndim = 0
        type(entry), save, private, allocatable :: pentry(:)

	integer, save :: idims(2,0:4)
	integer, save :: icoords(2,0:4)
	character*80, save :: cdims(0:4)
	character*80, save :: ccoords(0:4)

	character*5, parameter :: what = 'txyzi'
	integer, parameter :: nwhere = 3
	character*13, parameter :: where(nwhere) = (/
     +					 'standard_name'
     +					,'long_name    '
     +					,'description  '
     +					/)

!================================================================
        contains
!================================================================

        subroutine ncnames_init_alloc

        type(entry), allocatable :: paux(:)

        if( ndim == 0 ) then
          ndim = 10
          allocate(pentry(ndim))
        else
          allocate(paux(2*ndim))
          paux(1:ndim) = pentry(1:ndim)
          call move_alloc(paux,pentry)
          ndim = ndim*2
        end if

        end subroutine ncnames_init_alloc

!******************************************************************

        subroutine ncnames_init_new_id(id)

        integer id

        idlast = idlast + 1
        if( idlast > ndim ) then
          call ncnames_init_alloc
        end if
	if( idlast > ndim ) stop 'error stop: internal error (3)'
        id = idlast

        call ncnames_init_id(id)

        end subroutine ncnames_init_new_id

!******************************************************************

        subroutine ncnames_init_id(id)

        integer id

        if( id < 1 .or. id > idlast ) then
          stop 'error stop ncnames_init_id: ndim'
        end if

        pentry(id)%what = ' '
        pentry(id)%descrp = ' '
        pentry(id)%short = ' '
        pentry(id)%bclip = .false.
        pentry(id)%ilen = 0

        end subroutine ncnames_init_id

c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine ncnames_add_dim(short,descrp,bclip)

	implicit none

	character*(*) descrp,short
	logical, optional :: bclip

	logical bc

	bc = .false.
	if( present(bclip) ) bc = bclip

	call ncnames_add('dim',descrp,short,.false.)

	end subroutine ncnames_add_dim

c*****************************************************************

	subroutine ncnames_add_coord(short,descrp,bclip)

	implicit none

	character*(*) descrp,short
	logical, optional :: bclip

	logical bc

	bc = .false.
	if( present(bclip) ) bc = bclip

	call ncnames_add('coord',descrp,short,bc)

	end subroutine ncnames_add_coord

c*****************************************************************

	subroutine ncnames_add_var(short,descrp,bclip)

	implicit none

	character*(*) descrp,short
	logical, optional :: bclip

	logical bc

	bc = .false.
	if( present(bclip) ) bc = bclip

	call ncnames_add('var',descrp,short,bc)

	end subroutine ncnames_add_var

c*****************************************************************

	subroutine ncnames_add(what,descrp,short,bclip)

! adds item into internal list
!
! what: dim, coord, var
! descrp: description that can be found in nc file
! short: short version for item

	implicit none

	character*(*) what,descrp,short
	logical :: bclip

	logical, parameter :: bdebug = .false.
	integer id,i
	character*80 name

        call ncnames_init_new_id(id)

	name = descrp
	call to_lower(name)

        pentry(id)%what = what
        pentry(id)%descrp = name
        pentry(id)%short = short
        pentry(id)%bclip = bclip
        pentry(id)%ilen = len_trim(name)

	if( bdebug ) then		!GGU
	  i = len_trim(name)
	  write(6,*) 'add ',id,trim(what),' ',trim(name),' ',trim(short)
     +			,' ',bclip,len_trim(name)
     +			,ichar(name(i:i))
	end if

	end subroutine ncnames_add

c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine ncnames_get(what,descrp,short)

! looks for item with description descrp and returns short if found
!
! what: dim, coord, var
! descrp: description that can be found in nc file
! short: short version for item

	implicit none

	character*(*) what,descrp,short

	logical bclip,bdebug
	integer id,il,ilen,i,iu
	character*80 name

	bdebug = .true.			!GGU
	bdebug = .false.			!GGU
	bdebug = bdebug .and. what == 'var'

	short = ' '
	name = descrp
	iu = index(name,'[')
	if( iu > 0 ) name = name(1:iu-1)	!delete unit given in []
	call to_lower(name)
	il = len_trim(name)
	if( bdebug ) then
	write(6,*) 'in ncnames_get... -------------------'
	write(6,*) 'name: |',trim(name),'|',il
	do i=1,20
	  !write(6,*) i,ichar(descrp(i:i))
	  if( ichar(descrp(i:i)) == 0 ) then
	    write(6,*) 'char 0 in string: ',trim(name),i,il
	  end if
	end do
	end if
	if( name == ' ' ) stop 'empty string'

	if( bdebug ) then
	write(6,*) 'checking: ',trim(what),idlast,'  ',trim(descrp),bclip
	end if

	do id=1,idlast
	  !bdebug = ( bdebug .and. id == 56 )		!GGU
	  if( pentry(id)%what /= what ) cycle
	  ilen = il
	  if( pentry(id)%bclip ) ilen = pentry(id)%ilen
	if( bdebug ) then
	write(6,*) id,il,ilen,pentry(id)%bclip		!GGU
	write(6,*) pentry(id)%descrp(1:ilen),'  ',trim(name)
	end if
	  if( pentry(id)%descrp(1:ilen) == name(1:ilen) ) then
	    short = pentry(id)%short
	if( bdebug ) write(6,*) 'found: ',trim(short)
	    return
	  end if
	end do

	end subroutine

c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine ncnames_get_dims(ncid,bverb)

! insert dimensions in internal structure

	implicit none

	integer ncid
	logical bverb

	logical bdebug
	character*80 short
	integer dim_id,ndims,nlen,i
	character*80 name
	character*1 c

	!character*5, parameter :: what = 'txyzi'

	bdebug = .true.
	bdebug = .false.
	idims = 0
	cdims = ' '

        call nc_get_dim_totnum(ncid,ndims)

        do dim_id=1,ndims

          call nc_get_dim_name(ncid,dim_id,name)
          call nc_get_dim_len(ncid,dim_id,nlen)

	  call ncnames_get('dim',name,short)

	  i = index(what,short(1:1)) - 1
	  if( i < 0 ) then
	    if( bdebug ) then
	      write(6,*) '*** cannot identify dimension: ',trim(name)
	    end if
	  else
	    idims(1,i) = dim_id
	    idims(2,i) = nlen
	    cdims(i) = name
	  end if

        end do

	if( .not. bverb ) return

	write(6,*) 'dimensions in ncnames_get_dims:'
	do i=0,3
	  c = what(i+1:i+1)
	  write(6,*) c,'    ',idims(:,i),'  ',trim(cdims(i))
	end do

	end subroutine

c*****************************************************************

	subroutine ncnames_get_coords(ncid,bverb)

! insert coordinates in internal structure

	implicit none

	integer ncid
	logical bverb

	logical bdebug
	character*80 short
	integer var_id,nvars,nlen,i,j
	integer ndims,dimids(1)
	character*80 name,atext
	character*1 c

	bdebug = bverb
	icoords = 0
	ccoords = ' '

        call nc_get_var_totnum(ncid,nvars)

        do var_id=1,nvars

          call nc_get_var_name(ncid,var_id,name)

	  do j=1,nwhere
            call nc_get_var_attr(ncid,var_id,trim(where(j)),atext)
	    if( atext == ' ' ) cycle
	    call ncnames_get('coord',atext,short)
	    if( short /= ' ' ) exit
	  end do
	  if( short == ' ' ) cycle

	  !write(6,*) trim(name),'  ',trim(short)
	  i = index(what,short(1:1)) - 1
	  if( i >= 0 ) then
	    if( icoords(1,i) > 0 ) cycle	!do not insert second one
	    ndims = 0
	    call nc_get_var_ndims(ncid,var_id,ndims,dimids)
	    icoords(1,i) = var_id
	    icoords(2,i) = ndims
	    ccoords(i) = name
	  end if

        end do

	if( .not. bdebug ) return

	write(6,*) 'coordinates:'
	do i=0,3
	  c = what(i+1:i+1)
	  write(6,*) c,'    ',icoords(:,i),'  ',trim(ccoords(i))
	end do

	end subroutine

c*****************************************************************

	subroutine ncnames_get_vars(ncid)

! looks for variable names

	implicit none

	integer ncid

	logical bdebug
	character*80 short
	integer var_id,nvars,nlen,i,j
	integer ndims,dimids(1)
	character*80 name,atext
	character*1 c

	bdebug = .true.

        call nc_get_var_totnum(ncid,nvars)

        do var_id=1,nvars

          call nc_get_var_name(ncid,var_id,name)

	  do j=1,nwhere
            call nc_get_var_attr(ncid,var_id,trim(where(j)),atext)
	    if( atext == ' ' ) cycle
	    call ncnames_get('var',atext,short)
	    if( short /= ' ' ) exit
	  end do
	  if( short == ' ' ) cycle

	  write(6,*) 'var: ',trim(name),'  ',trim(short)

        end do

	if( .not. bdebug ) return

	end subroutine

c*****************************************************************

	subroutine ncnames_get_var(ncid,var,short)

! looks for variable var and returns short if found

	implicit none

	integer ncid
	character*(*) var,short

	logical bdebug
	integer var_id,j,i
	integer ndims,dimids(1)
	character*80 name,atext
	character*1 c

	bdebug = .true.			!GGU
	bdebug = .false.			!GGU

	call nc_get_var_id(ncid,var,var_id)

	if( bdebug ) write(6,*) 'looking: ',trim(var),var_id
	do j=1,nwhere
          call nc_get_var_attr(ncid,var_id,trim(where(j)),atext)
	if( bdebug ) write(6,*) '   ',trim(where(j)),'  ',trim(atext)
	  if( atext == ' ' ) cycle
	if( bdebug ) then
	  !do i=1,20
	  !  write(6,*) 'atext ',i,ichar(atext(i:i))
	  !end do
	end if
	  call ncnames_get('var',atext,short)
	if( bdebug ) then
	write(6,*) '  .. ','  |',trim(atext),'|  ',trim(short)
	end if
	  if( short /= ' ' ) exit
	end do

	end subroutine

!================================================================
        end module ncnames
!================================================================

c*****************************************************************
c*****************************************************************
c*****************************************************************

c       else if( iwhat .eq. 3 ) then    !wrf
c       'U10','u'  'V10','v'  'PSFC','p'
c       'RAINR','r',8
c       'T2','t'  'CLOUD','c'  'RH','h'  'SWDOWN','s'

c       else if( iwhat .eq. 4 ) then    !myocean
c       'sossheig','Z'  'vosaline','S'  'votemper','T'

c       else if( iwhat .eq. 5 ) then    !ROMS/TOMS
c       'salt','S' 'temp','T'

c       else if( iwhat .eq. 6 ) then    !wrf 2
c       'U10','u'  'V10','v'
c       'MSLP','p' 'PSFC','p'
c       'RAINR','r',rfact
c       'T2','t'  'CLOUD','c',0.01  'RH','h'  'SWDOWN','s'

c       else if( iwhat .eq. 7 ) then    !ECMWF
c       'var165','u'  'var166','v'  'var151','p'  'var228','r',rfact
c       'var167','t'  'var187','c'  'var168','d'  'var176','s'

c*****************************************************************
c*****************************************************************
c*****************************************************************
c test routines
c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine get_dims_and_coords(ncid,bverb
     +			,nt,nx,ny,nz
     +			,tcoord,xcoord,ycoord,zcoord)

	use ncnames

	implicit none

	integer ncid
	logical bverb
	integer nt,nx,ny,nz
	character(*) tcoord,xcoord,ycoord,zcoord

        call check_compatibility(ncid,bverb)

	nt = idims(2,0)
	nx = idims(2,1)
	ny = idims(2,2)
	nz = idims(2,3)

	tcoord = ccoords(0)
	xcoord = ccoords(1)
	ycoord = ccoords(2)
	zcoord = ccoords(3)

        if( nt > 0 .and. tcoord == ' ' ) then
          write(6,*) 'nt = ',nt,'   tcoord = ',trim(tcoord)
          stop 'error stop: dimension without variable name'
        end if
        if( nx > 0 .and. xcoord == ' ' ) then
          write(6,*) 'nx = ',nx,'   xcoord = ',trim(xcoord)
          stop 'error stop: dimension without variable name'
        end if
        if( ny > 0 .and. ycoord == ' ' ) then
          write(6,*) 'ny = ',ny,'   ycoord = ',trim(ycoord)
          stop 'error stop: dimension without variable name'
        end if
        if( nz > 0 .and. zcoord == ' ' ) then
          write(6,*) 'nz = ',nz,'   zcoord = ',trim(zcoord)
          stop 'error stop: dimension without variable name'
        end if

	end

c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine check_compatibility(ncid,bverb)

! tested compatibility - eliminated
! now used to write out dims and coords found (with -verbose)

	use ncnames

	implicit none

	integer ncid
	logical bverb

	logical bextra
	integer nt,nx,ny,nz,i
	character*80 tcoord,xname,yname,zcoord
	character*80 time_d,time_v
	character*1 c

	bextra = .true.
	bextra = .false.

	if( bverb ) write(6,*) 'compatibility test:'

	call ncnames_init

	call ncnames_get_dims(ncid,bextra)
	call ncnames_get_coords(ncid,bextra)

	if( bverb ) then
	  write(6,*) 'dimensions:'
	  do i=0,3
	    c = what(i+1:i+1)
	    write(6,*) c,'  ',idims(:,i),'  ',trim(cdims(i))
	  end do
	end if

	if( bverb ) then
	  write(6,*) 'coordinates:'
	  do i=0,3
	    c = what(i+1:i+1)
	    write(6,*) c,'  ',icoords(:,i),'  ',trim(ccoords(i))
	  end do
	end if

	if( bverb ) write(6,*) 'compatibility test successfully ended'

	return
   97	continue
	write(6,*) time_d,time_v
	write(6,*) cdims(0),ccoords(0)
	stop 'error stop check_compatibility: time information'
   98	continue
	write(6,*) nt,idims(2,0)
	write(6,*) nx,idims(2,1)
	write(6,*) ny,idims(2,2)
	write(6,*) nz,idims(2,3)
	stop 'error stop check_compatibility: dimensions'
   99	continue
	write(6,*) 't  ',trim(tcoord),'  ',trim(ccoords(0))
	write(6,*) 'x  ',trim(xname),'  ',trim(ccoords(1))
	write(6,*) 'y  ',trim(yname),'  ',trim(ccoords(2))
	write(6,*) 'z  ',trim(zcoord),'  ',trim(ccoords(3))
	stop 'error stop check_compatibility: coordinates'
	end

c*****************************************************************

	subroutine nc_dim_coords_test_open(ncid)

	implicit none

	integer ncid,nc
	character*80 file

	nc = command_argument_count()
	if( nc == 0 ) stop 'no file given'
	call get_command_argument(1,file)

        call nc_open_read(ncid,file)

	end

c*****************************************************************

	subroutine nc_dim_coords_test

	use ncnames

	implicit none

	integer ncid
	logical bverb

	bverb = .true.

	call nc_dim_coords_test_open(ncid)

	call ncnames_init

	call ncnames_get_dims(ncid,bverb)
	call ncnames_get_coords(ncid,bverb)

	end

c*****************************************************************

	subroutine nc_dim_compatibility_test

	use ncnames

	implicit none

	integer ncid

	call nc_dim_coords_test_open(ncid)

	!call ncnames_init
	call check_compatibility(ncid,.true.)

	end

c*****************************************************************

!	program nc_dim_coords_main
!	!call nc_dim_coords_test
!	call nc_dim_compatibility_test
!	end

c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine ncnames_init

	use ncnames

	implicit none

	character*80 time_d,time_v

	cdims = ' '
	ccoords = ' '
	idims = 0
	icoords = 0

	call ncnames_add_dimensions
	call ncnames_add_coordinates
	call ncnames_add_variables

	time_d = cdims(0)
	time_v = ccoords(0)
        call nc_set_time_name(time_d,time_v)

	end subroutine ncnames_init

c*****************************************************************

	subroutine ncnames_add_dimensions

	use ncnames

	implicit none

	call ncnames_add_dim('t','time')
	call ncnames_add_dim('t','Time')

	call ncnames_add_dim('x','x')
	call ncnames_add_dim('x','xpos')
	call ncnames_add_dim('x','lon')
	call ncnames_add_dim('x','longitude')
	call ncnames_add_dim('x','west_east')
	call ncnames_add_dim('x','xt_ocean')
	call ncnames_add_dim('x','rlon')

	call ncnames_add_dim('y','y')
	call ncnames_add_dim('y','ypos')
	call ncnames_add_dim('y','lat')
	call ncnames_add_dim('y','latitude')
	call ncnames_add_dim('y','south_north')
	call ncnames_add_dim('y','yt_ocean')
	call ncnames_add_dim('y','rlat')

	call ncnames_add_dim('z','z')
	call ncnames_add_dim('z','zpos')
	call ncnames_add_dim('z','bottom_top_stag')
	call ncnames_add_dim('z','level')
	call ncnames_add_dim('z','depth')
	call ncnames_add_dim('z','height')
	call ncnames_add_dim('z','st_ocean')

	call ncnames_add_dim('ignore','crsdim')
	call ncnames_add_dim('ignore','node')
	call ncnames_add_dim('ignore','element')
	call ncnames_add_dim('ignore','vertex')

	end subroutine ncnames_add_dimensions

c*****************************************************************

	subroutine ncnames_add_coordinates

	use ncnames

	implicit none

	logical, parameter :: bclip = .true.

	call ncnames_add_coord('t','time')
	call ncnames_add_coord('t','Julian day (UTC) of the station')
	call ncnames_add_coord('t','minutes since',bclip)

	call ncnames_add_coord('x','longitude')
	call ncnames_add_coord('x','Longitude')
	call ncnames_add_coord('x','Longitude of scalars')
	call ncnames_add_coord('x','LONGITUDE',bclip)

	call ncnames_add_coord('y','latitude')
	call ncnames_add_coord('y','Latitude')
	call ncnames_add_coord('y','Latitude of scalars')
	call ncnames_add_coord('y','LATITUDE',bclip)

	call ncnames_add_coord('z','depth')
	call ncnames_add_coord('z','zcoord')
	call ncnames_add_coord('z','height')
	call ncnames_add_coord('z','sigma of cell face')
	call ncnames_add_coord('z','bottom of vertical layers')
	call ncnames_add_coord('z','eta values on full',bclip)
	call ncnames_add_coord('z','tcell zstar depth')

	end subroutine ncnames_add_coordinates

c*****************************************************************

	subroutine ncnames_add_variables

! please use shortname as first argument and the description
! of the variable as found in
!     		 'standard_name'  'long_name'  'description'

	use ncnames

	implicit none

	logical, parameter :: bclip = .true.

	call ncnames_add_var('bathy','Surface topography')
	call ncnames_add_var('bathy','surface_altitude')
	call ncnames_add_var('bathy','bathymetry')
	call ncnames_add_var('bathy','sea_floor_depth_below_sea_surface')
	call ncnames_add_var('bathy','depth under water positive')
	call ncnames_add_var('bathy','depth')
	call ncnames_add_var('salt','sea_water_salinity')
	call ncnames_add_var('salt','Salinity')
	call ncnames_add_var('temp','sea_water_potential_temperature')
	call ncnames_add_var('temp','temperature')
	call ncnames_add_var('temp','Conservative temperature')
	call ncnames_add_var('zeta','sea_surface_elevation')
	call ncnames_add_var('zeta','Sea Surface height')
	call ncnames_add_var('zeta'
     +			,'water_surface_height_above_geoid')
	call ncnames_add_var('zeta'
     +			,'water_surface_height_above_reference_datum')
	call ncnames_add_var('zeta','surface height on T cells')
	call ncnames_add_var('vel','zonal velocity')
	call ncnames_add_var('vel','eastward_sea_water_velocity',bclip)
	call ncnames_add_var('vel','meridional velocity')
	call ncnames_add_var('vel','northward_sea_water_velocity',bclip)
	call ncnames_add_var('vel','Zonal current speed component')
	call ncnames_add_var('vel','Meridional current speed component')

	call ncnames_add_var('airp','Pressure at the Surface')
	call ncnames_add_var('airp','surface_air_pressure')
	call ncnames_add_var('airp','Mean sea level pressure')
	call ncnames_add_var('airp','SFC PRESSURE')
	call ncnames_add_var('airp','Pressure reduced to MSL')
	call ncnames_add_var('wind','eastward_wind')
	call ncnames_add_var('wind','northward_wind')
	call ncnames_add_var('wind','U at 10 M')
	call ncnames_add_var('wind','V at 10 M')
	call ncnames_add_var('wind','u-component of wind')
	call ncnames_add_var('wind','v-component of wind')
	call ncnames_add_var('rhum','Relative Humidity at 2 m')
	call ncnames_add_var('rhum','Relative Humidity')
	call ncnames_add_var('rhum','relative_humidity')
	call ncnames_add_var('shum','specific humidity')
	call ncnames_add_var('mixrat','Water vapor mixing ratio')
	call ncnames_add_var('airt','Temperature at 2 m')
	call ncnames_add_var('airt','TEMP at 2 M')
	call ncnames_add_var('airt','air_temperature')
	call ncnames_add_var('cc','total cloud cover')
	call ncnames_add_var('cc','total_cloud_cover')
	call ncnames_add_var('cc','Cloud cover')
	call ncnames_add_var('cc','CLOUD FRACTION')
	call ncnames_add_var('srad','surface_downwelling_shortwave_flux')
	call ncnames_add_var('srad','Short wave flux')
	call ncnames_add_var('srad','DOWNWARD SHORT WAVE FLUX',bclip)
	call ncnames_add_var('srad'
     +			,'DOWNWARD SHORT WAVE FLUX AT GROUND SURFACE')
	call ncnames_add_var('srad'
     +			,'surface_downwelling_shortwave_flux_in_air')
	call ncnames_add_var('rain','large_scale_precipitation_amount')
	call ncnames_add_var('rain'
     +			,'ACCUMULATED TOTAL GRID SCALE PRECIPITATION')
	call ncnames_add_var('rain','Total Precipitation')

	end subroutine ncnames_add_variables 

c*****************************************************************
c*****************************************************************
c*****************************************************************

