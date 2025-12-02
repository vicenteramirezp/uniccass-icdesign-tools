#!/bin/bash

set -ex

# Clone OpenROAD-flow-scripts repository to /opt/OpenROAD-flow-scripts
# First clone with minimal depth to get the repo structure
git clone --depth 1 $ORFS_REPO_URL $TOOLS/$ORFS_NAME
cd $TOOLS/$ORFS_NAME

# Fetch the specific commit we need
git fetch --depth 1 origin $ORFS_REPO_COMMIT

# Checkout the specific commit
git checkout $ORFS_REPO_COMMIT

# Initialize and update git submodules (may be needed by the flow scripts)
git submodule update --init --recursive --depth 1

# Cleanup: Remove .git directory to save space (keep .gitmodules if needed for reference)
# Note: This prevents git operations in the container but saves significant space
# Uncomment if git history is not needed in runtime:
# rm -rf .git
