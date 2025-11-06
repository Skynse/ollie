#!/bin/bash
# Shell script to build Flutter web with environment variables
# Usage: ./build-web.sh

set -e

ENV_FILE="${1:-.env}"

echo "Building Flutter web with environment variables from $ENV_FILE"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE file not found. Please create one from .env.example"
    exit 1
fi

# Read .env file and build dart-define arguments
DART_DEFINES=()
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
        DART_DEFINES+=("--dart-define=$line")
    fi
done < "$ENV_FILE"

if [ ${#DART_DEFINES[@]} -eq 0 ]; then
    echo "Error: No environment variables found in $ENV_FILE"
    exit 1
fi

echo "Found ${#DART_DEFINES[@]} environment variables"

# Build the Flutter web app
echo "Running: flutter build web ${DART_DEFINES[*]}"
flutter build web "${DART_DEFINES[@]}"

echo ""
echo "Build completed successfully!"
echo "Output directory: build/web"
