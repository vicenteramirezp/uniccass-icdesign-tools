#!/bin/bash

set -ex
cd /tmp

# Clone the OpenROAD repository
git clone $ORFS_REPO_URL $ORFS_NAME || true
cd $ORFS_NAME
git checkout $ORFS_REPO_COMMIT

# Initialize and update git submodules
git submodule update --init --recursive

# Install dependencies using OpenROAD's dependency installer
./etc/DependencyInstaller.sh -base

# STRATEGIC APPROACH: Apply fix for fmt v7 compatibility
# The code in dbBlock.cpp uses old fmt API that's incompatible with fmt v7
# We need to fix this before compilation
echo "Applying fmt v7 compatibility fix..."

# Fix the dbBlock.cpp compatibility issue
cat > /tmp/dbBlock_fix.patch << 'EOF'
--- a/src/odb/src/db/dbBlock.cpp
+++ b/src/odb/src/db/dbBlock.cpp
@@ -3782,7 +3782,7 @@ std::string _dbBlock::makeNewName(dbModInst* inst, const char* base_name, const
       {  // Use fmt if available
         fmt::basic_memory_buffer<char> buf;
         buf.reserve(est_size);
-        buf.append(fmt::string_view(base_name));
+        buf.append(base_name, base_name + strlen(base_name));
         fmt::format_to(std::back_inserter(buf), "{}_{}", index, suffix);
         *counter = index++;
         return std::string(buf.data(), buf.size());
EOF

# Apply the fix to dbBlock.cpp
cd src/odb/src/db
if grep -q "buf.append(fmt::string_view(base_name))" dbBlock.cpp; then
    sed -i 's/buf.append(fmt::string_view(base_name));/buf.append(base_name, base_name + strlen(base_name));/' dbBlock.cpp
    echo "Applied fmt v7 compatibility fix to dbBlock.cpp"
fi
cd /tmp/openroad

# Apply the fix to dbSdcNetwork.cc
cd src/dbSta/src
# Fix the dbSdcNetwork.cc compatibility issue - name() returns const char*
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

# Create build directory
mkdir -p build
cd build

# Configure with CMake - use system libraries for essential ones, build problematic ones from source
# This allows essential libraries to be found while avoiding conflicts with problematic libraries
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$TOOLS/$ORFS_NAME \
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

# Build OpenROAD with more parallelism for faster compilation
# Use available CPU cores for faster build
make -j$(nproc)

# Install OpenROAD
make install

# No libraries to restore since we didn't hide anything

# Create symlinks for easy access
ln -sf $TOOLS/$ORFS_NAME/bin/openroad $TOOLS/$ORFS_NAME/bin/or