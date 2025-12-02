#!/bin/bash

set -ex
cd /tmp || exit 1

REPO_COMMIT_SHORT=$(echo "$IVERILOG_REPO_COMMIT" | cut -c 1-5)

git clone "${IVERILOG_REPO_URL}" "${IVERILOG_NAME}"
cd "${IVERILOG_NAME}" || exit 1
git checkout "${IVERILOG_REPO_COMMIT}"
chmod +x autoconf.sh
./autoconf.sh
./configure --prefix="${TOOLS}/${IVERILOG_NAME}/${REPO_COMMIT_SHORT}"
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building iverilog with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
make install

# Cleanup: Remove source code
cd /tmp
rm -rf "${IVERILOG_NAME}"