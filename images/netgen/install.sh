#!/bin/bash

set -ex
cd /tmp

REPO_COMMIT_SHORT=$(echo "$NETGEN_REPO_COMMIT" | cut -c 1-7)

# Verify environment
echo "Environment check:"
echo "TOOLS=$TOOLS"
echo "PATH=$PATH"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-not set}"
which gcc || echo "WARNING: gcc not found in PATH"
gcc --version || echo "WARNING: gcc --version failed"

git clone --filter=blob:none "${NETGEN_REPO_URL}" "${NETGEN_NAME}"
cd "${NETGEN_NAME}"
git checkout "${NETGEN_REPO_COMMIT}"

# Netgen has configure script in scripts subdirectory
# Run configure from scripts directory
cd scripts
./configure CFLAGS="-O2 -g" --prefix="${TOOLS}/${NETGEN_NAME}/${REPO_COMMIT_SHORT}"

# Netgen's Makefile is in the parent directory, not in scripts
# Return to parent directory to build
cd ..
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building netgen with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
make install

# Cleanup: Remove source code
cd /tmp
rm -rf "${NETGEN_NAME}"