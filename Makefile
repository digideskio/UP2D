## Use GNU Make (gmake) to build

PROJECT = dns.out

include .mkdep_includes
include .mkdep_objects

F95=gfortran
BASEFLAGS=-g -fopenmp -lpthread -O3
#-fdefault-real-8
FREEFLAGS=$(INC) $(BASEFLAGS)
FFTW_LOC = $(FFT_ROOT)/lib
FFTW_INC = $(FFT_ROOT)/include
FFT_LINK = -I$(FFTW_INC) -L$(FFTW_LOC) -lfftw3_threads -lfftw3
LFLAGS=$(FFT_LINK) -lm -fopenmp -lpthread

$(PROJECT):$(OBJS)
	$(F95) -o $(PROJECT) $(OBJS) $(LFLAGS)

include .mkdep_dependencies

%.o : %.f90 ; $(F95) -c $(FREEFLAGS)   -o $@ $<

dep:
	# the switch "-b" inhibits collecting all *.o files in
	# the build directory. does not work without it.
	./mkdep/mkdep --fc gfortran -b files.in
clean:
	rm -f *.mod *~ $(PROJECT) $(MAINLIB)
	rmobjs .mkdep_objects