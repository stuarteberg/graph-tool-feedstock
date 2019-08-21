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
PYTHON_LIBS=" "

# Explicitly set this, which is used in configure.
# (We patched away the auto-detection of this variable.)
export BOOST_PYTHON_LIB=boost_python37

if [[ $(uname) == Linux ]]; then
    export BOOST_PYTHON="${BOOST_ROOT}/lib/lib${BOOST_PYTHON_LIB}.so"

elif [[ $(uname) == Darwin ]]; then
    export BOOST_PYTHON="${BOOST_ROOT}/lib/lib${BOOST_PYTHON_LIB}.dylib"

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
    --disable-debug \
    --disable-dependency-tracking \
    PYTHON_LIBS="${PYTHON_LIBS}" \
##

# Due to the high RAM requirements to build this package,
# We limit build parallelism to no more than 3.
MAX_CORES=3
if [ "${CPU_COUNT}" -gt ${MAX_CORES} ]; then
	CPU_COUNT=${MAX_CORES}
fi
make -j${CPU_COUNT}

# Test
#LD_LIBRARY_PATH=${PREFIX}/lib make test

make install
