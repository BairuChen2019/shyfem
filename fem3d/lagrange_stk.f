!
! $Id: lagrange_stk.f,v 1.6 2009-02-13 17:22:44 georg Exp $
!
! lagrangian stokes drift due to waves
!
! revision log :
!
! 19.06.2018    ccf     written from scratch
!
! TO BE IMPROVED IN THE HYDRO-WAVE COUPLING
!
!************************************************************

        subroutine lag_stk(i,id,ty,x,y,xi,iel,lb,time)

        use mod_lagrange
        use basin
        use mod_meteo

        implicit none

        integer, intent(in)     :: i            !particle number
        integer, intent(in)     :: id           !particle id
        integer, intent(in)	:: ty		!particle type
        real, intent(inout)     :: x            !x-coordinate
        real, intent(inout)     :: y            !y-coordinate
        double precision, intent(inout):: xi(3) !internal coordinates
        integer, intent(inout)  :: iel          !element number
        integer, intent(in)     :: lb   	!level
        real, intent(in)        :: time         !time to advect

        real                    :: ttime
        integer, save           :: icall = 0    !initialization parameter
        logical, save           :: bsphe
        integer                 :: isphe
	integer			:: k,ii
	real			:: wx,wy
        double precision        :: xx,yy
        real                    :: dx,dy
        real                    :: xnew,ynew
        integer                 :: ienew
        double precision        :: ddx,ddy,xc,yc
        double precision        :: dlat0,dlon0  !center of projection

!---------------------------------------------------------------
! initialize
!---------------------------------------------------------------

        if( icall == 0 ) then
          call get_coords_ev(isphe)
          bsphe = isphe .eq. 1
          icall = 1
        end if

	if( lb > 1 .or. iel < 0 .or. ty < 0) return !not in surface, out, or beached
	if( stkpar <= 0. ) return !no wind drag

        ttime = time
        dx = 0.
        dy = 0.
        ienew = 0

!---------------------------------------------------------------
! horizontal drift 
!---------------------------------------------------------------

        !-----------------------------------------------
        ! Compute wind on element
        !-----------------------------------------------
        wx = 0.
        wy = 0.
        do ii=1,3
          k = nen3v(ii,iel)
          wx = wx + wxv(k)
          wy = wy + wyv(k)
        end do
        wx = wx / 3.
        wy = wy / 3.

        !-----------------------------------------------
        ! Compute drift displacement and new coordinates
        !-----------------------------------------------
	dx = wx*stkpar*ttime
	dy = wy*stkpar*ttime

        xnew = x + dx
        ynew = y + dy

        if ( bsphe ) then
           ddx = dx
           ddy = dy
           dlon0 = x
           dlat0 = y
           call ev_c2g(ddx,ddy,xc,yc,dlon0,dlat0)
           xnew = xc
           ynew = yc
        end if

        call find_elem_from_old(iel,xnew,ynew,ienew)

        if (ienew == 0 ) then
           ienew = iel
           call particle_on_side(ienew,x,y,xnew,ynew)
        end if

        !-----------------------------------------------
        ! Assign new coordinates and element to particle 
        !-----------------------------------------------
        x   = xnew
        y   = ynew
        iel = ienew

        !-----------------------------------------------
        ! From external to internal coordinates
        !-----------------------------------------------
        xx = x
        yy = y
        call xy2xi(iel,xx,yy,xi)

!---------------------------------------------------------------
! end of routine
!---------------------------------------------------------------

        end subroutine lag_stk

!**********************************************************************



