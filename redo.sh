#!/bin/sh
make maintainer-clean
./get_submodules.sh
./autogen.sh
#./configure --prefix=$HOME/usr --with-osl=system --with-osl-prefix=$HOME/usr --with-osl-exec-prefix=$HOME/usr
./configure --prefix=$HOME/usr
make
