#!/bin/bash

export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include -std=c++17"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"

export BOOST_ROOT="${PREFIX}"

# Explicitly set this, which is used in configure.
# (We patched away the auto-detection of this variable.)
export BOOST_PYTHON_LIB=boost_python37
export BOOST_PYTHON="${BOOST_ROOT}/lib/lib${BOOST_PYTHON_LIB}.${SHLIB_EXT}"

# Note about PYTHON_LIBS:
# If left unset, the configure script will set PYTHON_LIBS as follows:
#
#   PYTHON_LIBS="-L${PREFIX}/lib -lpython3.7m"
#
# ...but we never want to link against libpython in a conda environment.
# That's because conda's python executable is STATICALLY linked.
# It does not link against libpython3.7.dylib and therefore no
# python extension modules should link against libpython3.7, either!
# In fact, if we link against libpython, we'll end up with segfaults.
# Instead, all python symbols will be loaded by python executable itself.
#
# So, we don't want to set PYTHON_LIBS, but we can't leave it empty.
# This is a suitable no-op.
PYTHON_LIBS=" "

if [[ $(uname) == Darwin ]]; then
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
    --with-cgal="${PREFIX}" \
    --disable-debug \
    --disable-dependency-tracking \
    PYTHON_LIBS="${PYTHON_LIBS}" \
##


##
## Building graph-tool requires a ton of RAM, which constrains the
## number of parallel jobs we can afford to use during the build.
## But if we were to use only a single thread, it would take 8 hours
## or more to complete build, and the CI provider would time out.
##
## Below, we use a hybrid approach:
##
##   1. Build a few of the biggest, most RAM-intensive parts first,
##      in a single thread.
##
##   2. Build everything else using parallel jobs (make -j<N>),
##      with the expectation that the job might fail intermittently due
##      to transient RAM problems.  Just restart the build a few times.
##

blockmodel_targets = ""
blockmodel_targets = "${blockmodel_targets} blockmodel/graph_blockmodel.lo"
blockmodel_targets = "${blockmodel_targets} blockmodel/graph_blockmodel_imp.lo"
blockmodel_targets = "${blockmodel_targets} blockmodel/graph_blockmodel_imp2.lo"
blockmodel_targets = "${blockmodel_targets} blockmodel/graph_blockmodel_imp3.lo"

# Start by building a few of the biggest files using only one thread.
# However, even in a single thread, gcc might choke on these
# and need a second (or third) try, hence the repeat 'make' commands here.
cd src/graph/inference
for target in ${blockmodel_targets}; do
	make ${target} || make ${target} || make ${target}
done
cd -

# Due to the high RAM requirements to build this package,
# we limit build parallelism somewhat.
MAX_CORES=4
if [ "${CPU_COUNT}" -gt ${MAX_CORES} ]; then
	CPU_COUNT=${MAX_CORES}
fi

# When building in a VM (especially one without much RAM),
# gcc might crap out early due to the complexity and/or high
# RAM usage of this build (due to "internal compiler error").
# We'll just restart the build a few times if necessary,
# including one final single-threaded try.
# It's ugly, but in practice, this seems to work.
make -j${CPU_COUNT} ||
  (echo "Restarting make (1)" && make -j${CPU_COUNT}) ||
  (echo "Restarting make (2)" && make -j${CPU_COUNT}) ||
  (echo "Restarting make (3)" && make -j${CPU_COUNT}) ||
  (echo "Restarting make (4)" && make)

# Test
#LD_LIBRARY_PATH=${PREFIX}/lib make test
#DYLD_FALLBACK_LIBRARY_PATH=${PREFIX}/lib make test

make install
