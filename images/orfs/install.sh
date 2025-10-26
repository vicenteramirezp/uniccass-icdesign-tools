#!/bin/bash

set -ex

# Clone OpenROAD-flow-scripts repository to /opt/OpenROAD-flow-scripts
git clone $ORFS_REPO_URL $TOOLS/$ORFS_NAME
cd $TOOLS/$ORFS_NAME
git checkout $ORFS_REPO_COMMIT

# Initialize and update git submodules (may be needed by the flow scripts)
git submodule update --init --recursive
