#!/bin/bash

export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include -std=c++14"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export BOOST_ROOT="${PREFIX}"

# Requires gcc-5 on Linux, but we want to use the pre-c++11 ABI nonetheless
if [[ $(uname) == Linux ]]; then
    export CPPFLAGS="${CPPFLAGS} -D _GLIBCXX_USE_CXX11_ABI=0"
fi

./configure --prefix="${PREFIX}" --with-boost="${BOOST_ROOT}" --with-boost-libdir="${BOOST_ROOT}/lib" --with-boost-python="${BOOST_ROOT}/lib/libboost_python3.dylib"
make -j${CPU_COUNT}
#make test
#eval ${LIBRARY_SEARCH_VAR}=$PREFIX/lib make test
make install
