#!/bin/bash

export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include -std=c++17"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export BOOST_ROOT="${PREFIX}"

if [[ $(uname) == Linux ]]; then
    export BOOST_PYTHON="${BOOST_ROOT}/lib/libboost_python3.so"
elif [[ $(uname) == Darwin ]]; then
    export BOOST_PYTHON="${BOOST_ROOT}/lib/libboost_python3.dylib"
fi

./configure \
    --prefix="${PREFIX}" \
    --with-boost="${BOOST_ROOT}" \
    --with-boost-libdir="${BOOST_ROOT}/lib" \
    --with-boost-python="${BOOST_PYTHON}" \
    --with-expat="${PREFIX}" \
##

# Due to the high RAM requirements to build this package,
# We limit build parallelism to no more than 2.
if [ "${CPU_COUNT}" -gt 2 ]; then
	CPU_COUNT=2
fi

make -j${CPU_COUNT} 

#LD_LIBRARY_PATH=${PREFIX}/lib make test

make install
