module RK2_module
  implicit none
  contains
  
subroutine RK2 (time, dt,it, u, uk, p, vort, nlk)
  use share_vars
  use rhs
  use FieldExport
  use masks
  implicit none
  real(kind=pr), dimension(0:nx-1,0:ny-1,1:2), intent (inout) :: u, uk, nlk
  real(kind=pr), dimension(0:nx-1,0:ny-1), intent (inout) :: vort, p
  real(kind=pr), intent (out) :: dt
  real(kind=pr), intent (in) :: time
  real(kind=pr), dimension (0:nx-1, 0:ny-1) :: workvis
  real(kind=pr), dimension (0:nx-1, 0:ny-1,1:2) :: nlk2, uk_tmp, u_tmp
  integer :: iy
  integer, intent(in) :: it
  real(kind=pr) :: timestep, max_divergence

  dt = timestep (time,it,u)
  !-- compute integrating factor
  call cal_vis (dt, workvis)  
  !-- mask and us
  call create_mask (time)
  call create_us (time, u, uk)
  !-- RHS and pressure
  call cal_nlk (time, u, uk, vort, nlk, .true.)
  call add_pressure (nlk, uk, u, vort)

  !-- do the euler step 
  !$omp parallel do private (iy)
  do iy=0,ny-1
    uk_tmp(:,iy,1) = (uk(:,iy,1)+dt*nlk(:,iy,1))*dealiase(:,iy)*workvis(:,iy)
    uk_tmp(:,iy,2) = (uk(:,iy,2)+dt*nlk(:,iy,2))*dealiase(:,iy)*workvis(:,iy)
  enddo
  !$omp end parallel do 
  
  !-- mean flow forcing
  call mean_flow (uk_tmp)
  
  !-- velocity in phys. space
  call cofitxy (uk_tmp(:,:,1), u_tmp(:,:,1))
  call cofitxy (uk_tmp(:,:,2), u_tmp(:,:,2))
  
 
  !---------------------------------------------------------------------------------
  ! do second RK2 step (RHS evaluation with the argument defined above)
  !---------------------------------------------------------------------------------
  !-- mask and us
  call create_mask (time+dt)
  call create_us (time+dt, u_tmp, uk_tmp)
  !-- RHS and pressure
  call cal_nlk (time+dt, u_tmp, uk_tmp, vort, nlk2, .true.)  
  call add_pressure (nlk2, uk_tmp, u_tmp, vort)

  !-- sum up all the terms (final step)
  !$omp parallel do private (iy)
  do iy=0,ny-1
    uk(:,iy,1) = ( uk(:,iy,1)*workvis(:,iy) + 0.5d0*dt*( nlk(:,iy,1)*workvis(:,iy) + nlk2(:,iy,1) ) )*dealiase(:,iy)      
    uk(:,iy,2) = ( uk(:,iy,2)*workvis(:,iy) + 0.5d0*dt*( nlk(:,iy,2)*workvis(:,iy) + nlk2(:,iy,2) ) )*dealiase(:,iy)
  enddo
  !$omp end parallel do 
  
  !-- mean flow forcing
  call mean_flow (uk)     
  !-- velocity in phys. space
  call cofitxy (uk(:,:,1), u(:,:,1))
  call cofitxy (uk(:,:,2), u(:,:,2))
  
!  at the end of the time step, we consistently return u and uk 
end subroutine RK2
end module