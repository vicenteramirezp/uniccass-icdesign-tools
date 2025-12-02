#!/bin/bash

set -ex
set -u

REPO_COMMIT_SHORT=$(echo "$CVC_RV_REPO_COMMIT" | cut -c 1-7)

git clone --filter=blob:none "${CVC_RV_REPO_URL}" "${CVC_RV_NAME}" || true
cd "${CVC_RV_NAME}"
git checkout "${CVC_RV_REPO_COMMIT}"
autoreconf -vif
./configure --disable-nls --prefix="${TOOLS}/${CVC_RV_NAME}/${REPO_COMMIT_SHORT}"
sed -i 's/api.parser.class/parser_class_name/' src/cdlParser.yy
# Use limited parallelism to reduce RAM usage
BUILD_JOBS=${MAX_BUILD_JOBS:-2}
echo "Building cvc_rv with $BUILD_JOBS parallel jobs"
make -j"${BUILD_JOBS}"
make install

# Cleanup: Remove source code
cd /tmp
rm -rf "${CVC_RV_NAME}"