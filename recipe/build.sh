#!/bin/bash

export CPPFLAGS="-I${PREFIX}/include"
export CXXFLAGS="-I${PREFIX}/include"
export LDFLAGS="-Wl,-rpath,${PREFIX}/lib, -L${PREFIX}/lib"
export BOOST_ROOT="${PREFIX}"

./configure --prefix="${PREFIX}" --with-boost="${BOOST_ROOT}" --with-boost-libdir="${BOOST_ROOT}/lib" --with-boost-python="${BOOST_ROOT}/lib/libboost_python3.dylib"
make -j${CPU_COUNT}
#make test
#eval ${LIBRARY_SEARCH_VAR}=$PREFIX/lib make test
make install
