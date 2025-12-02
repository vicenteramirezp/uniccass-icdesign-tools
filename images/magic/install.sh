#!/bin/bash

set -ex
set -u

REPO_COMMIT_SHORT=$(echo "$MAGIC_REPO_COMMIT" | cut -c 1-7)

git clone --filter=blob:none $MAGIC_REPO_URL $MAGIC_NAME || true

cd $MAGIC_NAME
git checkout $MAGIC_REPO_COMMIT

./configure --prefix="${TOOLS}/${MAGIC_NAME}/${REPO_COMMIT_SHORT}"
make database/database.h
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building magic with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
make install

echo "$MAGIC_NAME $MAGIC_REPO_COMMIT" > "${TOOLS}/${MAGIC_NAME}/${REPO_COMMIT_SHORT}/SOURCES"

ln -s "${TOOLS}/${MAGIC_NAME}/${REPO_COMMIT_SHORT}"/bin/magic /usr/local/bin/magic

# Cleanup: Remove source code
cd /tmp
rm -rf "${MAGIC_NAME}"