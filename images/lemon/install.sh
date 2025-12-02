#!/bin/bash

set -ex
cd /tmp

lemonPrefix="${TOOLS}/common"
lemonVersion=1.3.1

git clone --depth=1 -b ${lemonVersion} https://github.com/The-OpenROAD-Project/lemon-graph.git
cd lemon-graph
cmake -DCMAKE_INSTALL_PREFIX="${lemonPrefix}" -B build .
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building lemon with $BUILD_JOBS parallel jobs"
cmake --build build -j ${BUILD_JOBS} --target install

CMAKE_PACKAGE_ROOT_ARGS+=" -D LEMON_ROOT=$(realpath $lemonPrefix) "

# Cleanup: Remove source code and build directory
cd /tmp
rm -rf lemon-graph