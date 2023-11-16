#!/bin/sh
cd ${HOME}/OpenBLAS-0.3.25
export NO_SHARED=1
export DYNAMIC_ARCH=1
export TARGET=ARMV8
export NO_FORTRAN=1
export NUM_THREADS=8
export USE_OPENMP=1
make clean
make -j$(nproc)
make PREFIX=${HOME}/openblas install
mv ${HOME}/openblas/lib/libopenblasp-r0.3.25.a ${HOME}/openblas/lib/libopenblas_universalp-r0.3.25.a

export DYNAMIC_ARCH=0
for i in ARMV8 CORTEXA53 CORTEXA55 CORTEXA57 CORTEXA72 CORTEXA73 CORTEXX1 NEOVERSEN1 NEOVERSEV1 NEOVERSEN2 FALKOR THUNDERX VORTEX EMAG8180 THUNDERX2T99 TSV110 THUNDERX3T110 ARMV8SVE FT2000 #CORTEXX2 CORTEXA510 CORTEXA710 A64FX
do
	export TARGET=${i}
	make clean
	make -j$(nproc)
	make PREFIX=${HOME}/openblas install
	unset TARGET
done
unset NO_SHARED
unset DYNAMIC_ARCH
unset TARGET
unset NO_FORTRAN
unset NUM_THREADS
unset USE_OPENMP

VERSION="-r0.3.25.a"
SFX=".a"
PRX="lib"

export LDFLAGS=-L${HOME}/openblas/lib
export CFLAGS="-fopenmp" #-pthread
cd ${HOME}/hpl-2.3
for i in ${HOME}/openblas/lib/*${VERSION}
do
        ln -sf ${i} ${HOME}/openblas/lib/libopenblas.a
        make clean
        ./configure
        make -j$(nproc)
        strip testing/xhpl
        sstrip testing/xhpl #https://github.com/aunali1/super-strip
        NAME=$(basename ${i})
        NAME=${NAME##${PRX}}
        NAME=${NAME%%${SFX}}
        mv testing/xhpl ${HOME}/xhpl-aarch64/xhpl-${NAME}
done
unset LDFLAGS
unset CFLAGS
