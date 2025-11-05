#!/bin/bash
set -e

echo "Installing Flutter..."

# Install Flutter using git
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# Verify Flutter installation
flutter --version

# Disable analytics
flutter config --no-analytics

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build web app
echo "Building web app..."
flutter build web --release

echo "Build complete!"
