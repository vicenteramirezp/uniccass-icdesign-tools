#!/bin/bash

# References
# - From IHP: https://ihp-open-pdk-docu.readthedocs.io/en/latest/analog/xyce.html
# - From JKU: https://github.com/iic-jku/IIC-OSIC-TOOLS/blob/main/_build/images/xyce/scripts/install.sh

set -ex
cd /tmp

export REPO_COMMIT_SHORT=$(echo "$XYCE_REPO_COMMIT" | cut -c 1-5)

git clone --depth=1 --branch "${XYCE_REPO_COMMIT}" "${XYCE_REPO_URL}" "${XYCE_NAME}"
cd "${XYCE_NAME}"
./bootstrap

cd /tmp/"${XYCE_NAME}"
git clone --depth=1 --branch "${XYCE_TRILINOS_REPO_COMMIT}" "${XYCE_TRILINOS_REPO_URL}" trilinos

cd "/tmp/${XYCE_NAME}/trilinos"
mkdir -p parallel_build && cd parallel_build
cp /images/xyce/trilinos.reconfigure.sh ./reconfigure.sh
chmod +x reconfigure.sh
./reconfigure.sh
# Use limited parallelism to reduce RAM usage (Xyce/Trilinos are very memory intensive)
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building Trilinos with $BUILD_JOBS parallel jobs (limited for memory)"
make -j"${BUILD_JOBS}"
make install
# Clean intermediate files after Trilinos build
find . -name "*.o" -delete 2>/dev/null || true

cd /tmp/"${XYCE_NAME}"
mkdir -p parallel_build && cd parallel_build
cp /images/xyce/xyce.reconfigure.sh ./reconfigure.sh
chmod +x reconfigure.sh
./reconfigure.sh
echo "Building Xyce with $BUILD_JOBS parallel jobs (limited for memory)"
make -j"${BUILD_JOBS}"
make install

# Cleanup: Remove source code and build artifacts
cd /tmp
rm -rf "${XYCE_NAME}"