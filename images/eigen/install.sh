#!/bin/bash

set -ex
cd /tmp

eigenPrefix="${TOOLS}/common"
eigenVersion=3.4

git clone --depth=1 -b ${eigenVersion} https://gitlab.com/libeigen/eigen.git
cd eigen
cmake -DCMAKE_INSTALL_PREFIX="${eigenPrefix}" -B build .
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building eigen with $BUILD_JOBS parallel jobs"
cmake --build build -j ${BUILD_JOBS} --target install

CMAKE_PACKAGE_ROOT_ARGS+=" -D Eigen3_ROOT=$(realpath $eigenPrefix) "

# Cleanup: Remove source code and build directory
cd /tmp
rm -rf eigen