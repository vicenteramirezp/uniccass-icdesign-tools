#!/bin/bash

set -ex

REPO_COMMIT_SHORT=$(echo "$VERILATOR_REPO_COMMIT" | cut -c 1-7)

# git clone --filter=blob:none "${VERILATOR_REPO_URL}" "${VERILATOR_NAME}"
git clone --filter=blob:none "${VERILATOR_REPO_URL}" "${VERILATOR_NAME}"
cd "${VERILATOR_NAME}" || exit 1
git checkout "${VERILATOR_REPO_COMMIT}"

autoconf
./configure --prefix="${TOOLS}/${VERILATOR_NAME}/${REPO_COMMIT_SHORT}"
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building verilator with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
# make test
make install

# Cleanup: Remove source code
cd /tmp
rm -rf "${VERILATOR_NAME}"