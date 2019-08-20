#!/bin/bash

export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include -std=c++17"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export BOOST_ROOT="${PREFIX}"

# Note about PYTHON_LIBS:
# If left unset, the configure script will set PYTHON_LIBS as follows:
#
#   PYTHON_LIBS="-L${PREFIX}/lib -lpython3.7m"
#
# ...but we never want to link against libpython in a conda environment.
# Conda's python executable is STATICALLY linked.  It does not link against libpython3.7.dylib!
# Instead, all python symbols will be implicitly obtained from the python executable itself.
# In fact, if we link against libpython, we'll end up with segfaults.
#
# We don't want to set PYTHON_LIBS, but we can't leave it empty.
# This is a suitable no-op.  See note above.
PYTHON_LIBS="-L${PREFIX}/lib"

if [[ $(uname) == Linux ]]; then
    export BOOST_PYTHON="${BOOST_ROOT}/lib/libboost_python3.so"

elif [[ $(uname) == Darwin ]]; then
    export BOOST_PYTHON="${BOOST_ROOT}/lib/libboost_python3.dylib"

    # Don't resolve python symbols until runtime.
    # See note above about PYTHON_LIBS.
    export LDFLAGS="${LDFLAGS} -undefined dynamic_lookup"
fi

./autogen.sh

./configure \
    --prefix="${PREFIX}" \
    --with-boost="${BOOST_ROOT}" \
    --with-boost-libdir="${BOOST_ROOT}/lib" \
    --with-boost-python="${BOOST_PYTHON}" \
    --with-expat="${PREFIX}" \
    PYTHON_LIBS="${PYTHON_LIBS}" \
##

# Due to the high RAM requirements to build this package,
# We limit build parallelism to no more than 3.
if [ "${CPU_COUNT}" -gt 3 ]; then
	CPU_COUNT=3
fi

make -j${CPU_COUNT}
#LD_LIBRARY_PATH=${PREFIX}/lib make test

make install
