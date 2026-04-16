#!/bin/bash
set -e

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
export PATH="$PATH:/opt/flutter/bin"

# Verify
flutter --version

# Get dependencies and build
flutter pub get
flutter build web --release --base-href /

echo "Build complete."