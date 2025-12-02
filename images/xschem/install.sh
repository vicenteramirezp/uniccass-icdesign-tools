#!/bin/bash

set -e

REPO_COMMIT_SHORT=$(echo "$XSCHEM_REPO_COMMIT" | cut -c 1-7)

git clone --filter=blob:none "${XSCHEM_REPO_URL}" "${XSCHEM_NAME}"
cd "${XSCHEM_NAME}"
git checkout "${XSCHEM_REPO_COMMIT}"
./configure --prefix="${TOOLS}/${XSCHEM_NAME}/${REPO_COMMIT_SHORT}"
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building xschem with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
make install

# Cleanup: Remove source code
cd /tmp
rm -rf "${XSCHEM_NAME}"