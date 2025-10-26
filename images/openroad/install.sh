#!/bin/bash

set -ex
cd /tmp

REPO_COMMIT_SHORT=$(echo "$OPENROAD_APP_REPO_COMMIT" | cut -c 1-7)

git clone --filter=blob:none "${OPENROAD_APP_REPO_URL}" "${OPENROAD_APP_NAME}"
cd "${OPENROAD_APP_NAME}"
git checkout "${OPENROAD_APP_REPO_COMMIT}"
git submodule update --init --recursive

# Install dependencies using OpenROAD's dependency installer
./etc/DependencyInstaller.sh -base

# Apply fmt v7 compatibility fixes
echo "Applying fmt v7 compatibility fix..."

# Fix the dbBlock.cpp compatibility issue
cd src/odb/src/db
if grep -q "buf.append(fmt::string_view(base_name))" dbBlock.cpp; then
    sed -i 's/buf.append(fmt::string_view(base_name));/buf.append(base_name, base_name + strlen(base_name));/' dbBlock.cpp
    echo "Applied fmt v7 compatibility fix to dbBlock.cpp"
fi
cd /tmp/openroad

# Apply the fix to dbSdcNetwork.cc
cd src/dbSta/src
python3 << 'EOF'
import re

with open('dbSdcNetwork.cc', 'r') as f:
    content = f.read()

# Replace std::string_view(name(child)) with pointer arithmetic
content = re.sub(
    r'(\s+)path_buffer\.append\(std::string_view\(name\(child\)\)\);',
    r'\1const char* child_nm = name(child);\n\1path_buffer.append(child_nm, child_nm + strlen(child_nm));',
    content
)

with open('dbSdcNetwork.cc', 'w') as f:
    f.write(content)
    
print("Applied fmt v7 compatibility fix to dbSdcNetwork.cc")
EOF
cd /tmp/openroad

# Apply the fix to dbNetwork.cc  
cd src/dbSta/src
python3 << 'EOF'
import re

with open('dbNetwork.cc', 'r') as f:
    content = f.read()

# Try to fix std::string_view(modnet_name) - modnet_name is likely a string
if 'std::string_view(modnet_name)' in content:
    content = re.sub(
        r'full_path_buf\.append\(std::string_view\(modnet_name\)\)',
        r'full_path_buf.append(modnet_name.data(), modnet_name.data() + modnet_name.size())',
        content
    )
    print("Applied fmt v7 compatibility fix to dbNetwork.cc (with data/size)")
else:
    # It might just be full_path_buf.append(modnet_name)
    content = re.sub(
        r'full_path_buf\.append\(modnet_name\)',
        r'full_path_buf.append(modnet_name.data(), modnet_name.data() + modnet_name.size())',
        content
    )
    print("Applied fmt v7 compatibility fix to dbNetwork.cc (direct)")
    
with open('dbNetwork.cc', 'w') as f:
    f.write(content)
EOF
cd /tmp/openroad

# Patch: Install spdlog development package to provide spdlog::spdlog target
apt-get update && apt-get install -y libspdlog-dev 2>/dev/null || echo "spdlog-dev not available, will build from source"

mkdir -p build && cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    "-DCMAKE_INSTALL_PREFIX=${TOOLS}/${OPENROAD_APP_NAME}/${REPO_COMMIT_SHORT}" \
    -DCMAKE_PREFIX_PATH="/opt/common" \
    -DUSE_SYSTEM_BOOST=OFF \
    -DUSE_SYSTEM_EIGEN3=OFF \
    -DUSE_SYSTEM_LEMON=OFF \
    -DUSE_SYSTEM_GTEST=ON \
    -DUSE_SYSTEM_ORTOOLS=OFF \
    -DUSE_SYSTEM_SWIG=ON \
    -DUSE_SYSTEM_SPDLOG=OFF \
    -DUSE_SYSTEM_CUDD=OFF \
    -DUSE_SYSTEM_FMT=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_BUILD_TESTS=OFF \
    -DSPDLOG_BUILD_SHARED=OFF \
    -DFMT_DOC=OFF \
    -DFMT_TEST=OFF \
    -DFORCE_SPDLOG_BUILD=ON
make -j"$(nproc)"
make install

# Create symlinks for easy access
ln -sf ${TOOLS}/${OPENROAD_APP_NAME}/${REPO_COMMIT_SHORT}/bin/openroad ${TOOLS}/${OPENROAD_APP_NAME}/${REPO_COMMIT_SHORT}/bin/or