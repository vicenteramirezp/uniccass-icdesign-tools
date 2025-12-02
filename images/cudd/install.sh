#!/bin/bash

set -ex
cd /tmp

cuddPrefix="${TOOLS}/common"
cuddVersion=3.0.0

git clone --depth=1 -b ${cuddVersion} https://github.com/The-OpenROAD-Project/cudd.git
cd cudd
autoreconf
./configure --prefix=${cuddPrefix}
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building cudd with $BUILD_JOBS parallel jobs"
make -j ${BUILD_JOBS} install

# Cleanup: Remove source code
cd /tmp
rm -rf cudd