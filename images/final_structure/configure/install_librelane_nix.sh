#!/bin/bash
set -e

echo "Installing LibreLane from /opt/librelane (dev branch)"

# Clone LibreLane repository
if [ ! -d "/opt/librelane" ]; then
    git clone https://github.com/librelane/librelane.git /opt/librelane
fi

cd /opt/librelane

# Checkout dev branch for IHP support
git checkout dev
git pull || true

# Configure Nix with custom substituters
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << EOF
extra-substituters = https://nix-cache.fossi-foundation.org
extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
experimental-features = nix-command flakes
EOF

# Install LibreLane using Nix flakes
echo "Installing LibreLane with Nix (this may take several minutes)..."
nix profile install . --extra-experimental-features "nix-command flakes"

# Verify installation
librelane --version

echo "LibreLane installation complete!"

