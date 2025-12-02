#!/bin/bash

set -ex
cd /tmp

REPO_COMMIT_SHORT=$(echo "$GAW3_XSCHEM_REPO_COMMIT" | cut -c 1-7)

git clone --filter=blob:none "${GAW3_XSCHEM_REPO_URL}" "${GAW3_XSCHEM_NAME}"
cd "${GAW3_XSCHEM_NAME}"
git checkout "${GAW3_XSCHEM_REPO_COMMIT}"

chmod +x configure
autoreconf -f -i
./configure --prefix="${TOOLS}/${GAW3_XSCHEM_NAME}/${REPO_COMMIT_SHORT}"
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building gaw with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
make install

# Cleanup: Remove source code
cd /tmp
rm -rf "${GAW3_XSCHEM_NAME}"
