#!/bin/sh
cd ${HOME}/blis-0.9.0
make clean
./configure -p ${HOME}/blis --disable-shared -t openmp arm64
make -j$(nproc)
make install
mv ${HOME}/blis/lib/libblis.a ${HOME}/blis/lib/libblis_universalp-0.9.0.a

for i in a64fx armsve cortexa53 cortexa57 firestorm generic thunderx2
do
	make clean
	./configure -p ${HOME}/blis --disable-shared -t openmp ${i}
	make -j$(nproc)
	make install
	mv ${HOME}/blis/lib/libblis.a ${HOME}/blis/lib/libblis_${i}p-0.9.0.a
done

VERSION="-0.9.0.a"
SFX=".a"
PRX="lib"

export LDFLAGS=-L${HOME}/blis/lib
export CFLAGS="-fopenmp" #-pthread
cd ${HOME}/hpl-2.3
for i in ${HOME}/blis/lib/*${VERSION}
do
        ln -sf ${i} ${HOME}/blis/lib/libopenblas.a
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
