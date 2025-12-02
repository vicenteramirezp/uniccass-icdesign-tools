#!/bin/bash

set -ex
cd /tmp

spdlogPrefix="${TOOLS}/common"
spdlogVersion=1.8.1

git clone --depth=1 -b "v${spdlogVersion}" https://github.com/gabime/spdlog.git
cd spdlog
cmake -DCMAKE_INSTALL_PREFIX="${spdlogPrefix}" -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DSPDLOG_BUILD_EXAMPLE=OFF -B build .
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building spdlog with $BUILD_JOBS parallel jobs"
cmake --build build -j ${BUILD_JOBS} --target install

CMAKE_PACKAGE_ROOT_ARGS+=" -D spdlog_ROOT=$(realpath $spdlogPrefix) "

# Cleanup: Remove source code and build directory
cd /tmp
rm -rf spdlog