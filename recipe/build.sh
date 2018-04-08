#!/bin/bash

export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include -std=c++14"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export BOOST_ROOT="${PREFIX}"

# Requires gcc-5 on Linux, but we want to use the pre-c++11 ABI nonetheless
#
# How to install and enable gcc-5:
#
# yum install -y centos-release-scl yum-utils devtoolset-4-binutils devtoolset-4-gcc devtoolset-4-gcc-c++
# source /opt/rh/devtoolset-4/enable
#
# After building this package, don't forget to switch back to gcc-4.9 if you're using that for your other packages:
# 
# yum install -y centos-release-scl yum-utils devtoolset-3-binutils devtoolset-3-gcc devtoolset-3-gcc-c++
# source /opt/rh/devtoolset-3/enable

if [[ $(uname) == Linux ]]; then
    export CPPFLAGS="${CPPFLAGS} -D _GLIBCXX_USE_CXX11_ABI=0"
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

make -j${CPU_COUNT}
#make test
#eval ${LIBRARY_SEARCH_VAR}=$PREFIX/lib make test
make install
