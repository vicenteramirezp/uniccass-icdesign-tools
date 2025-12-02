#!/bin/bash

set -ex
cd /tmp

# Need libboost >= 1.78 for OpenROAD
BOOST_VER_MAJ=1
BOOST_VER_MIN=82	
BOOST_BUILD=0
BOOST_VERSION="$BOOST_VER_MAJ.$BOOST_VER_MIN.$BOOST_BUILD"

curl -L -o boost-${BOOST_VERSION}.tar.gz https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}.tar.gz
tar -xf boost-${BOOST_VERSION}.tar.gz

cd boost-${BOOST_VERSION}
./bootstrap.sh --prefix="${TOOLS}/common"
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building boost with $BUILD_JOBS parallel jobs"
./b2 install --with-iostreams --with-test --with-serialization --with-system --with-thread -j ${BUILD_JOBS}

# Cleanup: Remove source code and archive
cd /tmp
rm -rf boost-${BOOST_VERSION}
rm -f boost-${BOOST_VERSION}.tar.gz
