subroutine time_step
  use share_vars
  use masks
  use hdf5_wrapper
  use RK2_module
  use timing
  implicit none
  real(kind=pr) :: time=0.0d0, dt1=0.0d0, max_divergence
  real(kind=pr), dimension(:,:,:), allocatable :: u, uk, nlk
  real(kind=pr), dimension(:,:), allocatable :: pk, vort
  real(kind=pr) :: T_lastdrag=0.0d0, T_lastsave=0.0d0, t1, time_left
  integer :: it=0
  character(len=5) :: timestring

  allocate( pk(0:nx-1,0:ny-1), vort(0:nx-1,0:ny-1), u(0:nx-1,0:ny-1,1:2) )
  allocate( uk(0:nx-1,0:ny-1,1:2),nlk(0:nx-1,0:ny-1,1:2) )

  if (FD_2nd) write (*,*) "!!! ATTENTION; RUNNING IN REDUCED ACCURACY MODE"

  !-- Initialize fields or read values from a backup file
  call init_fields (time, u, uk, pk, vort, nlk)
  call sponge_mask(time)

  write (*,'("Initialization done, looping now.")')
  write (*,'("time=",es12.4," Tmax=",es12.4," it=",i2," nt=",i9)') time, Tmax, it, nt

  !----------------------------------------------------------------
  ! loop over time steps
  !----------------------------------------------------------------
  do while ((time<Tmax) .and. (it<=nt))
      t1 = Performance("start",1)

      !----------------------------------------------------------------
      !-- Actual time step
      !----------------------------------------------------------------
      call RK2 (time, dt1, it, u, uk, pk, vort, nlk)

      time = time + dt1  ! Advance in time
      it = it + 1

      if ((time-T_lastsave >= tsave) .or. (modulo(it,itsave)==0)) then
        !save output fields to disk
        call save_fields(time, it, u, uk, vort)
        T_lastsave=time
      endif

      t1 = Performance("stop",1)
      !----------------------------------------------------------------
      !-- remaining time
      !----------------------------------------------------------------
      if (modulo(it,1)==0) then
        time_left = t1*(Tmax-time)/dt1
        time_left = (nt-it)*t1
        write (*,'("time left=",i3,"d ",i2,"h ",i2,"m ",i2,"s (",es8.2," s/dt) [",i2,"%] divu=",es12.4)') &
          floor(time_left/(24.d0*3600.d0)),&
          floor(mod(time_left,24.d0*3600.d0)/3600.d0),&
          floor(mod(time_left,3600.d0)/60.d0),&
          floor(mod(mod(time_left,3600.d0),60.d0)),&
          t1, &
          nint(100.d0*time/Tmax), max_divergence(uk)
      endif
  enddo
  call save_fields(time, it, u, uk, vort)
  deallocate( pk,vort,u,uk,nlk)
  write (*,*) "Loop done."
end subroutine time_step
