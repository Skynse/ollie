#!/usr/bin/env bash
# Build the Ollie web bundle locally. Deployment is handled by CI.
set -euo pipefail

flutter --version
flutter pub get
flutter build web --release

echo "Web build written to build/web"
